@echo off
cd /d "%~dp0"
echo ==========================================================
echo Starting Jio STB 1-Click Post-ADB Debloat ^& Setup Suite
echo ==========================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp01CLICK_POST_ADB_SETUP.ps1"
pause
