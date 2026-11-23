# Sideload Packages & Launchers

This directory contains verified, tested, and optimized application packages for the Jio Set-Top Box running Android TV (Android 9 / Android 11).

---

## 1. Elyvon Launcher (`elyvon-launcher.apk`)
- **Package Name:** `com.elyvon.launcher`
- **Main Activity:** `com.elyvon.launcher/com.omeda.arc.MainActivity`
- **Recommended For:** Primary Android TV Home Launcher.
- **Features:**
  - Modern, minimalist Android TV user interface.
  - Zero advertisements, zero sponsored telemetry banners.
  - Fully supports TV D-Pad remote navigation.
  - Ultra-low RAM consumption (~45MB vs stock Jio Launcher's 350MB+).
  - Fast app drawer and customizable favorite rows.

## 2. Aurora Store v4.8.4 (`aurora-store.apk`)
- **Package Name:** `com.aurora.store`
- **Target SDK:** Android 11+ compatible (minSdk 21).
- **Recommended For:** Application Store & Package Management.
- **Why this replaces Google Play Store on Jio STB:**
  - The Jio STB lacks certified Google Mobile Services (GMS/GSF). Attempting to install the official Google Play Store (`com.android.vending`) extracted from newer TVs fails due to API 34 incompatibilities (`INSTALL_FAILED_OLDER_SDK`) and missing Google Framework services.
  - Aurora Store is an open-source, full client for the Google Play Store catalog.
  - Allows logging in with an Anonymous Google Session or personal account.
  - Provides direct one-click downloads and updates for official TV apps (YouTube, SmartTube, OTT apps, VLC, MX Player, etc.) directly from Google servers.

## 3. Shevery (`shevery-release.apk`)
- **Package Name:** `com.hamondev.shevery`
- **Recommended For:** Privileged Command Execution & Terminal Access on TV.
- **Features:**
  - Allows privileged shell commands directly on the TV interface using remote control.
  - Useful for quick maintenance or viewing active processes without reconnecting PC.

## 4. Monet Launcher (`monet-launcher.apk`)
- **Package Name:** `com.klevico.monet`
- **Main Activity:** `com.klevico.monet/com.klevico.monet.ui.main.MainActivity`
- **Recommended For:** Alternative TV Launcher.
- **Features:**
  - Material You dynamic theming on Android TV.
  - Customizable app grids and widget support.

---

### Installation via ADB
```bash
# Install Aurora Store
adb install -r -g apks/aurora-store.apk
adb shell appops set com.aurora.store REQUEST_INSTALL_PACKAGES allow

# Install Elyvon Launcher
adb install -r -g apks/elyvon-launcher.apk
adb shell pm grant com.elyvon.launcher android.permission.WRITE_SECURE_SETTINGS
adb shell cmd package set-home-activity com.elyvon.launcher/com.omeda.arc.MainActivity
```
