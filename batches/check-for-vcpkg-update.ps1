[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True, Position=0)]
    [string]$portName,
    
    [Parameter(Mandatory=$False, Position=1)]
    [string]$localVcpkgDir = ""
)
Set-StrictMode -Version Latest

Function Get-VcpkgJson-Version
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory=$True)]
        [Object]$JsonFile,

        [switch]$AppendPortVersion
    )
    Begin {
        $Version = [string]@{}
        $PortVersion = [string]@{}
    }
    Process {

        if ([bool]($JsonFile.PSobject.Properties.name -match "^version$"))
        {
            $Version = $JsonFile.version
        }
        elseif ([bool]($JsonFile.PSobject.Properties.name -match "^version-date$"))
        {
            $Version = $JsonFile.'version-date'
        }
        elseif ([bool]($JsonFile.PSobject.Properties.name -match "^version-string$"))
        {
            $Version = $JsonFile.'version-string'
        }
        elseif ([bool]($JsonFile.PSobject.Properties.name -match "^version-semver$"))
        {
            $Version = $JsonFile.'version-semver'
        }
        else
        {
            throw "Missing version field."
        }

        if ([bool]($JsonFile.PSobject.Properties.name -match "^port-version$"))
        {
            $PortVersion = $JsonFile.'port-version'
        }
        else
        {
            $PortVersion = '0'
        }
    }
    End {

        if ($AppendPortVersion)
        {
            $Version + '#' + $PortVersion
        }
        else
        {
            $Version
        }
    }
}

if (-Not [string]::IsNullOrWhiteSpace($localVcpkgDir))
{
    $remoteUrl = $localVcpkgDir + "/ports/" + $portName + "/vcpkg.json"
    $remoteJson = (Get-Content $remoteUrl -Raw) | ConvertFrom-Json
}
else
{
    $remoteUrl = "https://raw.githubusercontent.com/microsoft/vcpkg/master/ports/" + $portName + "/vcpkg.json"
    $remoteJson = (Invoke-WebRequest $remoteUrl) | ConvertFrom-Json
}

$localUrl = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"
$localJson = (Get-Content $localUrl -Raw) | ConvertFrom-Json

$remoteVersion = Get-VcpkgJson-Version $remoteJson -AppendPortVersion
$localVersion = Get-VcpkgJson-Version $localJson -AppendPortVersion

if ($remoteVersion -eq $localVersion)
{
    Write-Host "$($portName): same version $($localVersion)"
}
else
{
    Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion) - Update needed?"
}
