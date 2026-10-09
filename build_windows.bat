@echo off
setlocal EnableExtensions EnableDelayedExpansion

title The Choicer Voicer - Old 3DS Windows Build

echo.
echo ================================================================
echo   The Choicer Voicer - Old 3DS build (Windows)
echo ================================================================
echo.

rem -----------------------------------------------------------------
rem Find the official devkitPro installation.
rem -----------------------------------------------------------------
if not defined DEVKITPRO (
    if exist "C:\devkitPro" set "DEVKITPRO=C:\devkitPro"
)

if not defined DEVKITPRO (
    echo [ERROR] DEVKITPRO was not found.
    echo.
    echo Install the official devkitPro Windows environment first,
    echo including the 3DS development tools (3ds-dev), then run this file again.
    echo.
    echo Expected default install:
    echo   C:\devkitPro\
    echo.
    pause
    exit /b 1
)

if not defined DEVKITARM set "DEVKITARM=%DEVKITPRO%\devkitARM"

if not exist "%DEVKITARM%\3ds_rules" (
    echo [ERROR] devkitARM / 3DS build rules were not found:
    echo   "%DEVKITARM%"
    echo.
    echo Make sure the 3DS development tools are installed with devkitPro.
    pause
    exit /b 1
)

rem The official devkitPro Windows installer includes MSYS2 under devkitPro.
set "BASH=%DEVKITPRO%\msys2\usr\bin\bash.exe"
if not exist "%BASH%" (
    where bash.exe >nul 2>nul
    if not errorlevel 1 set "BASH=bash.exe"
)

if not exist "%BASH%" if /i not "%BASH%"=="bash.exe" (
    echo [ERROR] MSYS2 bash was not found.
    echo Expected:
    echo   "%DEVKITPRO%\msys2\usr\bin\bash.exe"
    echo.
    echo Reinstall or repair the official devkitPro Windows installation.
    pause
    exit /b 1
)

rem -----------------------------------------------------------------
rem Normalize paths for the MSYS2 shell.
rem -----------------------------------------------------------------
set "DP=%DEVKITPRO%"
set "DP=%DP:\=/%"
set "DA=%DEVKITARM%"
set "DA=%DA:\=/%"
set "PORT=%~dp03ds_port"
set "PORT=%PORT:\=/%"

if "%PORT:~-1%"=="/" set "PORT=%PORT:~0,-1%"

if not exist "%~dp03ds_port\Makefile" (
    echo [ERROR] The 3DS port Makefile was not found:
    echo   "%~dp03ds_port\Makefile"
    pause
    exit /b 1
)

pushd "%~dp03ds_port"

echo [INFO] DEVKITPRO = %DEVKITPRO%
echo [INFO] DEVKITARM = %DEVKITARM%
echo [INFO] Project   = %CD%

echo.
echo [INFO] Building with the devkitPro MSYS2 environment...
echo.

"%BASH%" -lc "export DEVKITPRO='%DP%'; export DEVKITARM='%DA%'; cd '%PORT%'; make -j2"
set "BUILD_RESULT=%ERRORLEVEL%"

if not "%BUILD_RESULT%"=="0" (
    echo.
    echo ================================================================
    echo BUILD FAILED  (exit code %BUILD_RESULT%)
    echo ================================================================
    echo.
    echo Read the error above. Most failures are caused by a missing
    echo 3DS development package or a source/compiler error.
    echo.
    popd
    pause
    exit /b %BUILD_RESULT%
)

echo.
echo ================================================================
echo BUILD SUCCESSFUL

echo ================================================================
echo.
echo Output:
echo   %CD%\TheChoicerVoicer3DS.3dsx
if exist "%CD%\TheChoicerVoicer3DS.smdh" echo   %CD%\TheChoicerVoicer3DS.smdh
echo.

echo You can copy the .3dsx to:
echo   SD:\3ds\TheChoicerVoicer3DS\
echo.
popd
pause
exit /b 0
