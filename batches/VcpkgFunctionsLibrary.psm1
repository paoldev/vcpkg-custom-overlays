# 
# VcpkgFunctionsLibrary
#
# Author: paoldev
#
# Few helpers to export some vcpkg.json, portfile.cmake and github repos infos.
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
		if ($FilePathOrUrl.StartsWith("http://") -or $FilePathOrUrl.StartsWith("https://"))
		{
			$FileContent = Invoke-WebRequest $FilePathOrUrl
		}
		else
		{
			$FileContent = Get-Content $FilePathOrUrl -Raw
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
            throw "Missing 'name' field."
        }

        if ([bool]($JsonObject.PSobject.Properties.name -match "^version$"))
        {
            $Version = $JsonObject.version
        }
        elseif ([bool]($JsonObject.PSobject.Properties.name -match "^version-date$"))
        {
            $Version = $JsonObject.'version-date'
        }
        elseif ([bool]($JsonObject.PSobject.Properties.name -match "^version-string$"))
        {
            $Version = $JsonObject.'version-string'
        }
        elseif ([bool]($JsonObject.PSobject.Properties.name -match "^version-semver$"))
        {
            $Version = $JsonObject.'version-semver'
        }
        else
        {
            throw "Missing 'version', 'version-date', 'version-string', 'version-semver' fields."
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
            portversion=$PortVersion
			homepage=$Homepage
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
        $Version = [string]@{}
    }
    Process {

        $remoteLatestRelease = Get-FileContent $remoteLatestReleaseUrl -ToJsonObject
        if ([bool]($remoteLatestRelease.PSobject.Properties.name -match "^tag_name$"))
        {
            $Version = $remoteLatestRelease.tag_name
        }
        else
        {
            throw "Missing 'tag_name' field."
        }
    }
    End {

        $Version
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
            throw "Missing 'sha' field."
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
                throw "Missing both 'committer' and 'author' fields."
            }
            
            if ($date -eq "")
            {
                throw "Missing 'date' field in both 'committer' and 'author' fields."
            }
            else
            {
                $date = (Get-Date $date).ToString("yyyy-MM-dd")
            }
        }
        else
        {
            throw "Missing 'commit' field."
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
        $ref = $matches_ref.Matches.Groups[1].Value
        $branch = $matches_branch.Matches.Groups[1].Value

        # Fix port refs containing ${version} field.
        $ref = $ref -replace "(?i)\$\{version\}", $expectedPortVersion
    }
    End {
        @{
            repo=$repo
            ref=$ref
            branch=$branch
        }
    }
}
