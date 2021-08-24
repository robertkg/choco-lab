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

  if $facts['hostname'] == 'chocoserver' {
    package { 'chocolatey.server':
      ensure => 'present',
      before => Chocolateysource['chocolatey'],
    }
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
    location => 'http://chocolab.local/chocolatey',
    require  => Host['chocolab.local'],
  }

}


