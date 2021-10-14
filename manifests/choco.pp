# Class: chocolab::choco
#
#
class chocolab::choco {

  include chocolatey

  # Set default package provider
  Package { provider => 'chocolatey' }

  package { 'chocolatey':
    ensure => 'present',
  }

  host { 'chocolab.local':
    ensure  => present,
    ip      => '172.20.0.10',
    comment => 'Internal Chocolatey repo',
    target  => 'C:/windows/system32/drivers/etc/hosts',
  }

  chocolateysource {'chocolatey':
    ensure => absent,
  }

  chocolateysource {'chocolab.local':
    ensure   => present,
    location => 'https://chocolab.local/repository/chocolatey/',
    user     => 'chocoread',
    password => 'Passw0rd',
    require  => Host['chocolab.local'],
  }

}


