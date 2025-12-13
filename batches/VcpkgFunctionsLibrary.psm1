# 
# VcpkgFunctionsLibrary
#
# Author: paoldev
#
# Few helpers to export some vcpkg.json, portfile.cmake and github repos info.
#

Function Get-FileContent
{
    [CmdletBinding()]
    [OutputType([Object])]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$FilePathOrUrl,
        
        [switch]$ToJsonObject
    )
    Begin {
        $FileContent = [string]@{}
    }
    Process {
        Try
        {
            if ($FilePathOrUrl.StartsWith("http://") -or $FilePathOrUrl.StartsWith("https://"))
            {
                $FileContent = Invoke-WebRequest $FilePathOrUrl
            }
            else
            {
                $FileContent = Get-Content $FilePathOrUrl -Raw
            }
        }
        Catch
        {
            Write-Host $_
            throw "Can't get file content: file path or url '" + $FilePathOrUrl +"' may be invalid."
        }
    }
    End {
        
        if ($ToJsonObject)
        {
            ConvertFrom-Json $FileContent
        }
        else
        {
            $FileContent
        }
    }
}

Function Get-VcpkgJsonInfo
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$JsonPathOrUrl
    )
    Begin {
        $Name = [string]@{}
        $Version = [string]@{}
        $VersionType = [string]@{}
        $PortVersion = [string]@{}
        $Homepage = [string]@{}
    }
    Process {
        
        $JsonObject = Get-FileContent $JsonPathOrUrl -ToJsonObject
        
        if ([bool]($JsonObject.PSobject.Properties.name -match "^name$"))
        {
            $Name = $JsonObject.name
        }
        else
        {
            throw "Missing 'name' field in vcpkg.json."
        }

        if ([bool]($JsonObject.PSobject.Properties.name -match "^version$"))
        {
            $Version = $JsonObject.version
            $VersionType = "version"
        }
        elseif ([bool]($JsonObject.PSobject.Properties.name -match "^version-date$"))
        {
            $Version = $JsonObject.'version-date'
            $VersionType = "version-date"
        }
        elseif ([bool]($JsonObject.PSobject.Properties.name -match "^version-string$"))
        {
            $Version = $JsonObject.'version-string'
            $VersionType = "version-string"
        }
        elseif ([bool]($JsonObject.PSobject.Properties.name -match "^version-semver$"))
        {
            $Version = $JsonObject.'version-semver'
            $VersionType = "version-semver"
        }
        else
        {
            throw "Missing 'version', 'version-date', 'version-string', 'version-semver' fields in vcpkg.json."
        }

        if ([bool]($JsonObject.PSobject.Properties.name -match "^port-version$"))
        {
            $PortVersion = $JsonObject.'port-version'
        }
        else
        {
            $PortVersion = '0'
        }
        
        if ([bool]($JsonObject.PSobject.Properties.name -match "^homepage$"))
        {
            $Homepage = $JsonObject.homepage
        }
        else
        {
            $Homepage = ''
        }
    }
    End {

        @{
            name=$Name
            version=$Version
            versiontype=$VersionType
            portversion=$PortVersion
            homepage=$Homepage
        }
    }
}

# Get the latest release tag and assets list (name, download_url, size and digest)
Function Get-GithubLatestReleaseInfo
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$remoteLatestReleaseUrl
    )
    Begin {
        $Version = [string]@{}
		$Assets = @()
    }
    Process {

        $remoteLatestRelease = Get-FileContent $remoteLatestReleaseUrl -ToJsonObject
        if ([bool]($remoteLatestRelease.PSobject.Properties.name -match "^tag_name$"))
        {
            $Version = $remoteLatestRelease.tag_name
			
			if ([bool]($remoteLatestRelease.PSobject.Properties.name -match "^assets$"))
			{
				foreach ($asset in $remoteLatestRelease.assets)
				{
					#Write-Host "$($asset.name) $($asset.browser_download_url) $($asset.size) $($asset.digest)"
					
					$Assets += @{
						name=$asset.name
						download_url=$asset.browser_download_url
						size=$asset.size
						digest=$asset.digest
					}
				}
			}
        }
        else
        {
            throw "Missing 'tag_name' field in repo tag list."
        }
    }
    End {

        @{
			version=$Version
			assets=$Assets
		}
    }
}

Function Get-GithubLatestReleaseVersion
{
    [CmdletBinding()]
    [OutputType([string])]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$remoteLatestReleaseUrl
    )
    Begin {
        $ReleaseInfo = @{}
    }
    Process {
        $ReleaseInfo = Get-GithubLatestReleaseInfo $remoteLatestReleaseUrl
    }
    End {
        $ReleaseInfo.version
    }
}

Function Get-GithubLatestCommitShaAndDate
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$remoteLatestCommitUrl
    )
    Begin {
        $sha = [string]@{}
        $date = [string]@{}
    }
    Process {

        $remoteLatestCommit = Get-FileContent $remoteLatestCommitUrl -ToJsonObject
        
        if ([bool]($remoteLatestCommit.PSobject.Properties.name -match "^sha$"))
        {
            $sha = $remoteLatestCommit.sha
        }
        else
        {
            throw "Missing 'sha' field in repo latest commit info."
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
                throw "Missing both 'committer' and 'author' fields in repo latest commit info."
            }
            
            if ($date -eq "")
            {
                throw "Missing 'date' field in both 'committer' and 'author' fields in repo latest commit info."
            }
            else
            {
                $date = (Get-Date $date).ToString("yyyy-MM-dd")
            }
        }
        else
        {
            throw "Missing 'commit' field in repo latest commit info."
        }
    }
    End {

        @{
            sha=$sha
            date=$date
        }
    }
}

Function Get-GithubPortFileInfo
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    Param (
        [Parameter(Mandatory=$True)]
        [string]$portFileName,
        
        [Parameter(Mandatory=$True)]
        [string]$expectedPortVersion
    )
    Begin {
        $repo = [string]@{}
        $ref = [string]@{}
		$raw_ref = [string]@{}
        $branch = [string]@{}
    }
    Process {

        # These patterns may not work if '(' or ')' are present in comments or other lines where vcpkg_from_github(...) content is extracted from.
        $pattern_github = "vcpkg_from_github[\s]*\([^\)]*\)"
        $pattern_repo = "repo[\s]*(?<repo>[\S]*)"
        $pattern_ref = "ref[\s]*(?<ref>[\S]*)"
        $pattern_branch = "head_ref[\s]*(?<branch>[\S]*)"
        
        $portFile = Get-FileContent $portFileName
        
        $matches_github = Select-String -Pattern $pattern_github -InputObject $portFile
        
        $matches_repo = Select-String -Pattern $pattern_repo -InputObject $matches_github.Matches.Value -CaseSensitive:$false
        $matches_ref = Select-String -Pattern $pattern_ref -InputObject $matches_github.Matches.Value -CaseSensitive:$false
        $matches_branch = Select-String -Pattern $pattern_branch -InputObject $matches_github.Matches.Value -CaseSensitive:$false
        
        # Can't use named groups, but current captures are always at index 1.
        $repo = $matches_repo.Matches.Groups[1].Value
        $raw_ref = $matches_ref.Matches.Groups[1].Value
        $branch = $matches_branch.Matches.Groups[1].Value

        # Fix port refs containing ${version} field.
        $ref = $raw_ref -replace "(?i)\$\{version\}", $expectedPortVersion
    }
    End {
        @{
            repo=$repo
            ref=$ref
			raw_ref=$raw_ref
            branch=$branch
        }
    }
}
