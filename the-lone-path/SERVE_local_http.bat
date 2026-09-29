@echo off
rem ============================================================
rem  THE LONE PATH - optional local web server (if you prefer
rem  running the game at http://localhost instead of a file).
rem  Requires Python (python.org). Otherwise just use
rem  PLAY_on_Windows.bat - it works without any server.
rem ============================================================
setlocal
cd /d "%~dp0"
where python >nul 2>nul
if %errorlevel%==0 goto pysrv
where py >nul 2>nul
if %errorlevel%==0 goto pysrv2
echo Python was not found on this system.
echo You don't need a server: just double-click
echo   PLAY_on_Windows.bat   (or open index.html in a browser)
echo.
pause
exit /b
:pysrv
echo Starting server on http://localhost:8123  (Ctrl+C to stop)
start "" http://localhost:8123
python -m http.server 8123
exit /b
:pysrv2
echo Starting server on http://localhost:8123  (Ctrl+C to stop)
start "" http://localhost:8123
py -m http.server 8123
exit /b
