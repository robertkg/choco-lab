# chocolab
Lab environment for a server/client setup using Chocolatey Simple Server, Puppet Bolt and Docker.

## Setup

Puppet Bolt and Docker Desktop must be installed on your machine. 
You must also enable windows containers in Docker Desktop.

```
choco install docker-desktop puppet-bolt
```

### Build

The build script will compose the client and server docker containers, apply the Puppet manifests and push a set of test packages to the internal Chocolatey repository.

```powershell
.\build.ps1
```

## Debugging

### Testing WinRM connection:
Bolt uses WinRM to apply configuration. You can debug WinRM connection issues with:

```powershell
$splat = @{
    Credential     = Get-Credential 'Bolt'
    ComputerName   = 'localhost'
    Port           = 55986 # See docker-compose.yaml for port maps
    Authentication = 'Basic'
    UseSSL         = $true
    SessionOption  = New-PSSessionOption -SkipCACheck -SkipCNCheck # Using self-signed cert for WinRM connection
}

Enter-PSSession @splat
```

### Remote into container
Start an interactive session through docker on the container:

```
docker exec -it <client/chocoserver> powershell
```

