@echo off

rem Usage: log-custom-registry.bat

setlocal enabledelayedexpansion

pushd %~dp0..

rem 'git rev-parse head' (local) or 'git rev-parse origin/main' (remote)
for /f %%i in ('git rev-parse head') do set COMMIT_SHA=%%i

popd

if "%COMMIT_SHA%" equ "" goto :usage

echo.
echo vcpkg-configuration.json:
echo.
echo {
echo   "registries": [
echo     {
echo       "kind": "git",
echo       "baseline": "%COMMIT_SHA%",
echo       "repository": "https://github.com/paoldev/vcpkg-custom-overlays.git",
echo       "packages": [

set LAST_PORT=

rem log ports with comma
for /f %%i in ('dir /b /on "%~dp0..\ports"') do (
if "!LAST_PORT!" neq "" echo         "!LAST_PORT!",
set LAST_PORT=%%i
)

rem log last port without comma
if "%LAST_PORT%" neq "" echo         "%LAST_PORT%"

echo       ]
echo     }
echo   ]
echo }
echo.

goto :eof

:usage
echo.
echo Usage:
echo %~nx0
echo.
echo git MUST be installed.
echo.
