[CmdletBinding()]
Param (
    [Parameter(Mandatory=$True, Position=0)]
    [string]$portName,
    
    [switch]$UseReleaseTag
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

Function Get-LatestCommitShaAndDate
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory=$True)]
        [Object]$remoteLatestCommitUrl
    )
    Begin {
        $sha = [string]@{}
        $date = [string]@{}
    }
    Process {

        $remoteLatestCommit = (Invoke-WebRequest $remoteLatestCommitUrl) | ConvertFrom-Json
        
        if ([bool]($remoteLatestCommit.PSobject.Properties.name -match "^sha$"))
        {
            $sha = $remoteLatestCommit.sha
        }
        else
        {
            throw "Missing sha field."
        }
        
        if ([bool]($remoteLatestCommit.PSobject.Properties.name -match "^commit$"))
        {
            $commit = $remoteLatestCommit.commit
            if ([bool]($commit.PSobject.Properties.name -match "^committer$"))
            {
                $committer = $commit.committer
                if ([bool]($committer.PSobject.Properties.name -match "^date$"))
                {
                    $date = $committer.date
                }
            }
            elseif ([bool]($commit.PSobject.Properties.name -match "^author$"))
            {
                $author = $commit.author
                if ([bool]($author.PSobject.Properties.name -match "^date$"))
                {
                    $date = $author.date
                }
            }
            else
            {
                throw "Missing both committer and author fields."
            }
            
            if ($date -eq "")
            {
                throw "Missing date field in both committer and author fields."
            }
            else
            {
                $date = (Get-Date $date).ToString("yyyy-MM-dd")
            }
        }
        else
        {
            throw "Missing commit field."
        }
    }
    End {

        $sha + "@" + $date
    }
}

Function Get-PortFileInfo
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [Parameter(Mandatory=$True)]
        [Object]$portFileName,
        
        [Parameter(Mandatory=$True)]
        [Object]$portVersion
    )
    Begin {
        $repo = [string]@{}
        $ref = [string]@{}
        $branch = [string]@{}
    }
    Process {

        # These patterns may not work if '(' or ')' are present in comments or other lines where vcpkg_from_github(...) content is extracted from.
        $pattern_github = "vcpkg_from_github[\s]*\([^\)]*\)"
        $pattern_repo = "repo[\s]*(?<repo>[\S]*)"
        $pattern_ref = "ref[\s]*(?<ref>[\S]*)"
        $pattern_branch = "head_ref[\s]*(?<branch>[\S]*)"
        
        $portFile = Get-Content $portFileName
        
        $matches_github = Select-String -Pattern $pattern_github -InputObject $portFile
        
        $matches_repo = Select-String -Pattern $pattern_repo -InputObject $matches_github.Matches.Value -CaseSensitive:$false
        $matches_ref = Select-String -Pattern $pattern_ref -InputObject $matches_github.Matches.Value -CaseSensitive:$false
        $matches_branch = Select-String -Pattern $pattern_branch -InputObject $matches_github.Matches.Value -CaseSensitive:$false
        
        # Can't use named groups, but current captures are always at index 1.
        $repo = $matches_repo.Matches.Groups[1].Value
        $ref = $matches_ref.Matches.Groups[1].Value
        $branch = $matches_branch.Matches.Groups[1].Value

        # Fix port refs containing ${version} field.
        $ref = $ref -replace "(?i)\$\{version\}", $portVersion
    }
    End {
        @{
            repo=$repo
            ref=$ref
            branch=$branch
        }
    }
}

$localVcpkgJson = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"
$localPortFile = $PSScriptRoot + "/../ports/" + $portName + "/portfile.cmake"
$localJson = (Get-Content $localVcpkgJson -Raw) | ConvertFrom-Json

$localVersion = Get-VcpkgJson-Version $localJson

$portFile = Get-PortFileInfo $localPortFile $localVersion

$remoteLatestReleaseUrl = "https://api.github.com/repos/" + $portFile.repo + "/releases/latest"
$remoteLatestCommitUrl = "https://api.github.com/repos/" + $portFile.repo + "/commits/" + $portFile.branch

if ($UseReleaseTag)
{
    $remoteVersion = Get-LatestReleaseVersion $remoteLatestReleaseUrl
    $localVersion = $portFile.ref
}
else
{
    $remoteVersion = Get-LatestCommitShaAndDate $remoteLatestCommitUrl
    $localVersion = $portFile.ref + "@" + $localVersion
}

if ($remoteVersion -eq $localVersion)
{
    Write-Host "$($portName): same version $($localVersion)"
}
else
{
    Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion) - Update needed?"
}
