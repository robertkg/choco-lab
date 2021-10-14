#Requires -PSEdition Core
$ErrorActionPreference = 'Stop'

# Self-signed SSL certificate for chocolab.local
do {
    $prompt = Read-Host 'Generate SSL certificate for site? [y/n]'
    if ($prompt -match '^y$') {
        $cerPath = "$PSScriptRoot\client\cert\chocolab.local.cer"
        $pfxPath = "$PSScriptRoot\nexus\cert\chocolab.local.pfx"

        $guid = (New-Guid).Guid
        $guid | Out-File "$pfxPath`.password"
        $pfxPassword = $guid | ConvertTo-SecureString -AsPlainText
        $cert = New-SelfSignedCertificate -CertStoreLocation Cert:\CurrentUser\My\ -DnsName chocolab.local -Subject 'CN=chocolab.local'
        Export-PfxCertificate -Cert $cert -Password $pfxPassword -FilePath $pfxPath 1>$null
        Export-Certificate -Cert $cert -Type CERT -FilePath $cerPath 1>$null
        Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)"
    }
} while ($prompt -notmatch '^y|n$')

Write-Output '----------- DOCKER COMPOSE -----------'
docker-compose up -d --build --force-recreate
if (!$?) { Write-Error 'docker-compose failed' }

Write-Output '----------- CLIENT MANIFEST -----------'
bolt apply --log-level debug .\manifests\client.pp -t client
if (!$?) { Write-Error 'bolt apply failed' }

Write-Output '----------- NEXUS MANIFEST -----------'
bolt apply --log-level debug .\manifests\nexus.pp -t nexus
if (!$?) { Write-Error 'bolt apply failed' }

Write-Output '----------- NEXUS SETUP -----------'
docker exec nexus powershell -nologo -noninteractive -noprofile -file 'c:\script\setup.ps1'

# Write-Output '----------- PUSH PACKAGES -----------'
# . $PSScriptRoot\src\Get-ChocolateyPackage.ps1
# . $PSScriptRoot\src\Push-ChocolateyPackage.ps1

# $packages = @(
#     'chocolatey-core.extension'
#     'git'
#     'git.install'
#     'nodejs-lts'
#     # 'notepadplusplus'
#     # 'notepadplusplus.install'
#     # 'DotNet4.5.2'
#     # 'vscode'
#     # 'vscode.install'
#     # 'KB2919355'
#     # 'KB2919442'
#     # 'sql-server-management-studio'
# )

# $packages | ForEach-Object {
#     Get-ChocolateyPackage -Name $_
# }

# Push-ChocolateyPackage 'C:\Temp\*.nupkg' -Confirm:$false



