# @summary Configure wh31e_metrics
#
class wh31e (
) {
  include sdr

  file { '/usr/local/etc/rtl_433/rtl_433.conf':
    ensure => file,
    source => 'puppet:///modules/wh31e/
}
