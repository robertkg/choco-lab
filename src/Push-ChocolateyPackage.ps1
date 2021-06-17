<#
.SYNOPSIS
Pushes local Chocolatey NuGet packages to a Chocolatey source.

.DESCRIPTION
This script pushes one or more Chocolatey NuGet packages to a Chocolatey package repository using the choco push command from the Chocolatey CLI.
If the package version already exists in the source, it will be skipped.
This script is used alongside the Get-ChocolateyPackage script in this repo to internalize chocolatey packages to an internal NuGet feed.
Packages without bundled installers must be recompiled before being pushed to avoid downloading at runtime on the deployment target. 
See https://docs.chocolatey.org/en-us/guides/create/recompile-packages.

.PARAMETER Path
Specifies the path to the nupkg package file.

.PARAMETER ApiKey
Specifies the API key to use for the given Chocolatey source.

.PARAMETER Source
Specifies the Chocolatey source to push the package to.

.EXAMPLE
Push-ChocolateyPackage -Path C:\Temp\mypackage.1.2.3.nupkg -ApiKey myapikey -Source http://chocolab.local:8080

This command pushes the version 1.2.3 of package 'mypackage' to the Chocolatey source http://chocolab.local:8080. 

.EXAMPLE
Push-ChocolateyPackage C:\Packages -ApiKey myapikey

This command pushes all .nupkg packages from the C:\Packages directory.
#>
function Push-ChocolateyPackage {
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
    param (
        [Parameter(Mandatory)]
        [SupportsWildcards()]
        [System.IO.FileInfo]
        $Path,

        [Parameter(Mandatory)]
        [string]
        $ApiKey,

        # Parameter help description
        [Parameter()]
        [uri]
        $Source = 'http://chocolab.local:8080'
    )

    $nupkgs = Get-ChildItem -Path $Path | Where-Object Name -Match '\.nupkg$'

    if ($PSCmdlet.ShouldProcess($Source, "Push packages $($nupkgs.Name -join ', ')")) {
        foreach ($nupkg in $nupkgs) {
            try {
                $push = choco push $nupkg.FullName -r -s $source -k $ApiKey --force # Force required when using http repo
                
                if ($LASTEXITCODE -ne 0) {
                    throw $push
                }

                Write-Output $push
            }
            catch {
                if ($_.Exception.Message -match 'package version already exists on the repository\.$') {
                    Write-Warning "$($nupkg.Name) already exists on the repository"
                    continue
                }
                else {
                    Write-Error "Error pushing $($nupkg.Name): $($_.Exception.Message)"
                }
            }
        }
    }
}