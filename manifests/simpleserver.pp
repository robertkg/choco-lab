include chocolatey

chocolateyfeature {'autouninstaller':
  ensure => enabled,
}

chocolateyfeature {'usepackageexitcodes':
  ensure => disabled,
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
    require => iis_site['Default Web Site'],
}

# application in iis
iis_application_pool { 'ChocolateyServer':
  ensure                    => 'present',
  state                     => 'started',
  enable32_bit_app_on_win64 => true,
  managed_runtime_version   => 'v4.0',
  start_mode                => 'AlwaysRunning',
  idle_timeout              => '00:00:00',
  restart_time_limit        => '00:00:00',
}
-> iis_site {'chocolab.local':
  ensure          => 'started',
  physicalpath    => $_chocolatey_server_location,
  applicationpool => $_chocolatey_server_app_pool_name,
  preloadenabled  => true,
  bindings        =>  [
    {
      'bindinginformation'   => '*:443:chocolab.local',
      'protocol'             => 'https',
      'certificatehash'      => '3598FAE5ADDB8BA32A061C5579829B359409856F',
      'certificatestorename' => 'MY',
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


file { 'C:/Puppet.txt':
  ensure  => present,
  content => 'Managed by Puppet',
  owner   => system,
}
