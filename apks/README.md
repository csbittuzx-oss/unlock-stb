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

## 3. Shizuku (`shizuku.apk`) & Package Installer (`package-installer.apk`)
- **Package Names:** `moe.shizuku.privileged.api`, `io.github.vvb2060.packageinstaller`
- **Recommended For:** Bypassing the hardcoded carrier sideload restriction (`mSuppressAppInstall = true`).
- **Why this is essential on Jio STB:**
  - Reliance Jio / Skyworth hardcoded `mSuppressAppInstall = true` directly inside `/system/priv-app/PackageInstaller/PackageInstaller.apk`, causing standard AOSP package installation to terminate instantly (`finish()`).
  - Shizuku runs as a privileged ADB/shell daemon (`UID 2000`) and provides system-level package manager services without needing root.
  - The Shizuku Package Installer registers as the system handler for `.apk` files (`application/vnd.android.package-archive`), enabling direct, seamless on-device APK installations from USB drives, file managers (X-plore), Send Files to TV, and Aptoide TV using the TV remote.

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
