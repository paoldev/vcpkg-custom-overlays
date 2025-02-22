@echo off

rem Usage: update-registry-versions.bat vcpkg_dir

setlocal

if "%1" equ "" goto :usage
if not exist "%1\vcpkg.exe" goto :usage

set LOCAL_ROOT=%~dp0..

"%1\vcpkg.exe" --x-builtin-ports-root="%LOCAL_ROOT%\ports" --x-builtin-registry-versions-dir="%LOCAL_ROOT%\versions" x-add-version --all --verbose --skip-version-format-check

goto :eof

:usage
echo.
echo Usage:
echo %~nx0 vcpkg_dir
echo.
echo vcpkg_dir MUST contain vcpkg.exe.
echo.
