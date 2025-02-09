[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True, Position=0)]
    [string]$portName,
    
	# $portVersionedTag: 'v${version}', '${version}', 'my-tag-${version}', 'my-${version}-tag', etc.
    # Use 'tag-${version}' with single quotes to pass powershell parameters containing '$'.
    [Parameter(Mandatory=$True, Position=1)]
    [string]$portVersionedTag,

    [Parameter(Mandatory=$False, Position=2)]
    [string]$overrideRepoName
)
Set-StrictMode -Version Latest

Import-Module '.\VcpkgFunctionsLibrary.psm1'

$localVcpkgJson = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"
$localJson = Get-VcpkgJsonInfo $localVcpkgJson

$localVersion = $portVersionedTag -replace "(?i)\$\{version\}", $localJson.version

if ($overrideRepoName -ne "")
{
    $portRepo = $overrideRepoName
}
elseif ($localJson.homepage.StartsWith("https://github.com/"))
{
    $portRepo = $localJson.homepage -replace "https://github.com/", ""
}
else
{
	throw "Missing or invalid 'homepage' field in vcpkg.json. Please specify a valid 'overrideRepoName' command-line parameter."
}

$remoteLatestReleaseUrl = "https://api.github.com/repos/" + $portRepo + "/releases/latest"
$remoteVersion = Get-GithubLatestReleaseVersion $remoteLatestReleaseUrl

if ($localVersion -eq $remoteVersion)
{
    Write-Host "$($portName): same version $($localVersion)"
}
else
{
    Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion) - Update needed?"
}
