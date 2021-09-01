# Class: chocolab::powershell
#
#
class chocolab::base {

  # Indicators
  file { 'C:/Puppet.txt':
    ensure  => present,
    content => 'Managed by Puppet',
    owner   => system,
  }

  windows_env { 'MANAGED_BY_PUPPET':
    value => 'true',
  }

  # Base files
  file { 'C:/Temp':
    ensure => directory,
    owner  => system,
    before => Acl['C:/Temp']
  }

  acl { 'C:/Temp':
    permissions => [
      { identity => 'Administrator', rights => ['full'] },
      { identity => 'Users', rights => ['read','execute'] }
    ]
  }

  # Shell profile
  file { 'C:/Windows/System32/WindowsPowerShell/v1.0/profile.ps1':
    ensure  => present,
    content => file('chocolab/profile.ps1'),
  }

}
