[CmdletBinding()]
Param()
Set-StrictMode -Version Latest

Import-Module '.\VcpkgFunctionsLibrary.psm1'

$portName = "vcpkg-tool-clang"
$remoteVersionPrefix = "llvmorg-"

$localCmakeFile = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg-port-config.cmake"
$localVcpkgJson = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"

$localJson = Get-VcpkgJsonInfo $localVcpkgJson
$localVersion = $localJson.version

if ($localJson.homepage.StartsWith("https://github.com/"))
{
    $portRepo = $localJson.homepage -replace "https://github.com/", ""
}
else
{
	throw "Missing or invalid 'homepage' field in vcpkg.json."
}

$remoteLatestReleaseUrl = "https://api.github.com/repos/" + $portRepo + "/releases/latest"
$releaseInfo = Get-GithubLatestReleaseInfo $remoteLatestReleaseUrl

$remoteVersion = $releaseInfo.version -replace $remoteVersionPrefix, ""
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
		$found = $false
		$expectedAssetName="LLVM-$($remoteVersion)-win64.exe"
		foreach ($asset in $releaseInfo.assets)
		{
			if ($asset.name -eq $expectedAssetName)
			{
				$found = $true
				$outputPath = Join-Path -Path $PSScriptRoot -ChildPath $expectedAssetName
				
				Write-Host "Downloading $($asset.download_url)"
				
				#Invoke-WebRequest -Uri $asset.download_url -OutFile $outputPath
				#(New-Object Net.WebClient).DownloadFile($asset.download_url, $outputPath)
				Start-BitsTransfer -Source $asset.download_url -Destination $outputPath

				$hash256 = Get-FileHash -Path $outputPath -Algorithm SHA256
				$hash512 = Get-FileHash -Path $outputPath -Algorithm SHA512

				if (("sha256:"+$hash256.Hash) -ieq $asset.digest)
				{
					$newHashLine = "set(hash $($hash512.Hash.ToLower()))"
					$cmakeContent = Get-Content -Path $localCmakeFile -Raw
					$cmakeContent = $cmakeContent -Replace 'set\(hash(.*)\)', $newHashLine
					Set-Content -Path $localCmakeFile -Value $cmakeContent -NoNewLine
					
					$newVersionLine = '"version": "' + $remoteVersion + '",'
					$vcpkgContent = Get-Content -Path $localVcpkgJson -Raw
					$vcpkgContent = $vcpkgContent -Replace '"version"(.*),', $newVersionLine
					Set-Content -Path $localVcpkgJson -Value $vcpkgContent -NoNewLine
					
					Write-Host "Port updated:`n`tversion $($remoteVersion)`n`tsha512 $($hash512.Hash.ToLower())."
				}
				else
				{
					Write-Warning "Port not updated.`nSHA256 doesn't match:`n`tgithub $($asset.digest)`n`tlocal  sha256:$($hash256.Hash)."
				}
		
				Remove-Item -LiteralPath $outputPath
				break
			}
		}
		
		if (-not $found)
		{
			Write-Warning "Port not updated: asset $($expectedAssetName) not found."
		}
	}
}
