# chocolab
Lab environment for a server/client setup using Chocolatey Simple Server, Puppet Bolt and Docker.

## Setup

### Build
Creates containers from docker-compose.yaml.
```
docker-compose up -d --build
```

### Verify connection
Runs a test connection on the containers to verify WinRM connection is working.
```
bolt command run whoami -t containers
```

### Sync modules
Syncs modules from Puppetfile.
```
bolt module install
```

### Apply catalog
Applies a manifest from the catalog on containers
```
bolt apply ./manifests/site.pp -t containers -l info
```

### Push some packages

Some example packages for testing purposes.
Packages with external installer need to be recompiled manually atm.

```
.\files\Push-ChocolateyPackage.ps1
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

