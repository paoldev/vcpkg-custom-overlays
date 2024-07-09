@echo off

rem Usage: check-for-update.bat [optional_vcpkg_dir]
rem	 If "optional_vcpkg_dir" is not specified, the check is done against the vcpkg online repository.

setlocal

set optional_vcpkg_dir=%1

call :check cairo %optional_vcpkg_dir%
call :check cpprestsdk %optional_vcpkg_dir%
call :check icu %optional_vcpkg_dir%
call :check intel-mkl %optional_vcpkg_dir%
call :check libpsl %optional_vcpkg_dir%
call :check lua %optional_vcpkg_dir%
call :check onednn %optional_vcpkg_dir%
call :check sentencepiece %optional_vcpkg_dir%

goto :eof

:check
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0check-for-update.ps1' %*}"
exit /b 0
