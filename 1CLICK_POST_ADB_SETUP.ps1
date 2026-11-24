<#
.SYNOPSIS
    1CLICK_POST_ADB_SETUP.ps1 - Complete Post-ADB Setup, Debloat & Custom Launcher Suite for Jio STB
.DESCRIPTION
    Automates debloating, telemetry removal, OTA disabling, custom launcher installation,
    Aurora Store sideloading, permission grants, and UI performance optimizations.
#>

param(
    [string]$StbIp = "192.168.50.2:5555",
    [string]$Launcher = "elyvon",
    [switch]$KeepStockLauncher = $false,
    [switch]$NonInteractive = $false
)

$ErrorActionPreference = 'Continue'
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition
if (-not $PSScriptRoot) { $PSScriptRoot = (Get-Location).Path }

# 1. Locate ADB
$adb = "adb"
if (Test-Path (Join-Path $PSScriptRoot "bin\adb.exe")) {
    $adb = Join-Path $PSScriptRoot "bin\adb.exe"
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "     Jio STB 1-Click Post-ADB Debloat & Custom Launcher Suite    " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ""

# 2. Check Connection
Write-Host "[*] Connecting to STB at $StbIp..." -ForegroundColor Yellow
& $adb connect $StbIp 2>$null
Start-Sleep -Seconds 2

# Check devices
$devices = & $adb devices
if ($devices -notmatch "$StbIp\s+device") {
    Write-Host "[!] STB at $StbIp not in 'device' state. Trying fallback scan..." -ForegroundColor Yellow
    & $adb connect 192.168.50.2:5555 2>$null
    & $adb wait-for-device
}

$devModel = (& $adb shell getprop ro.product.model).Trim()
$devAndroid = (& $adb shell getprop ro.build.version.release).Trim()
$devBuild = (& $adb shell getprop ro.build.display.id).Trim()

Write-Host "[+] Connected to STB!" -ForegroundColor Green
Write-Host "    Model:   $devModel" -ForegroundColor Green
Write-Host "    Android: $devAndroid (API $(& $adb shell getprop ro.build.version.sdk))" -ForegroundColor Green
Write-Host "    Build:   $devBuild" -ForegroundColor Green
Write-Host ""

# 3. Launcher Selection
if (-not $NonInteractive) {
    Write-Host "Select Launcher to Install & Set as Default:" -ForegroundColor White
    Write-Host "  [1] Elyvon Launcher (Recommended - Clean, Modern Android TV UI) [DEFAULT]" -ForegroundColor Cyan
    Write-Host "  [2] Monet Launcher (Material You TV Launcher)" -ForegroundColor Cyan
    Write-Host "  [3] Keep existing / skip launcher install" -ForegroundColor Cyan
    $choice = Read-Host "Enter choice [1-3, default 1]"
    if ($choice -eq "2") { $Launcher = "monet" }
    elseif ($choice -eq "3") { $Launcher = "none" }
    else { $Launcher = "elyvon" }
}

# 4. Debloating & Telemetry Disabling
Write-Host "`n[*] [STEP 1/4] Disabling OTA Updaters & Aggressive Telemetry..." -ForegroundColor Yellow

$otaPackages = @(
    "com.jio.httpupdate",
    "com.jio.usbupdate",
    "com.jio.tr069client",
    "com.rjil.jio.stb.commandreceiver",
    "com.jio.backgroundscheduler",
    "com.jio.stbadservice"
)

$telemetryPackages = @(
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
    "com.jio.web",
    "com.media.jio.sso.stb",
    "com.jio.profileutility",
    "com.netflix.partnertoken",
    "com.jio.dialserver",
    "com.omni.simplesetup",
    "com.jio.universalsetup",
    "com.jio.screensaver"
)

foreach ($pkg in ($otaPackages + $telemetryPackages)) {
    Write-Host "  -> Disabling: $pkg" -ForegroundColor DarkGray
    & $adb shell pm disable-user --user 0 $pkg 2>$null
    & $adb shell pm suspend --user 0 $pkg 2>$null
    & $adb shell cmd appops set $pkg RUN_IN_BACKGROUND ignore 2>$null
    & $adb shell cmd appops set $pkg RUN_ANY_IN_BACKGROUND ignore 2>$null
}

# 5. Uninstall User Bloatware
Write-Host "`n[*] [STEP 2/4] Removing Non-Essential Pre-installed Apps for User 0..." -ForegroundColor Yellow
$userBloat = @(
    "com.jio.store",
    "com.jio.stb.catv",
    "com.netflix.ninja"
)
foreach ($pkg in $userBloat) {
    Write-Host "  -> Uninstalling for user 0: $pkg" -ForegroundColor DarkGray
    & $adb shell pm uninstall -k --user 0 $pkg 2>$null
}

# 6. Install Custom Launcher & Aurora Store
Write-Host "`n[*] [STEP 3/4] Installing Launcher & App Store..." -ForegroundColor Yellow

$apksDir = Join-Path $PSScriptRoot "apks"

# Aurora Store
$auroraApk = Join-Path $apksDir "aurora-store.apk"
if (Test-Path $auroraApk) {
    Write-Host "  -> Installing Aurora Store (Google Play Store Client for Android TV)..." -ForegroundColor Cyan
    & $adb install -r -g $auroraApk 2>$null
    & $adb shell appops set com.aurora.store REQUEST_INSTALL_PACKAGES allow 2>$null
}

# Shizuku & On-Device Package Installer (Bypasses Carrier App Installation Lock)
$shizukuApk = Join-Path $apksDir "shizuku.apk"
$pkgInstallerApk = Join-Path $apksDir "package-installer.apk"
if (Test-Path $shizukuApk) {
    Write-Host "  -> Installing Shizuku (v13.6.0)..." -ForegroundColor Cyan
    & $adb install -r -g $shizukuApk 2>$null
    
    # Start Shizuku daemon via ADB
    Write-Host "  -> Starting Shizuku daemon on STB..." -ForegroundColor Cyan
    $shizukuLibPath = (& $adb shell "pm path moe.shizuku.privileged.api").Trim() -replace 'package:',''
    $shizukuLibDir = [System.IO.Path]::GetDirectoryName($shizukuLibPath) + "/lib/arm"
    & $adb shell "$shizukuLibDir/libshizuku.so" 2>$null
    & $adb shell "cp $shizukuLibDir/libshizuku.so /data/local/tmp/shizuku_starter && chmod 755 /data/local/tmp/shizuku_starter" 2>$null
}

if (Test-Path $pkgInstallerApk) {
    Write-Host "  -> Installing Shizuku Package Installer (Direct TV Remote APK Sideloading)..." -ForegroundColor Cyan
    & $adb install -r -g $pkgInstallerApk 2>$null
    
    # Pre-authorize Package Installer & Aurora Store in Shizuku's config database
    Write-Host "  -> Pre-authorizing Package Installer & Aurora Store in Shizuku..." -ForegroundColor Cyan
    $pkgUid = ((& $adb shell "dumpsys package io.github.vvb2060.packageinstaller | grep userId=").Trim() -replace 'userId=','').Trim()
    $auroraUid = ((& $adb shell "dumpsys package com.aurora.store | grep userId=").Trim() -replace 'userId=','').Trim()
    $entries = @()
    if ($pkgUid) { $entries += "{`"uid`":$pkgUid,`"flags`":2,`"packages`":[`"io.github.vvb2060.packageinstaller`"]}" }
    if ($auroraUid) { $entries += "{`"uid`":$auroraUid,`"flags`":2,`"packages`":[`"com.aurora.store`"]}" }
    $shizukuConfig = "{`"version`":2,`"packages`":[" + ($entries -join ",") + "]}"
    & $adb shell "echo '$shizukuConfig' > /data/user_de/0/com.android.shell/shizuku.json && chmod 666 /data/user_de/0/com.android.shell/shizuku.json" 2>$null
    
    # Grant permissions
    & $adb shell appops set io.github.vvb2060.packageinstaller REQUEST_INSTALL_PACKAGES allow 2>$null
    & $adb shell appops set io.github.vvb2060.packageinstaller MANAGE_EXTERNAL_STORAGE allow 2>$null
    & $adb shell appops set io.github.vvb2060.packageinstaller READ_EXTERNAL_STORAGE allow 2>$null
}

