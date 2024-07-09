@echo off

rem Usage: create-patch-file.bat portname original_vcpkg_dir

setlocal

if "%1" equ "" goto :usage
if "%2" equ "" goto :usage

set portname=%1
set source_vcpkg_dir=%2
set patch_file="%~dp0..\patches\port-%portname%.patch"
set patched_port_dir="%~dp0..\ports\%portname%"
set temp_dir="%~dp0temp_dir\"

if not exist "%source_vcpkg_dir%\ports\%portname%" (
echo Missing "%source_vcpkg_dir%\ports\%portname%"
goto :usage
)

if not exist "%patched_port_dir%" (
echo Missing "%patched_port_dir%"
goto :usage
)

rem Remove any previous temp directory
if exist %temp_dir% rmdir /s /q %temp_dir%

rem Copy original port into temp directory
xcopy "%source_vcpkg_dir%\ports\%portname%" %temp_dir% /I /E

if not exist %temp_dir% goto :usage

pushd %temp_dir%

rem Setup a base repository with original port
git init .
git add .
git commit -m "temp"

rem Remove all files and directories except the ".git" folder
del /q *.*
for /d %%i in (".\*") do if /i not "%%~nxi"==".git" rmdir /s /q "%%i"

rem Copy the patched port directory
xcopy %patched_port_dir% %temp_dir% /I /E

rem Generate the patch file; use "git add ." and "--cached" to track new and deleted files.
git add .
git diff --cached --output=%patch_file%

popd

rmdir /s /q %temp_dir%

goto :eof

:usage
echo.
echo Usage:
echo %~nx0 portname original_vcpkg_dir
echo.
