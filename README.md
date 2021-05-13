# choco-lab

Lab environment for a server/client setup using Chocolatey Simple Server, Puppet Bolt and Docker.

## Setup

Build

```
cd choco-lab
docker compose up -d --build
```

Verify connection

```
bolt command run ping -t containers
```

Apply catalog

```
bolt apply ./manifests/site.pp -t containers
```

Remote into container

```
docker exec -it <chococli/chocosrv> powershell
```

## Debugging

Testing WinRM connection:

```powershell
$cred = new-object System.Management.Automation.PSCredential ('Bolt', (ConvertTo-Secure
String -AsPlainText '<password>' -Force))
Enter-PSSession -Credential $cred -ComputerName localhost -Port <55986, 55987> -Authentication Basic -UseSSL -SessionOption (New-PSSessionOption -SkipCACheck -SkipCNCheck)
```
