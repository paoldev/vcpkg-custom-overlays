[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True, Position=0)]
    [string]$portName,
    
    [Parameter(Mandatory=$False, Position=1)]
    [string]$localVcpkgDir = ""
)
Set-StrictMode -Version Latest

Import-Module '.\VcpkgFunctionsLibrary.psm1'

$localUrl = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"
if (-Not [string]::IsNullOrWhiteSpace($localVcpkgDir))
{
    $remoteUrl = $localVcpkgDir + "/ports/" + $portName + "/vcpkg.json"
}
else
{
    $remoteUrl = "https://raw.githubusercontent.com/microsoft/vcpkg/master/ports/" + $portName + "/vcpkg.json"
}

$localJson = Get-VcpkgJsonInfo $localUrl
$remoteJson = Get-VcpkgJsonInfo $remoteUrl

$localVersion = $localJson.version + "#" + $localJson.portversion
$remoteVersion = $remoteJson.version + "#" + $remoteJson.portversion

if ($localVersion -eq $remoteVersion)
{
    Write-Host "$($portName): same version $($localVersion)"
}
else
{
    Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion) - Update needed?"
}
