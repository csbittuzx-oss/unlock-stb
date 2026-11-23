@echo off
cd /d "%~dp0"
set ADB=adb
if exist "%~dp0bin\adb.exe" set ADB="%~dp0bin\adb.exe"

echo ==========================================================
echo Jio STB Complete Restoration ^& Undo Tool
echo ==========================================================
echo This will restore all stock apps, re-enable Jio launcher,
echo restore OTA update services, and reset animations to stock.
echo.
set /p CONFIRM="Are you sure you want to restore? [y/N]: "
if /i not "%CONFIRM%"=="y" (
    echo Restoration cancelled.
    pause
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0undo.ps1"
pause
