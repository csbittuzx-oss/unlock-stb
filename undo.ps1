# ============================================================================
# Jio STB Restoration Script (undo.ps1)
# Model: Skyworth JMSB200A & Iwedia JHS Series (Android 9 / Android 11)
# Restores all disabled and uninstalled packages, settings, and stock launcher.
# ============================================================================

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $PSScriptRoot) { $PSScriptRoot = (Get-Location).Path }

$adb = "adb"
if (Test-Path (Join-Path $PSScriptRoot "bin\adb.exe")) {
    $adb = Join-Path $PSScriptRoot "bin\adb.exe"
}

Write-Host "[*] Checking ADB connection..." -ForegroundColor Cyan
& $adb connect 192.168.50.2:5555 2>$null
# Connect via Wi-Fi if custom IP provided
if ($args[0]) { & $adb connect "$($args[0]):5555" 2>$null }
& $adb wait-for-device

Write-Host "[*] Re-installing uninstalled apps for user 0..." -ForegroundColor Cyan
$uninstalled = @(
    "com.netflix.ninja",
    "com.jio.store",
    "com.jio.stb.catv"
)
foreach ($pkg in $uninstalled) {
    Write-Host "  -> Reinstalling: $pkg" -ForegroundColor Yellow
    & $adb shell cmd package install-existing $pkg 2>$null
}

Write-Host "[*] Re-enabling Jio system, update, telemetry, and store packages..." -ForegroundColor Cyan

$packages = @(
    "com.jio.httpupdate",
    "com.jio.usbupdate",
    "com.jio.tr069client",
    "com.rjil.jio.stb.commandreceiver",
    "com.jio.backgroundscheduler",
    "com.jio.stbadservice",
    "com.teamviewer.quicksupport.addon.jio_stb",
    "com.rjil.podlogservice",
    "com.jio.systemstats",
    "com.jio.stb.remotediagnose",
    "com.jio.smartmemorymanager",
    "com.jio.appoptimizer",
    "com.jio.bioscopecontentservice",
    "com.jio.product.exploremyremote",
    "com.jio.stb.bot",
    "com.jio.stbwidget",
    "com.jio.store",
    "com.jio.web",
    "com.media.jio.sso.stb",
    "com.jio.profileutility",
    "com.netflix.partnertoken",
    "com.jio.dialserver",
    "com.omni.simplesetup",
    "com.jio.universalsetup"
)

foreach ($pkg in $packages) {
    Write-Host "  -> Re-enabling: $pkg" -ForegroundColor Yellow
    & $adb shell pm enable --user 0 $pkg 2>$null
    & $adb shell pm enable $pkg 2>$null
    & $adb shell pm unsuspend --user 0 $pkg 2>$null
    & $adb shell cmd package unhide $pkg 2>$null
    & $adb shell cmd appops set $pkg RUN_IN_BACKGROUND allow 2>$null
    & $adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND allow 2>$null
}

Write-Host "[*] Restoring system animations to 1.0x..." -ForegroundColor Cyan
& $adb shell settings put global window_animation_scale 1.0
& $adb shell settings put global transition_animation_scale 1.0
& $adb shell settings put global animator_duration_scale 1.0

Write-Host "[*] Restoring screen off timeout (default: 30 minutes / 1800000 ms)..." -ForegroundColor Cyan
& $adb shell settings put system screen_off_timeout 1800000

Write-Host "[*] Restoring stock Jio Launcher as default Home..." -ForegroundColor Cyan
& $adb shell pm enable --user 0 com.iwedia.ui.rjio.launcher.reliance 2>$null
& $adb shell pm unsuspend --user 0 com.iwedia.ui.rjio.launcher.reliance 2>$null
& $adb shell cmd package set-home-activity com.iwedia.ui.rjio.launcher.reliance/.MainActivity 2>$null

Write-Host "[*] Sending HOME keyevent..." -ForegroundColor Cyan
& $adb shell input keyevent KEYCODE_HOME 2>$null

Write-Host "[+] Undo complete! All original apps, settings, and stock launcher restored." -ForegroundColor Green
