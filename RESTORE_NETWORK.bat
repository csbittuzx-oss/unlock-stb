@echo off
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges to restore network settings...
    powershell -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

echo ==========================================================
echo Restoring PC Network and Adapter Settings to Default
echo ==========================================================

echo [*] Stopping lingering Python lab processes...
powershell -NoProfile -Command "Get-CimInstance Win32_Process | Where-Object { $_.Name -like '*python*' -and ($_.CommandLine -like '*captive_lab*' -or $_.CommandLine -like '*mock_acs*') } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

echo [*] Removing static lab IP addresses from Ethernet adapter...
netsh interface ip delete address name="Ethernet" addr=192.168.50.1 >nul 2>&1
netsh interface ip delete address name="Ethernet" addr=8.8.8.8 >nul 2>&1
netsh interface ip delete address name="Ethernet" addr=49.44.112.10 >nul 2>&1
netsh interface ip delete address name="Ethernet" addr=142.250.190.46 >nul 2>&1

echo [*] Setting Ethernet adapter to Automatic DHCP...
netsh interface ip set address name="Ethernet" source=dhcp >nul 2>&1
netsh interface ip set dns name="Ethernet" source=dhcp >nul 2>&1

echo [*] Removing temporary lab firewall rules...
powershell -NoProfile -Command "Get-NetFirewallRule -DisplayName 'LocalLab*' -ErrorAction SilentlyContinue | Remove-NetFirewallRule"

echo [*] Re-enabling Windows Defender Firewall...
netsh advfirewall set allprofiles state on >nul 2>&1

echo [*] Restarting Windows Time Service (w32time)...
net start w32time >nul 2>&1

echo [*] Renewing DHCP lease for Ethernet...
ipconfig /renew Ethernet >nul 2>&1

echo.
echo ==========================================================
echo [+] NETWORK SETTINGS RESTORED SUCCESSFULLY!
echo ==========================================================
echo PC Ethernet is now set to automatic DHCP.
timeout /t 5
