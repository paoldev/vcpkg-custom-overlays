@echo off

rem Usage: check-for-update.bat [optional_vcpkg_dir]
rem	 If "optional_vcpkg_dir" is not specified, the check is done against the vcpkg online repository.

setlocal

set optional_vcpkg_dir=%1

call :check_vcpkg cairo %optional_vcpkg_dir%
call :check_vcpkg cpprestsdk %optional_vcpkg_dir%
call :check_vcpkg icu %optional_vcpkg_dir%
call :check_vcpkg intel-mkl %optional_vcpkg_dir%
call :check_vcpkg libpsl %optional_vcpkg_dir%
call :check_vcpkg lua %optional_vcpkg_dir%
call :check_vcpkg sentencepiece %optional_vcpkg_dir%

goto :eof

:check_vcpkg
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0check-for-vcpkg-update.ps1' %*}"
exit /b 0
