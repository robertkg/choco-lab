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

file { 'C:/Windows/System32/WindowsPowerShell/v1.0/profile.ps1':
  ensure  => present,
  content => file('chocolab/profile.ps1'),
}

chocolateysource {'chocolatey':
  ensure => absent,
}

chocolateysource {'chocolab.local':
  ensure   => present,
  location => 'http://chocolab.local/chocolatey',
  require  => File['C:/windows/system32/drivers/etc/hosts']
}

exec { 'refresh-env':
  command     => 'C:/ProgramData/chocolatey/bin/RefreshEnv.cmd',
  refreshonly => true,
  provider    => windows,
}

# Set default package provider
Package { provider => 'chocolatey' }

# Chocolatey packages
package { 'git':
  ensure          => latest,
  install_options => [
    '-params',
    '"',
    '/GitOnlyOnPath',
    '/WindowsTerminal',
    '/NoShellIntegration',
    '/NoCredentialManager',
    '/NoGitLfs', '/SChannel',
    '"'
  ],
  notify          => Exec['refresh-env'],
  require         => Chocolateysource['chocolab.local'],
}

package { 'nodejs-lts':
  ensure   => latest,
}

package { 'notepadplusplus':
  ensure => latest,
}

package { 'vscode':
  ensure          => 'present',
  install_options => [
    '-params',
    '"',
    '/NoContextMenuFiles',
    '/NoContextMenuFolders',
    '/NoQuicklaunchIcon',
    '/NoDesktopIcon',
    '"',
  ],
}

file { 'C:/Git':
  ensure => directory,
  owner  => system,
}
-> file { 'C:/Git/README.txt':
  ensure  => present,
  content => 'Git repos here',
  owner   => system,
}

vcsrepo { 'chocolab':
  ensure   => present,
  path     => 'C:/Git/chocolab',
  source   => 'https://github.com/robertkg/chocolab.git',
  provider => git,
  require  => File['C:/Git'],
}
