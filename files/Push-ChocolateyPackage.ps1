<#
.SYNOPSIS
    Internalizes NuGet packages from chcocolatey.org to internal chocolab NuGet repository.
.DESCRIPTION
    Mockup script for internalizing NuGet packages to an internal chocolatey repository.
.EXAMPLE
    PS C:\> Push-ChocolateyPackage.ps1
    Explanation of what the example does
.INPUTS
    Inputs (if any)
.OUTPUTS
    Output (if any)
.NOTES
    General notes
#>

$apiKey = 'chocolateyrocks' # Default key
$source = 'http://chocolab.local:8080' # See docker-compose for port map
#Set-Location 'C:\Temp'

function Push-ChocolateyPackage {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.IO.FileInfo]
        $Package
    )
    $params = @{
        FilePath     = 'C:\ProgramData\chocolatey\bin\choco.exe'
        ArgumentList = @('push', $FilePath, '--source=http://chocolab.local:8080', '--api-key=chocolateyrocks')
        NoNewWindow  = $true
        Wait         = $true
    }
    Start-Process @params
}

$ProgressPreference = 'SilentlyContinue'

Push-Location 'C:\Temp'
$wc = New-Object System.Net.WebClient

# chocolatey-core.extension
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/chocolatey-core.extension/1.3.5.1', 'C:\Temp\chocolatey-core.extension.1.3.5.1.nupkg')
choco push 'chocolatey-core.extension.1.3.5.1.nupkg' -s $source -k $apiKey --force
    
# git + git.install
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/git.install/2.31.1', 'C:\Temp\git.install.2.31.nupkg')
choco push 'git.install.2.31.nupkg' -s $source -k $apiKey --force
    
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/git/2.31.1', 'C:\Temp\git.2.31.nupkg')
choco push 'git.2.31.nupkg' -s $source -k $apiKey --force
    
# nodejs-lts
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/nodejs-lts/14.17.0', 'C:\Temp\nodejs-lts.14.17.0.nupkg')
choco push 'nodejs-lts.14.17.0.nupkg' -s $source -k $apiKey --force
    
# notepadplusplus
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/notepadplusplus.install/7.9.5', 'C:\Temp\notepadplusplus.install.7.9.5.nupkg')
choco push 'notepadplusplus.install.7.9.5.nupkg' -s $source -k $apiKey --force
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/notepadplusplus/7.9.5', 'C:\Temp\notepadplusplus.7.9.5.nupkg')
choco push 'notepadplusplus.7.9.5.nupkg' -s $source -k $apiKey --force
    
# vscode
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/vscode/1.56.2', 'C:\Temp\vscode.1.56.2.nupkg')
choco push 'vscode.1.56.2.nupkg' -s $source -k $apiKey --force
    
$wc.DownloadFile('https://community.chocolatey.org/api/v2/package/vscode.install/1.56.2', 'C:\Temp\vscode.install.1.56.2.nupkg')
Expand-Archive '.\vscode.install.1.56.2.nupkg' -DestinationPath '.\vscode.install.1.56.2'
Remove-Item '.\vscode.install.1.56.2\package\' -Recurse -ErrorAction SilentlyContinue 
Remove-Item '.\vscode.install.1.56.2\_rels\' -Recurse -ErrorAction SilentlyContinue
Remove-Item '.\vscode.install.1.56.2\`[Content_Types`].xml' -ErrorAction SilentlyContinue
    
do {
    $prompt = Read-Host 'Download installer, save it in \tools and edit ChocolateyInstall.ps1. Press y once complete' # Temp, try to automate
} until ($prompt -eq 'y')

choco pack '.\vscode.install.1.56.2\vscode.install.nuspec'
choco push '.\vscode.install.1.56.2.nupkg' -s $source -k $apiKey --force

# Summary
choco list -s chocolab.local --nocolor

Pop-Location