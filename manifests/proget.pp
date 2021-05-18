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

package { 'sql-server-express':
  ensure   => '2019.20200409',
}

# consider dockerfile https://docs.inedo.com/docs/proget-installation-installation-guide-linux-docker
