@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/k \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
call "%~dp0scripts\ensure-python.bat"
if %errorlevel% neq 0 exit /b 1

echo ==========================================================
echo Starting Jio STB Ethernet ADB Unlock Lab (Universal ACS)
echo ==========================================================
echo [*] If this tool helps you, please star our GitHub repo:
echo     https://github.com/krishnasen2401/jiostb
echo ==========================================================
echo.
echo Select your Jio STB Model Family:
echo   [1] Skyworth / JMS Series: JMSB200A, JMSC200A, JMSD200A, AirFiber (RILROOTCA) [DEFAULT]
echo   [2] JHS / Iwedia Series: JHSC200, JHSD200, JioOS 2.0 (eMudhra)
echo.
set MODEL_CHOICE=1
set /p MODEL_CHOICE="Enter choice [1 or 2, default 1]: "
set STB_MODEL=jms
if "%MODEL_CHOICE%"=="2" set STB_MODEL=jhs

if "%STB_MODEL%"=="jms" (
    echo [+] Configured for Skyworth / JMS Series - RILROOTCA certificate chain (acs_chain.pem)
) else (
    echo [+] Configured for JHS Series - eMudhra certificate chain (forged_chain.pem)
)
echo.
echo [*] Tip: If STB never contacts the lab, temporarily turn OFF Windows Firewall
echo     (or pause Quick Heal/McAfee) as Windows drops incoming port 9443/8443 packets.
echo.
echo [*] PRO-TIP: If STB loops on /generate_204 or fails TLS (CERTIFICATE_UNKNOWN),
echo     perform a FACTORY RESET on the STB (Settings -> Device Preferences -> Reset).
echo     During fresh setup, the STB forces immediate TR-069 provisioning without backoff!
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\start-adb-ethernet.ps1" -AcsScript "mock_acs_universal.py" -Model "%STB_MODEL%"
pause
