# Deletes default repositories and configures a hosted/proxy chocolatey repository group
[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $HostName = 'chocolab.local',

    [Parameter()]
    [ValidatePattern('^\S+\:\S+$')]
    [string]
    $Auth = "admin:$(Get-Content 'C:\nexus\sonatype-work\nexus3\admin.password')" # Only for first-time setup
)

$ErrorActionPreference = 'Stop'

$bytes = [System.Text.Encoding]::UTF8.GetBytes($Auth)
$cred = [System.Convert]::ToBase64String($bytes)
#$portMap = ((Get-Content $PSScriptRoot\docker-compose.yaml | Select-String "- \'(?'port_map'\d{1,5})\:443\'").Matches.Groups | Where-Object Name -EQ port_map).Value
$serverAddress = "https://$HostName"
$uri = "$serverAddress/service/rest/v1/repositories/nuget"
$contentType = 'application/json'
$headers = @{'Authorization' = "Basic $cred" }

Write-Host $serverAddress

#region default repos
$repos = Invoke-RestMethod "https://$HostName/service/rest/v1/repositories" -Method Get -Headers $headers
foreach ($repo in $repos) {
    Invoke-RestMethod "https://$HostName/service/rest/v1/repositories/$($repo.name)" -Method Delete -Headers $headers 1>$null
    Write-Host "- Deleted $($repo.type) $($repo.format) repository $($repo.name)"
}
#endregion

#region chocolatey repos
# Nuget version must be set manually
# Bug ticket: https://issues.sonatype.org/browse/NEXUS-28791
$bodyProxy = @'
{
    "name": "chocolatey-proxy",
    "online": true,
    "storage": {
        "blobStoreName": "default",
        "strictContentTypeValidation": true
    },
    "cleanup": {
        "policyNames": [
            "string"
        ]
    },
    "proxy": {
        "remoteUrl": "https://chocolatey.org/api/v2/",
        "contentMaxAge": 1440,
        "metadataMaxAge": 1440
    },
    "negativeCache": {
        "enabled": true,
        "timeToLive": 1440
    },
    "httpClient": {
        "blocked": false,
        "autoBlock": true
    },
    "nugetProxy": {
        "queryCacheItemMaxAge": 3600,
        "nugetVersion": "V2"
    }
}
'@

Invoke-RestMethod -Method Post -Uri "$uri/proxy" -Body $bodyProxy -ContentType $contentType -Headers $headers 1>$null
Write-Host '- Created proxy nuget repository chocolatey-proxy'

$bodyHosted = @'
{
    "name": "chocolatey-hosted",
    "online": true,
    "storage": {
        "blobStoreName": "default",
        "strictContentTypeValidation": true,
        "writePolicy": "allow_once"
    }
}
'@

Invoke-RestMethod -Method Post -Uri "$uri/hosted" -Body $bodyHosted -ContentType $contentType -Headers $headers 1>$null
Write-Host '- Created hosted nuget repository chocolatey-hosted'

$bodyGroup = @'
{
    "name": "chocolatey",
    "online": true,
    "storage": {
        "blobStoreName": "default",
        "strictContentTypeValidation": true
    },
    "group": {
        "memberNames": [
            "chocolatey-hosted",
            "chocolatey-proxy"
        ]
    }
}
'@

Invoke-RestMethod -Method Post -Uri "$uri/group" -Body $bodyGroup -ContentType $contentType -Headers $headers 1>$null
Write-Host '- Created group nuget repository chocolatey'
#endregion

#region user management
$rolePayload = @'
{
    "id": "nx-chocolatey-reader",
    "name": "nx-chocolatey-reader",
    "description": "Read access chocolatey",
    "privileges": [
        "nx-repository-view-nuget-chocolatey-read"
    ]
}
'@

Invoke-RestMethod -Method Post -Uri "$serverAddress/v1/security/roles" -Body $rolePayload -ContentType $contentType -Headers $headers 1>$null
Write-Host '- Created role nx-chocolatey-reader'

$readerPayload = @'
{
    "userId": "chocoread",
    "firstName": "Chocolatey",
    "lastName": "Reader",
    "emailAddress": "chocolab@example.com",
    "password": "Passw0rd",
    "status": "active",
    "roles": [
        "nx-chocolatey-reader"
    ]
}
'@

Invoke-RestMethod -Method Post -Uri "$serverAddress/v1/security/users" -Body $readerPayload -ContentType $contentType -Headers $headers 1>$null
Write-Host '- Created user chocoread'
#endregion

# Output to build script to avoid remoting into container for admin OTP
if (Test-Path 'C:\nexus\sonatype-work\nexus3\admin.password') {
    $otp = (($Auth | Select-String "\S+\:(?'pw'.+)$").Matches.Groups | Where-Object Name -EQ pw).Value
    Write-Host "`nFirst-time setup of $serverAddress completed`n- Username: admin`n- OTP: $otp"
    Write-Host '`nRemember to also change nuget version to V2 on chocolatey-proxy repository until ticket #28791 i resolved'
}
