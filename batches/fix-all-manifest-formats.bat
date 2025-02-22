@echo off

rem Usage: fix-all-manifest-formats.bat vcpkg_dir

setlocal

if "%1" equ "" goto :usage
if not exist "%1\vcpkg.exe" goto :usage

set LOCAL_ROOT=%~dp0..

rem override "vcpkg-root" in order to use "--all" argument.
"%1\vcpkg.exe" format-manifest --all --vcpkg-root %LOCAL_ROOT%

goto :eof

:usage
echo.
echo Usage:
echo %~nx0 vcpkg_dir
echo.
echo vcpkg_dir MUST contain vcpkg.exe.
echo.
