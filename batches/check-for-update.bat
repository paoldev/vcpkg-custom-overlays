@echo off

rem Usage: check-for-update.bat [optional_vcpkg_dir]
rem	 If "optional_vcpkg_dir" is not specified, the check is done against the vcpkg and github online repositories.

setlocal

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

call :check_github ctranslate2 -UseReleaseTag
call :check_github ruy
call :check_github tokenizer -UseReleaseTag

goto :eof

:check_vcpkg
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0check-for-vcpkg-update.ps1' %*}"
exit /b 0

:check_github
if "%optional_vcpkg_dir%" neq "" (
echo Ignoring '%1' port check since it can't be run locally.
) else (
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0check-for-github-update.ps1' %*}"
)
exit /b 0
