@echo off

rem Usage: check-for-update.bat [optional_vcpkg_dir]
rem	 If "optional_vcpkg_dir" is not specified, the check is done against the vcpkg and github online repositories.

setlocal

pushd %~dp0

set optional_vcpkg_dir=%1

echo.
echo Check ports against vcpkg repository
echo.

call :check_vcpkg cairo %optional_vcpkg_dir%
call :check_vcpkg cpprestsdk %optional_vcpkg_dir%
call :check_vcpkg icu %optional_vcpkg_dir%
call :check_vcpkg intel-mkl %optional_vcpkg_dir%
call :check_vcpkg libpsl %optional_vcpkg_dir%
call :check_vcpkg lua %optional_vcpkg_dir%
call :check_vcpkg sentencepiece %optional_vcpkg_dir%

echo.
echo Check ports against github repository
echo.

call :check_github_repo ctranslate2 -UseReleaseTag
call :check_github_repo ruy
call :check_github_repo tokenizer -UseReleaseTag

echo.
echo Check ports against their latest github repository tags
echo.

rem Use 'tag-${version}' with single quotes to pass powershell parameters containing '$'.
rem Add overrideRepo parameter string (such as 'repoowner/reponame') if vcpkg.json 'homepage' field doesn't reference it as https://github.com/repoowner/reponame.
rem call :check_github_tag vcpkg-tool-clang 'llvmorg-${version}' 'llvm/llvm-project'
call :check_github_tag vcpkg-tool-clang 'llvmorg-${version}'

popd

goto :eof

:check_vcpkg
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0ps-check-for-vcpkg-update.ps1' %*}"
exit /b 0

:check_github_repo
if "%optional_vcpkg_dir%" neq "" (
echo Ignoring '%1' port check since it can't be run locally.
) else (
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0ps-check-for-github-repo-update.ps1' %*}"
)
exit /b 0

:check_github_tag
if "%optional_vcpkg_dir%" neq "" (
echo Ignoring '%1' port check since it can't be run locally.
) else (
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0ps-check-for-github-tag-update.ps1' %*}"
)
exit /b 0
