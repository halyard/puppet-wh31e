# @summary Configure wh31e metrics
#
# @param sensor_names sets the mapping between sensor ID and human name
# @param sample_rate sets the polling speed for new data
# @param version sets the version of wh31e to install
# @param binfile sets the install path for the wh31e binary
# @param prometheus_server_ip sets the IP range to allow for prometheus connections
# @param port to serve the wh31e metrics on
class wh31e (
  Hash[Integer, String] $sensor_names,
  String $sample_rate = '250k',
  String $version = 'v0.1.0',
  String $binfile = '/usr/local/bin/wh31e',
  String $prometheus_server_ip = '0.0.0.0/0',
  Integer $port = 9131,
) {
  class { 'sdr': }

  -> file { '/usr/local/etc/rtl_433/rtl_433.conf':
    ensure  => file,
    content => template('wh31e/rtl_433.conf.erb'),
    notify  => Service['rtl_433'],
  }

  -> file { '/var/lib/wh31e':
    ensure => directory,
  }

  -> file { '/etc/systemd/system/rtl_433.service':
    ensure => file,
    source => 'puppet:///modules/wh31e/rtl_433.service',
  }

  ~> service { 'rtl_433':
    ensure => running,
    enable => true,
  }

  $kernel = downcase($facts['kernel'])
  $arch = $facts['os']['architecture'] ? {
    'x86_64'  => 'amd64',
    'arm64'   => 'arm64',
    'aarch64' => 'arm64',
    'arm'     => 'arm',
    default   => 'error',
  }

  $filename = "wh31e_${kernel}_${arch}"
  $url = "https://github.com/akerl/wh31e/releases/download/${version}/${filename}"

  file { $binfile:
    ensure => file,
    source => $url,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    notify => Service['wh31e'],
  }

  -> file { '/usr/local/etc/wh31e.conf':
    ensure  => file,
    mode    => '0644',
    content => template('wh31e/wh31e.conf.erb'),
    notify  => Service['wh31e'],
  }

  -> file { '/etc/systemd/system/wh31e.service':
    ensure => file,
    source => 'puppet:///modules/wh31e/wh31e.service',
  }

  ~> service { 'wh31e':
    ensure => running,
    enable => true,
    notify => Service['rtl_433'],
  }

  firewall { '100 allow prometheus wh31e metrics':
    source => $prometheus_server_ip,
    dport  => $port,
    proto  => 'tcp',
    action => 'accept',
  }
}
