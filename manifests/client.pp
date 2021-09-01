include chocolab::base
include chocolab::choco

# Chocolatey packages
Package { provider => 'chocolatey' }

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

# package { 'notepadplusplus':
#   ensure => latest,
# }

# package { 'vscode':
#   ensure          => 'present',
#   install_options => [
#     '-params',
#     '"',
#     '/NoContextMenuFiles',
#     '/NoContextMenuFolders',
#     '/NoQuicklaunchIcon',
#     '/NoDesktopIcon',
#     '"',
#   ],
# }

file { 'C:/Git':
  ensure => directory,
  owner  => system,
}
-> file { 'C:/Git/README.txt':
  ensure  => present,
  content => 'Git repos here',
  owner   => system,
}
