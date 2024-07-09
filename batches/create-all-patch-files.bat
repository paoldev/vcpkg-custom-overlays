@echo off

rem Usage: create-all-patch-files.bat original_vcpkg_dir

setlocal

if "%1" equ "" goto :usage

set source_vcpkg_dir=%1

for /d %%i in ("%~dp0..\ports\*") do (
if exist %source_vcpkg_dir%\ports\%%~nxi (
echo.
echo ^[32m%%~nxi^[0m ...
call %~dp0create-patch-file.bat %%~nxi %source_vcpkg_dir%
)
)

goto :eof

:usage
echo.
echo Usage:
echo %~nx0 original_vcpkg_dir
echo.
