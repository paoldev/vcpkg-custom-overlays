[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True, Position=0)]
    [string]$portName,
    
    [switch]$UseReleaseTag
)
Set-StrictMode -Version Latest

Import-Module '.\VcpkgFunctionsLibrary.psm1'

$localVcpkgJson = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"
$localPortFile = $PSScriptRoot + "/../ports/" + $portName + "/portfile.cmake"

$localVersion = (Get-VcpkgJsonInfo $localVcpkgJson).version

$portFile = Get-GithubPortFileInfo $localPortFile $localVersion

$remoteLatestReleaseUrl = "https://api.github.com/repos/" + $portFile.repo + "/releases/latest"
$remoteLatestCommitUrl = "https://api.github.com/repos/" + $portFile.repo + "/commits/" + $portFile.branch

if ($UseReleaseTag)
{
	$localVersion = $portFile.ref
    $remoteVersion = Get-GithubLatestReleaseVersion $remoteLatestReleaseUrl
}
else
{
	$localVersion = $portFile.ref + "@" + $localVersion
	$commitInfo = Get-GithubLatestCommitShaAndDate $remoteLatestCommitUrl
    $remoteVersion = $commitInfo.sha + "@" + $commitInfo.date
}

if ($localVersion -eq $remoteVersion)
{
    Write-Host "$($portName): same version $($localVersion)"
}
else
{
    Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion) - Update needed?"
}
