@echo off

rem Usage: test-build-custom-ports.bat vcpkg_directory all|portname triplet [-uninstall]
rem
rem Only x64-windows and x64-uwp (and some variants of them) are supported in this batch.

setlocal

if "%1" equ "" goto :usage
if "%2" equ "" goto :usage
if "%3" equ "" goto :usage

set VcpkgRoot=%1
set PortToBuild=%2
set Triplet=%3
set Operation=install
if /i "%4" equ "-uninstall" (
set Operation=remove
)
set OverlayPorts="%~dp0..\ports"
set OverlayTriplets="%~dp0..\triplets"

set vcpkg="%1\vcpkg.exe"

rem "ms-icu" and "cpprestsdk[windows-asio]" should be tested as standalone ports; "sentencepiece" is only static (and so its dependencies).
rem "cpprestsdk", "ctranslate2", "onednn", "ruy" are not available in uwp; "cairo[core,freetype]" is the only feature supported in uwp.
rem "-uninstall" doesn't support feature list in squared brackets.
set dyn_libs=000000-my-tools cairo cpprestsdk ctranslate2 icu intel-mkl libpsl lua onednn ruy
set stat_libs=000000-my-tools cairo cpprestsdk ctranslate2 icu intel-mkl libpsl lua onednn ruy sentencepiece tokenizer
set uwp_dyn_libs=000000-my-tools cairo[core,freetype] icu intel-mkl libpsl lua 
set uwp_stat_libs=000000-my-tools cairo[core,freetype] icu intel-mkl libpsl lua sentencepiece tokenizer
set uninstall_all=000000-my-tools cairo cpprestsdk ctranslate2 icu intel-mkl libpsl lua ms-icu onednn ruy sentencepiece tokenizer

if /i "%triplet:-static=%" equ "%triplet%" (
if /i "%triplet:-uwp=%" equ "%triplet%" (
rem x64-windows, x64-windows-release
set all_libs=%dyn_libs%
) else (
rem x64-uwp
set all_libs=%uwp_dyn_libs%
)
) else (
if /i "%triplet:-uwp=%" equ "%triplet%" (
rem x64-windows-static, x64-windows-static-md, x64-windows-static-md-release, x64-windows-static-release
set all_libs=%stat_libs%
) else (
rem x64-uwp-static-md, x64-uwp-static-md-release
set all_libs=%uwp_stat_libs%
)
)

if /i "%Operation%" equ "remove" (
rem Ignore all warnings when removing libs that were not built for a specific triplet.
set all_libs=%uninstall_all%
)

if /i "%PortToBuild%" equ "all" (
call :build %all_libs%
) else (
call :build %PortToBuild%
)

goto :eof

:build
%vcpkg% %Operation% --vcpkg-root "%VcpkgRoot%" --triplet %Triplet% --overlay-ports %OverlayPorts% --overlay-triplets %OverlayTriplets% --recurse %*
exit /b 0

:usage
echo.
echo Usage:
echo %~nx0 vcpkg_directory all^|portname triplet [-uninstall]
echo.
