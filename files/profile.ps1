using namespace System.Management.Automation
using namespace System.Management.Automation.Language

function Get-Motd {
    @"

                    ##        .            
              ## ## ##       ==            
           ## ## ## ##      ===            
       /""""""""""""""""\___/ ===        
  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~   
       \______ o          __/            
         \    \        __/             
          \____\______/
          
           Container: chocolab_$(hostname)
           Logged in as: $($env:USERNAME)
           Current time: $(Get-Date -Format 'dd.MM.yyyy HH:mm')

"@
}

Get-Motd

function prompt {
    "[DOCKER] $($executionContext.SessionState.Path.CurrentLocation.Path)> "
}

function Get-HostFile {
    Get-Content C:\Windows\System32\drivers\etc\hosts
}
