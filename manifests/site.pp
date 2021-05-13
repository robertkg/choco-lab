file {'C:/Puppet.txt':
  ensure  => present,
  content => 'Managed by Puppet',
  owner   => system,
}

file { 'C:/Puppet':
  ensure => directory,
  owner  => system,
}

