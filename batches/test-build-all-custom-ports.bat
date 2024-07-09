@echo off

rem Usage: test-build-all-custom-ports.bat vcpkg_directory [-uninstall]

setlocal

if "%1" equ "" goto :usage

call "%~dp0test-build-custom-ports.bat" %1 all x64-windows %2
call "%~dp0test-build-custom-ports.bat" %1 all x64-uwp %2
call "%~dp0test-build-custom-ports.bat" %1 all x64-windows-static-md-release %2
call "%~dp0test-build-custom-ports.bat" %1 all x64-uwp-static-md-release %2

goto :eof

:usage
echo.
echo Usage:
echo %~nx0 vcpkg_directory [-uninstall]
echo.
