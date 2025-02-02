[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True, Position=0)]
    [string]$portName,
    
	# $portVersionedTag: 'v${version}', '${version}', 'my-tag-${version}', 'my-${version}-tag', etc.
    # Use 'tag-${version}' with single quotes to pass powershell parameters containing '$'.
    [Parameter(Mandatory=$True, Position=1)]
    [string]$portVersionedTag
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

Function Get-VcpkgJson-Homepage
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory=$True)]
        [Object]$JsonFile,

        [switch]$AppendPortVersion
    )
    Begin {
        $Homepage = [string]@{}
    }
    Process {

        if ([bool]($JsonFile.PSobject.Properties.name -match "^homepage$"))
        {
            $Homepage = $JsonFile.homepage
        }
        else
        {
            throw "Missing homepage field."
        }
    }
    End {
        $Homepage
    }
}

Function Get-LatestReleaseVersion
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory=$True)]
        [Object]$remoteLatestReleaseUrl
    )
    Begin {
        $Version = [string]@{}
    }
    Process {

        $remoteLatestRelease = (Invoke-WebRequest $remoteLatestReleaseUrl) | ConvertFrom-Json
        if ([bool]($remoteLatestRelease.PSobject.Properties.name -match "^tag_name$"))
        {
            $Version = $remoteLatestRelease.tag_name
        }
        else
        {
            throw "Missing tag_name field."
        }
    }
    End {

        $Version
    }
}

$localVcpkgJson = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"
$localJson = (Get-Content $localVcpkgJson -Raw) | ConvertFrom-Json

$localVersion = Get-VcpkgJson-Version $localJson
$portRepo = (Get-VcpkgJson-Homepage $localJson) -replace "https://github.com/", ""

$remoteLatestReleaseUrl = "https://api.github.com/repos/" + $portRepo + "/releases/latest"

$remoteVersion = Get-LatestReleaseVersion $remoteLatestReleaseUrl

$localVersion = $portVersionedTag -replace "(?i)\$\{version\}", $localVersion

if ($remoteVersion -eq $localVersion)
{
    Write-Host "$($portName): same version $($localVersion)"
}
else
{
    Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion) - Update needed?"
}
