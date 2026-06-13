[CmdletBinding()]
Param()
Set-StrictMode -Version Latest

Import-Module '.\VcpkgFunctionsLibrary.psm1'

Function Get-HighestVersion
{
	param ( $url )

	$html = Invoke-WebRequest -Uri $url

	$hrefs = [regex]::Matches($html.Content, 'href=[''"]redistrib_(\d+\.\d+\.\d+(\.\d+)?)\.json[''"]')

	$versions = foreach ($href in $hrefs) { [version]::Parse($href.Groups[1].Value) }

	$highestVersion = $versions | Sort-Object -Descending | Select-Object -First 1

	return $highestVersion
}

Function Get-SHA512
{
	param ( $url, $assetName )

	$downloadUrl = $url + $assetName
	$outputPath = Join-Path -Path $PSScriptRoot -ChildPath $assetName
				
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

	Remove-Item -LiteralPath $outputPath

	return $hash512;
}

$CudaUrl = "https://developer.download.nvidia.com/compute/cuda/redist/"
$CudnnUrl = "https://developer.download.nvidia.com/compute/cudnn/redist/"

$portName = "cuda-ci"
$localCmakeFile = $PSScriptRoot + "/../ports/" + $portName + "/portfile.cmake"
$localVcpkgJson = $PSScriptRoot + "/../ports/" + $portName + "/vcpkg.json"

$localJson = Get-VcpkgJsonInfo $localVcpkgJson
$localVersion = $localJson.version

($localCudaVersion, $localCudnnVersion) = $localVersion -split '-'
# Write-Output "Local version is: $localCudaVersion-$localCudnnVersion"

$highestCudaVersion = Get-HighestVersion $CudaUrl
$highestCudnnVersion = Get-HighestVersion $CudnnUrl
$remoteVersion = "$highestCudaVersion-$highestCudnnVersion"
# Write-Output "The highest version is: $remoteVersion"

if (($highestCudaVersion -gt $localCudaVersion) -or ($highestCudnnVersion -gt $localCudnnVersion))
{
	Write-Warning "$($portName): different versions: local $($localVersion) - remote $($remoteVersion)"
	
	$choice = Read-Host "Update port to version $($remoteVersion)? (y/n)"
	if ($choice -ieq "y")
	{
		# Always download both files.
		$cudaAssetName = "redistrib_$($highestCudaVersion).json";
		$cudnnAssetName = "redistrib_$($highestCudnnVersion).json";

		$cudaHash512 = Get-SHA512 $CudaUrl $cudaAssetName
		$cudnnHash512 = Get-SHA512 $CudnnUrl $cudnnAssetName

		$cudaHashLine = "set(CUDA_MANIFEST_HASH $($cudaHash512.Hash.ToLower()))"
		$cudnnHashLine = "set(CUDNN_MANIFEST_HASH $($cudnnHash512.Hash.ToLower()))"
		$cmakeContent = Get-Content -Path $localCmakeFile -Raw
		$cmakeContent = $cmakeContent -Replace 'set\(CUDA_MANIFEST_HASH(.*)\)', $cudaHashLine
		$cmakeContent = $cmakeContent -Replace 'set\(CUDNN_MANIFEST_HASH(.*)\)', $cudnnHashLine
		Set-Content -Path $localCmakeFile -Value $cmakeContent -NoNewLine

		$newVersionLine = '"version-string": "' + $remoteVersion + '",'
		$vcpkgContent = Get-Content -Path $localVcpkgJson -Raw
		$vcpkgContent = $vcpkgContent -Replace '"version-string"(.*),', $newVersionLine
		Set-Content -Path $localVcpkgJson -Value $vcpkgContent -NoNewLine

		Write-Host "Port updated:`n`tversion $($remoteVersion)`n`tcuda sha512 $($cudaHash512.Hash.ToLower())`n`tcudnn sha512 $($cudnnHash512.Hash.ToLower())."
	}
}
elseif (($highestCudaVersion -eq $localCudaVersion) -and ($highestCudnnVersion -eq $localCudnnVersion))
{
	Write-Host "$($portName): same version $($localVersion)"
}
else
{
	Write-Host "$($portName): unexpected versions: local $($localVersion) - remote $($remoteVersion)"
}
