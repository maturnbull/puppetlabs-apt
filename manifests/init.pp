#
class apt(
  $always_apt_update    = false,
  $apt_update_frequency = 'reluctantly',
  $purge_sources_list   = false,
  $purge_sources_list_d = false,
  $purge_preferences    = false,
  $purge_preferences_d  = false,
  $update_timeout       = undef,
  $update_tries         = undef,
  $sources              = undef,
) inherits ::apt::params {

  include apt::update

  $frequency_options = ['always','daily','weekly','reluctantly']
  validate_re($apt_update_frequency, $frequency_options)

  validate_bool($purge_sources_list, $purge_sources_list_d,
                $purge_preferences, $purge_preferences_d)

  $sources_list_content = $purge_sources_list ? {
    false => undef,
    true  => "# Repos managed by puppet.\n",
  }

  if $always_apt_update == true {
    Exec <| title=='apt_update' |> {
      refreshonly => false,
    }
  }

  apt::setting { 'conf-update-stamp':
    base_name    => 'update-stamp',
    setting_type => 'conf',
    priority     => 15,
    content      => template('apt/_header.erb', 'apt/15update-stamp.erb'),
  }

  file { 'sources.list':
    ensure  => present,
    path    => $::apt::sources_list,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => $sources_list_content,
    notify  => Exec['apt_update'],
  }

  file { 'sources.list.d':
    ensure  => directory,
    path    => $::apt::sources_list_d,
    owner   => root,
    group   => root,
    purge   => $purge_sources_list_d,
    recurse => $purge_sources_list_d,
    notify  => Exec['apt_update'],
  }

  if $purge_preferences {
    file { 'apt-preferences':
      ensure => absent,
      path   => $::apt::preferences,
    }
  }

  file { 'preferences.d':
    ensure  => directory,
    path    => $::apt::preferences_d,
    owner   => root,
    group   => root,
    purge   => $purge_preferences_d,
    recurse => $purge_preferences_d,
  }

  # Need anchor to provide containment for dependencies.
  anchor { 'apt::update':
    require => Class['apt::update'],
  }

  # manage sources if present
  if $sources != undef {
    validate_hash($sources)
    create_resources('apt::source', $sources)
  }
}
