@echo off

set PWSHELL=powershell.exe
where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (set PWSHELL=pwsh.exe)
echo Using %PWSHELL%

%PWSHELL% -NoProfile -ExecutionPolicy Bypass -Command "& {& '%~dp0ps-update-port-from-repository.ps1' ctranslate2 -UseReleaseTag }"
%PWSHELL% -NoProfile -ExecutionPolicy Bypass -Command "& {& '%~dp0ps-update-port-from-repository.ps1' tokenizer -UseReleaseTag }"
%PWSHELL% -NoProfile -ExecutionPolicy Bypass -Command "& {& '%~dp0ps-update-port-from-repository.ps1' ruy }"

%PWSHELL% -NoProfile -ExecutionPolicy Bypass -Command "& {& '%~dp0ps-update-vcpkg-tool-clang-port.ps1' }"

%PWSHELL% -NoProfile -ExecutionPolicy Bypass -Command "& {& '%~dp0ps-update-cuda-ci-version-from-repository.ps1' }"