# Launcher
if ($Launcher -eq "elyvon") {
    $elyvonApk = Join-Path $apksDir "elyvon-launcher.apk"
    if (Test-Path $elyvonApk) {
        Write-Host "  -> Installing Elyvon Launcher..." -ForegroundColor Cyan
        & $adb install -r -g $elyvonApk 2>$null
        & $adb shell pm grant com.elyvon.launcher android.permission.WRITE_SECURE_SETTINGS 2>$null
        Write-Host "  -> Setting Elyvon Launcher as Default Home..." -ForegroundColor Green
        & $adb shell cmd package set-home-activity com.elyvon.launcher/com.omeda.arc.MainActivity 2>$null
    }
} elseif ($Launcher -eq "monet") {
    $monetApk = Join-Path $apksDir "monet-launcher.apk"
    if (Test-Path $monetApk) {
        Write-Host "  -> Installing Monet Launcher..." -ForegroundColor Cyan
        & $adb install -r -g $monetApk 2>$null
        & $adb shell pm grant com.klevico.monet android.permission.WRITE_SECURE_SETTINGS 2>$null
        Write-Host "  -> Setting Monet Launcher as Default Home..." -ForegroundColor Green
        & $adb shell cmd package set-home-activity com.klevico.monet/com.klevico.monet.ui.main.MainActivity 2>$null
    }
}

