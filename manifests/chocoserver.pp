include chocolab::base
include chocolab::choco

$chocoserver_hostname = 'chocolab.local'
$site_path = 'C:\\Tools\\chocolatey.server'
$app_pool_name = $chocoserver_hostname

# Workaround for host resource
# file { 'C:/windows/system32/drivers/etc/hosts':
#   ensure  => present,
#   content => "127.0.0.1 ${chocoserver_hostname} # Internal chocolatey repo"
# }

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
iis_application_pool { $app_pool_name:
  ensure                    => 'present',
  state                     => 'started',
  enable32_bit_app_on_win64 => true,
  managed_runtime_version   => 'v4.0',
  start_mode                => 'AlwaysRunning',
  idle_timeout              => '00:00:00',
  restart_time_limit        => '00:00:00',
}
-> iis_site { $chocoserver_hostname:
  ensure          => 'started',
  physicalpath    => $site_path,
  applicationpool => $app_pool_name,
  preloadenabled  => true,
  bindings        =>  [
    {
      'bindinginformation' => "*:80:${chocoserver_hostname}",
      'protocol'           => 'http',
    }
  ],
  require         => Package['chocolatey.server'],
}


# lock down web directory
-> acl { $site_path:
  purge                      => true,
  inherit_parent_permissions => false,
  permissions                => [
    { identity => 'Administrators', rights => ['full'] },
    { identity => 'IIS_IUSRS', rights => ['read'] },
    { identity => 'IUSR', rights => ['read'] },
    { identity => "IIS APPPOOL\\${app_pool_name}", rights => ['read'] }
  ],
  require                    => Package['chocolatey.server'],
}
-> acl { "${site_path}/App_Data":
  permissions => [
    { identity => "IIS APPPOOL\\${app_pool_name}", rights => ['modify'] },
    { identity => 'IIS_IUSRS', rights => ['modify'] }
  ],
  require     => Package['chocolatey.server'],
}
