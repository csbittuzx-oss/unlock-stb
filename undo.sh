#!/bin/bash
# ============================================================================
# Jio STB Restoration Script (undo.sh)
# Model: Skyworth JMSB200A (Android 11 - 25.1.9)
# Restores all disabled and uninstalled packages, settings, and stock launcher.
# ============================================================================

set -e

echo "[*] Checking ADB connection..."
adb connect 192.168.50.2:5555 2>/dev/null || true
if [ -n "$1" ]; then adb connect "$1:5555" 2>/dev/null || true; fi
adb wait-for-device

echo "[*] Re-installing uninstalled apps for user 0..."
UNINSTALLED=(
    "com.netflix.ninja"
    "com.jio.store"
    "com.jio.stb.catv"
)
for pkg in "${UNINSTALLED[@]}"; do
    echo "  -> Reinstalling: $pkg"
    adb shell cmd package install-existing "$pkg" 2>/dev/null || true
done

echo "[*] Re-enabling all Jio system, update, and telemetry packages..."

PACKAGES=(
    "com.jio.httpupdate"
    "com.jio.usbupdate"
    "com.jio.tr069client"
    "com.rjil.jio.stb.commandreceiver"
    "com.jio.backgroundscheduler"
    "com.jio.stbadservice"
    "com.teamviewer.quicksupport.addon.jio_stb"
    "com.rjil.podlogservice"
    "com.jio.systemstats"
    "com.jio.stb.remotediagnose"
    "com.jio.smartmemorymanager"
    "com.jio.appoptimizer"
    "com.jio.bioscopecontentservice"
    "com.jio.product.exploremyremote"
    "com.jio.stb.bot"
    "com.jio.stbwidget"
    "com.jio.store"
    "com.jio.web"
    "com.media.jio.sso.stb"
    "com.jio.profileutility"
    "com.netflix.partnertoken"
    "com.jio.dialserver"
    "com.omni.simplesetup"
    "com.jio.universalsetup"
)

for pkg in "${PACKAGES[@]}"; do
    echo "  -> Re-enabling: $pkg"
    adb shell pm enable --user 0 "$pkg" 2>/dev/null || true
    adb shell pm enable "$pkg" 2>/dev/null || true
    adb shell pm unsuspend --user 0 "$pkg" 2>/dev/null || true
    adb shell cmd package unhide "$pkg" 2>/dev/null || true
    adb shell cmd appops set "$pkg" RUN_IN_BACKGROUND allow 2>/dev/null || true
    adb shell cmd appops set "$pkg" RUN_ANY_IN_BACKGROUND allow 2>/dev/null || true
done

echo "[*] Restoring system animations to 1.0x..."
adb shell settings put global window_animation_scale 1.0
adb shell settings put global transition_animation_scale 1.0
adb shell settings put global animator_duration_scale 1.0

echo "[*] Restoring screen off timeout (default: 30 minutes / 1800000 ms)..."
adb shell settings put system screen_off_timeout 1800000

echo "[*] Restoring stock Jio Launcher as default Home..."
adb shell pm enable --user 0 com.iwedia.ui.rjio.launcher.reliance 2>/dev/null || true
adb shell pm unsuspend --user 0 com.iwedia.ui.rjio.launcher.reliance 2>/dev/null || true
adb shell cmd package set-home-activity com.iwedia.ui.rjio.launcher.reliance/.MainActivity 2>/dev/null || true

echo "[*] Sending HOME keyevent..."
adb shell input keyevent KEYCODE_HOME 2>/dev/null || true

echo ""
echo "[+] Undo complete! All original apps, settings, and stock launcher restored."