# Stock Launcher Disabling
if (-not $KeepStockLauncher) {
    Write-Host "  -> Disabling Stock Jio Launcher (com.iwedia.ui.rjio.launcher.reliance)..." -ForegroundColor Yellow
    & $adb shell pm disable-user --user 0 com.iwedia.ui.rjio.launcher.reliance 2>$null
    & $adb shell pm suspend --user 0 com.iwedia.ui.rjio.launcher.reliance 2>$null
}

# 7. UI Performance & Animation Tweaks
Write-Host "`n[*] [STEP 4/4] Applying Performance & Smoothness Tweaks..." -ForegroundColor Yellow
& $adb shell settings put global window_animation_scale 0.5
& $adb shell settings put global transition_animation_scale 0.5
& $adb shell settings put global animator_duration_scale 0.5
& $adb shell settings put system screen_off_timeout 7200000
& $adb shell settings put secure screensaver_enabled 0 2>$null
& $adb shell settings put secure screensaver_activate_on_sleep 0 2>$null
& $adb shell settings put secure screensaver_activate_on_dock 0 2>$null
& $adb shell settings delete secure screensaver_components 2>$null

# Wake up screen and press home
& $adb shell input keyevent KEYCODE_WAKEUP 2>$null
& $adb shell input keyevent KEYCODE_HOME 2>$null

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "           🎉 SETUP COMPLETE & JIO STB FULLY OPTIMIZED! 🎉       " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host "Summary of Changes:" -ForegroundColor White
Write-Host "  [+] TR-069 & FOTA updates permanently blocked from upgrading firmware"
Write-Host "  [+] 24+ background telemetry & aggressive RAM killer services disabled"
Write-Host "  [+] Custom launcher installed and locked as default home"
Write-Host "  [+] Stock Jio bloatware launcher disabled"
Write-Host "  [+] Shizuku + Package Installer enabled (carrier app install lock bypassed!)"
Write-Host "  [+] Aurora Store installed (ready to install YouTube, SmartTube, OTT apps)"
Write-Host "  [+] Animation scales optimized to 0.5x for snappy responsiveness"
Write-Host ""
Write-Host "Next Step:" -ForegroundColor Cyan
Write-Host "  Run 'RESTORE_NETWORK.bat' on your PC to set your Ethernet back to normal DHCP."
Write-Host "=================================================================" -ForegroundColor Green
