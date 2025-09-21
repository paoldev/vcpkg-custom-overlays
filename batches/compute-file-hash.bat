@echo off

echo.
echo *************** SHA256 ***************
certutil.exe -hashfile %1 SHA256
echo.
echo *************** SHA512 ***************
certutil.exe -hashfile %1 SHA512
