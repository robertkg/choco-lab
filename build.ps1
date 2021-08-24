$ErrorActionPreference = 'Stop'

Write-Output '----------- DOCKER COMPOSE -----------'
docker-compose up -d --build --force-recreate
if (!$?) { throw 'docker-compose failed' }

Write-Output '----------- CHOCOSERVER MANIFEST -----------'
bolt apply --log-level debug .\manifests\chocoserver.pp -t chocoserver
if (!$?) { throw 'bolt apply failed' }

Write-Output '----------- PUSH PACKAGES -----------'
. $PSScriptRoot\src\Get-ChocolateyPackage.ps1
. $PSScriptRoot\src\Push-ChocolateyPackage.ps1

$packages = @(
    'chocolatey-core.extension'
    'git'
    'git.install'
    'nodejs-lts'
    # 'notepadplusplus'
    # 'notepadplusplus.install'
    # 'DotNet4.5.2'
    # 'vscode'
    # 'vscode.install'
    # 'KB2919355'
    # 'KB2919442'
    # 'sql-server-management-studio'
)

$packages | ForEach-Object {
    Get-ChocolateyPackage -Name $_
}

Push-ChocolateyPackage 'C:\Temp\*.nupkg' -Confirm:$false

Write-Output '----------- CLIENT MANIFEST -----------'
bolt apply --log-level debug .\manifests\client.pp -t client
if (!$?) { throw 'bolt apply failed' }
