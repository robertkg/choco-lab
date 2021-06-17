# Installs chocolatey on the system
include chocolatey

file { 'C:/Puppet.txt':
  ensure  => present,
  content => 'Managed by Puppet',
  owner   => system,
}

# host { 'chocolatey.local':
#   ensure  => present,
#   ip      => '127.0.0.1',
#   comment => 'Internal Chocolatey repo',
# }

$_chocolatey_server_dns_name = 'chocolab.local'
$_chocolatey_server_location = 'C:\\Tools\\chocolatey.server'
$_chocolatey_server_app_pool_name = $_chocolatey_server_dns_name

# Workaround for host resource
file { 'C:/windows/system32/drivers/etc/hosts':
  ensure  => present,
  content => "127.0.0.1 ${_chocolatey_server_dns_name} # Internal chocolatey repo"
}

file { 'C:/Windows/System32/WindowsPowerShell/v1.0/profile.ps1':
  ensure  => present,
  content => file('chocolab/profile.ps1'),
}

package { 'chocolatey.server':
  ensure   => present,
  provider => chocolatey,
}

iis_feature { 'Web-WebServer':
  ensure                   => present,
  include_management_tools => true,
}
iis_feature { 'Web-Asp-Net45':
  ensure => present,
}
iis_feature { 'Web-AppInit':
  ensure => present,
}

# Cleanup IIS defaults 
-> iis_site {'Default Web Site':
  ensure          => absent,
  applicationpool => 'DefaultAppPool',
  require         => Iis_feature['Web-WebServer'],
}
iis_application_pool { [
  'DefaultAppPool',
  '.NET v4.5 Classic',
  '.NET v4.5',]:
    ensure  => absent,
    require => Iis_site['Default Web Site'],
}

# application in iis
iis_application_pool { $_chocolatey_server_app_pool_name:
  ensure                    => 'present',
  state                     => 'started',
  enable32_bit_app_on_win64 => true,
  managed_runtime_version   => 'v4.0',
  start_mode                => 'AlwaysRunning',
  idle_timeout              => '00:00:00',
  restart_time_limit        => '00:00:00',
}
-> iis_site { $_chocolatey_server_dns_name:
  ensure          => 'started',
  physicalpath    => $_chocolatey_server_location,
  applicationpool => $_chocolatey_server_app_pool_name,
  preloadenabled  => true,
  bindings        =>  [
    {
      'bindinginformation' => "*:80:${_chocolatey_server_dns_name}",
      'protocol'           => 'http',
    }
  ],
  require         => Package['chocolatey.server'],
}


# lock down web directory
-> acl { $_chocolatey_server_location:
  purge                      => true,
  inherit_parent_permissions => false,
  permissions                => [
    { identity => 'Administrators', rights => ['full'] },
    { identity => 'IIS_IUSRS', rights => ['read'] },
    { identity => 'IUSR', rights => ['read'] },
    { identity => "IIS APPPOOL\\${_chocolatey_server_app_pool_name}", rights => ['read'] }
  ],
  require                    => Package['chocolatey.server'],
}
-> acl { "${_chocolatey_server_location}/App_Data":
  permissions => [
    { identity => "IIS APPPOOL\\${_chocolatey_server_app_pool_name}", rights => ['modify'] },
    { identity => 'IIS_IUSRS', rights => ['modify'] }
  ],
  require     => Package['chocolatey.server'],
}

chocolateysource {'chocolatey':
  ensure => absent,
}

chocolateysource { $_chocolatey_server_dns_name:
  ensure   => present,
  location => "http://${_chocolatey_server_dns_name}/chocolatey",
  require  => File['C:/windows/system32/drivers/etc/hosts']
}


# Internalize and push packages
