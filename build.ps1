$ErrorActionPreference = 'Stop'

Write-Output '----------- DOCKER COMPOSE -----------'
docker-compose up -d --build --force-recreate

Write-Output '----------- CHOCOSERVER MANIFEST -----------'
bolt apply .\manifests\chocolateyserver.pp -t chocoserver

Write-Output '----------- PUSH PACKAGES -----------'
. $PSScriptRoot\src\Get-ChocolateyPackage.ps1
. $PSScriptRoot\src\Push-ChocolateyPackage.ps1

$packages = @(
    'chocolatey-core.extension'
    'git'
    'git.install'
    'nodejs-lts'
    'notepadplusplus'
    'notepadplusplus.install'
    'DotNet4.5.2'
    'vscode'
    'vscode.install'
    'KB2919355'
    'KB2919442'
    'sql-server-management-studio'
)

$packages | ForEach-Object {
    Get-ChocolateyPackage -Name $_
}

Push-ChocolateyPackage 'C:\Temp\*.nupkg' -Confirm:$false

Write-Output '----------- CLIENT MANIFEST -----------'
bolt apply .\manifests\client.pp -t client