include chocolab::base
include chocolab::choco

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

exec { 'refresh-env':
  command     => 'C:/ProgramData/chocolatey/bin/RefreshEnv.cmd',
  refreshonly => true,
  provider    => windows,
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
