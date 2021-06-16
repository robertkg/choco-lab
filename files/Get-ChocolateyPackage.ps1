
<#
.SYNOPSIS
Downloads NuGet packages from the Chocolatey Community Repository.

.DESCRIPTION
This script downloads a given version of a given NuGet package from the chocolatey community repository and checks for dependencies.
If a version is not supplied, the latest version of the package will be downloaded.
This script is used alongside the Push-ChocolateyPackage script in this repo to internalize chocolatey packages to an internal NuGet feed.
Packages without bundled installers must be recompiled to avoid downloading at runtime on the deployment target.
See https://docs.chocolatey.org/en-us/guides/create/recompile-packages.

.PARAMETER Name
Specifies the name of the Chocolatey package.

.PARAMETER Version
Specifies the version of the Chocolatey package to download.

.EXAMPLE
Get-ChocolateyPackage -Name git -Version 2.32.0

.NOTES
General notes
#>
function Get-ChocolateyPackage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-zA-Z0-9\.-]+$')]
        [string]
        $Name,

        [Parameter()]
        [ValidatePattern('^[0-9\.]+$')]
        [string]
        $Version

        # [Parameter()]
        # [switch]
        # $ResolveDependency
    )

    # Fetch file name from redir
    $baseUri = 'https://community.chocolatey.org/api/v2/package'
    if ($PSBoundParameters.ContainsKey('Version')) {
        $uri = "$baseUri/$Name/$Version"
    }
    else {
        $uri = "$baseUri/$Name"
    }

    Write-Progress -Activity $Name -PercentComplete 0

    $request = [System.Net.WebRequest]::Create($uri)
    $request.AllowAutoRedirect = $false

    try {
        $response = $request.GetResponse()
    }
    catch {
        throw "Error requesting '$uri': $($_.Exception.Message)"
    }

    # Extract nuget package name, version and file extension from response header
    if ($response.StatusCode -eq 'Found') {
        $responseHeader = $response.GetResponseHeader('Location')
        $fileName = $responseHeader -split '/' | Select-Object -Last 1
    }

    if ($outFile -notmatch '^\S+\.nupkg$') {
        throw "Could not determine file name from response header $($response.ResponseUri)"
    }
    
    $downloadDir = 'C:\Temp'
    $outFile = "$downloadDir\$fileName"

    if (-not (Test-Path $downloadDir)) {
        New-Item -ItemType Directory -Path $downloadDir -ErrorAction Stop 1>$null   
    }

    Write-Progress -Activity $Name
    
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($responseHeader, $outFile)

    $result = [PSCustomObject] @{
        Package     = $Name
        Source      = $responseHeader
        Destination = $outFile
        Dependency  = $false 
        RequiredBy  = $null
    }

    Write-Progress -Activity $Name

    Write-Output $result

    #region Check nuspec file for dependencies
    try {
        $archiveDir = $outFile -split '\.nupkg$' | Select-Object -First 1
        Expand-Archive -Path $outFile -DestinationPath $archiveDir        
        
        [xml] $nuspec = Get-Content "$archiveDir\*.nuspec"
        $dependencies = $nuspec.package.metadata.dependencies.dependency

        if ($dependencies.Count -gt 0) {
            Write-Warning "Package $Name has dependencies: $($dependencies.id -join ', ')"

            # This will cause problems with dependencies having dependencies
            # All packages should be explicitly requested
            
            #region ResolveDependency
            # if ($PSBoundParameters.ContainsKey('ResolveDependency')) {
            #     foreach ($dep in $dependencies) {
            #         # Some nuspec files use characters such as [] that would break the download request
            #         # Extract version number
            #         $depVersion = $dep.Version | Select-String "(?'version'[0-9\.]+)"
            #         $depVersion = $depVersion.Matches.Groups | Where-Object Name -EQ 'version' | Select-Object -ExpandProperty Value

            #         $depUri = "$baseUri/$($dep.id)/$depVersion"

            #         Write-Progress -Activity $Name

            #         # Fetch dependency file name from redir
            #         $request = [System.Net.WebRequest]::Create($depUri)
            #         $request.AllowAutoRedirect = $false
                
            #         try {
            #             $response = $request.GetResponse()
            #         }
            #         catch {
            #             throw "Error requesting '$depUri': $($_.Exception.Message)"
            #         }

            #         # Extract nuget package name, version and file extension from response header for dependency
            #         if ($response.StatusCode -eq 'Found') {
            #             $responseHeader = $response.GetResponseHeader('Location')
            #             $depFileName = $responseHeader -split '/' | Select-Object -Last 1
            #         }
                
            #         $depOutFile = "$downloadDir\$depFileName"

            #         if ($depOutFile -notmatch '^\S+\.nupkg$') {
            #             throw "Could not determine file name from response header $($response.ResponseUri)"
            #         }

            #         Write-Progress -Activity $Name 

            #         $wc.DownloadFile($depUri, $depOutFile) 

            #         $depResult = [PSCustomObject] @{
            #             Package     = $dep.id
            #             Source      = $responseHeader
            #             Destination = $depOutFile
            #             Dependency  = $true 
            #             RequiredBy  = $Name 
            #         }

            #         Write-Progress -Activity $Name

            #         Write-Output $depResult
            #     }
            # }
            # else {
            #     Write-Warning "Package $Name has dependencies: $($dependencies.id -join ', ')"
            # }
            #endregion ResolveDependency
        }
    }
    catch {
        Write-Error "Error occurred when checking nuspec file for dependencies: $($_.Exception.Message)"
    }
    finally {
        Remove-Item -Path $archiveDir -Recurse -Confirm:$false
    }
    #endregion Check nuspec file for dependencies


}

# Get-ChocolateyPackage -Name 'git' -ResolveDependency
# Get-ChocolateyPackage -Name 'nodejs-lts' -ResolveDependency
# Get-ChocolateyPackage -Name 'winscp' -ResolveDependency
# Get-ChocolateyPackage -Name 'notepadplusplus' -ResolveDependency
# Get-ChocolateyPackage -Name 'gpg4win' -ResolveDependency
# Get-ChocolateyPackage -Name 'puppet-bolt' -ResolveDependency
# Get-ChocolateyPackage -Name 'vscode' -ResolveDependency
# Get-ChocolateyPackage -Name 'sql-server-management-studio' -ResolveDependency
