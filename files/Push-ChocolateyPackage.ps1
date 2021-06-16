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
An example

.NOTES
General notes
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
                choco push $nupkg.FullName -s $source -k $ApiKey --force # Force required when repo uses http instead of https                    
            }
            catch {
                Write-Error "Error pushing package '$Path': $($_.Exception.Message)"
            }
        }
    }
}