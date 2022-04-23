# @summary Configure wh31e_metrics
#
# @param influx_url sets the InfluxDB hostname
# @param influx_org sets the InfluxDB Organization
# @param influx_token sets the credential to use for metric submission
# @param influx_bucket sets the InfluxDB bucket
# @param sensor_names sets the mapping between sensor ID and human name
# @param version sets the version of wh31e_metrics to install
# @param binfile sets the install path for the wh31e_metrics binary
class wh31e (
  String $influx_url,
  String $influx_org,
  String $influx_token,
  String $influx_bucket,
  Hash[Integer, String] $sensor_names,
  String $version = 'v0.0.4',
  String $binfile = '/usr/local/bin/wh31e_metrics',
) {
  class { 'sdr': }

  -> file { '/usr/local/etc/rtl_433/rtl_433.conf':
    ensure => file,
    source => 'puppet:///modules/wh31e/rtl_433.conf',
    notify => Service['rtl_433'],
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

  $filename = "wh31e_metrics_${kernel}_${arch}"
  $url = "https://github.com/akerl/wh31e_metrics/releases/download/${version}/${filename}"

  file { $binfile:
    ensure => file,
    source => $url,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    notify => Service['wh31e_metrics'],
  }

  -> file { '/usr/local/etc/wh31e_metrics.conf':
    ensure  => file,
    mode    => '0644',
    content => template('wh31e/wh31e_metrics.conf.erb'),
    notify  => Service['wh31e_metrics'],
  }

  -> file { '/etc/systemd/system/wh31e_metrics.service':
    ensure => file,
    source => 'puppet:///modules/wh31e/wh31e_metrics.service',
  }

  ~> service { 'wh31e_metrics':
    ensure => running,
    enable => true,
    notify => Service['rtl_433'],
  }
}
