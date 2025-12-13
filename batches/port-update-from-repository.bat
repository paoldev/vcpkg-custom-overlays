@echo off

powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0ps-update-port-from-repository.ps1' ctranslate2 -UseReleaseTag }"
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0ps-update-port-from-repository.ps1' tokenizer -UseReleaseTag }"
powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0ps-update-port-from-repository.ps1' ruy }"

powershell.exe -NoProfile -ExecutionPolicy Bypass "& {& '%~dp0ps-update-vcpkg-tool-clang-port.ps1' }"
