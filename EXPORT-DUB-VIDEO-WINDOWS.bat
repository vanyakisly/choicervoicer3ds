@echo off
setlocal
cd /d "%~dp0"
where py >nul 2>nul
if not errorlevel 1 goto USE_PY
where python >nul 2>nul
if not errorlevel 1 goto USE_PYTHON
echo Python 3 was not found. Install Python 3 from python.org, then run this file again.
pause
exit /b 1

:USE_PY
py -3 tools\export_dub_video.py --gui --packs-root "%~dp0packs_voice"
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" pause
exit /b %ERR%

:USE_PYTHON
python tools\export_dub_video.py --gui --packs-root "%~dp0packs_voice"
set "ERR=%ERRORLEVEL%"
if not "%ERR%"=="0" pause
exit /b %ERR%
