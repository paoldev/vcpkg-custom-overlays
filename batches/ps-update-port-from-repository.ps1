[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True, Position=0)]
    [string]$portName,
	   
    [switch]$UseReleaseTag
)
Set-StrictMode -Version Latest

Import-Module '.\VcpkgFunctionsLibrary.psm1'

$localCmakeFile = $PSScriptRoot + "/../ports/" + $portName + "/portfile.cmake"
$localVcpkgJson = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"

$localJson = Get-VcpkgJsonInfo $localVcpkgJson
$portFile = Get-GithubPortFileInfo $localCmakeFile $localJson.version

$localVersion = $portFile.ref

if ($localJson.homepage.StartsWith("https://github.com/"))
{
    $portRepo = $localJson.homepage -replace "https://github.com/", ""
}
else
{
	throw "Missing or invalid 'homepage' field in vcpkg.json."
}

$remoteLatestReleaseUrl = "https://api.github.com/repos/" + $portFile.repo + "/releases/latest"
$remoteLatestCommitUrl = "https://api.github.com/repos/" + $portFile.repo + "/commits/" + $portFile.branch
$remoteVersionForJson = ""
$remoteRefCommitId = ""

if ($UseReleaseTag)
{
    $releaseInfo = Get-GithubLatestReleaseInfo $remoteLatestReleaseUrl
	$remoteVersion = $releaseInfo.version
	$expectedAssetName="$($releaseInfo.version).tar.gz"
	
	$localVersionStartPos = $localVersion.IndexOf($localJson.version)
	if ($localVersionStartPos -eq -1)
	{
		throw "Unexpected version '$($localVersion)' while looking for '$($localJson.version)'"
	}
	$localVersionCountFromEnd = $localVersion.Length - $localVersionStartPos - $localJson.version.Length
	$remoteVersionForJson = $remoteVersion.Substring($localVersionStartPos, $remoteVersion.Length - $localVersionStartPos - $localVersionCountFromEnd)
}
else
{
	$commitInfo = Get-GithubLatestCommitShaAndDate $remoteLatestCommitUrl
    $remoteVersion = $commitInfo.sha + "@" + $commitInfo.date
	$localVersion = $portFile.ref + "@" + $localJson.version
	$expectedAssetName="$($commitInfo.sha).tar.gz"
	$remoteRefCommitId = $commitInfo.sha
	# TODO: this only works for "version-date" type; add other version types.
	$remoteVersionForJson = $commitInfo.date
}

# This is the url usually used by vcpkg_from_github to download source code file.
$downloadUrl = "https://github.com/$($portFile.repo)/archive/$($expectedAssetName)"

if ($localVersion -eq $remoteVersion)
{
    Write-Host "$($portName): same version $($localVersion)"
}
else
{
    Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion)"
	
	$choice = Read-Host "Update port to version $($remoteVersion)? (y/n)"
	if ($choice -ieq "y")
	{
		$outputPath = Join-Path -Path $PSScriptRoot -ChildPath $expectedAssetName
				
		Write-Host "Downloading $($downloadUrl)"
				
		Try
		{
			Start-BitsTransfer -Dynamic -Source $downloadUrl -Destination $outputPath
		}
		Catch
		{
			# Fallback, since Start-BitsTransfer seems to not work with "subst" drives.
			Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath
			#(New-Object Net.WebClient).DownloadFile($downloadUrl, $outputPath)
		}

		$hash512 = Get-FileHash -Path $outputPath -Algorithm SHA512

		$cmakeContent = Get-Content -Path $localCmakeFile -Raw
		$newHashLine = "SHA512 $($hash512.Hash.ToLower())"
		$cmakeContent = $cmakeContent -Replace 'SHA512(.*)', $newHashLine
		if (-not $UseReleaseTag)
		{
			$newRefLine = " REF $($remoteRefCommitId.ToLower())"
			$cmakeContent = $cmakeContent -Replace ' REF(.*)', $newRefLine
		}
		Set-Content -Path $localCmakeFile -Value $cmakeContent -NoNewLine

		$oldVersionLine = '"' + $localJson.versiontype + '"(.*),'
		$newVersionLine = '"' + $localJson.versiontype + '": "' + $remoteVersionForJson + '",'
		$vcpkgContent = Get-Content -Path $localVcpkgJson -Raw
		$vcpkgContent = $vcpkgContent -Replace $oldVersionLine, $newVersionLine
		Set-Content -Path $localVcpkgJson -Value $vcpkgContent -NoNewLine
					
		Write-Host "Port updated:`n`tversion $($remoteVersionForJson)`n`tsha512 $($hash512.Hash.ToLower())."
		
		Remove-Item -LiteralPath $outputPath
	}
}
