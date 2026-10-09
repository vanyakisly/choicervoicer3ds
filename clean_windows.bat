@echo off
setlocal EnableExtensions EnableDelayedExpansion

title The Choicer Voicer - Old 3DS Clean (Windows)

if not defined DEVKITPRO if exist "C:\devkitPro" set "DEVKITPRO=C:\devkitPro"
if not defined DEVKITPRO (
    echo DEVKITPRO was not found. Expected C:\devkitPro.
    pause
    exit /b 1
)
if not defined DEVKITARM set "DEVKITARM=%DEVKITPRO%\devkitARM"
set "BASH=%DEVKITPRO%\msys2\usr\bin\bash.exe"
if not exist "%BASH%" (
    echo MSYS2 bash was not found at:
    echo %BASH%
    pause
    exit /b 1
)

set "DP=%DEVKITPRO%"
set "DP=%DP:\=/%"
set "DA=%DEVKITARM%"
set "DA=%DA:\=/%"
set "PORT=%~dp03ds_port"
set "PORT=%PORT:\=/%"
if "%PORT:~-1%"=="/" set "PORT=%PORT:~0,-1%"

"%BASH%" -lc "export DEVKITPRO='%DP%'; export DEVKITARM='%DA%'; cd '%PORT%'; make clean"
if errorlevel 1 (
    echo.
    echo Clean failed.
    pause
    exit /b 1
)

echo.
echo Clean complete.
pause
exit /b 0
