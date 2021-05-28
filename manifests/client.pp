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

# Workaround for host resource
file { 'C:/windows/system32/drivers/etc/hosts':
  ensure  => present,
  content => '172.20.0.10 chocolab.local # Internal chocolatey repo'
}

chocolateysource {'chocolatey':
  ensure => disabled,
}

chocolateysource {'chocolab.local':
  ensure   => present,
  location => 'http://chocolab.local/chocolatey',
  require  => File['C:/windows/system32/drivers/etc/hosts']
}

# Set default package provider
Package { provider => 'chocolatey' }

# Install packages
package { 'git':
  ensure          => latest,
  provider        => chocolatey,
  install_options => [
    '-params',
    '"',
    '/GitOnlyOnPath',
    '/WindowsTerminal',
    '/NoShellIntegration',
    '/NoCredentialManager',
    '/NoGitLfs', '/SChannel',
    '"'
  ]
}

package { 'nodejs-lts':
  ensure   => latest,
}

package { 'notepadplusplus':
  ensure => latest,
}
