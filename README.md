# Jio Set-Top Box (STB) Complete Unlock, Debloat & Custom Launcher Guide
### Supporting Skyworth (JMS Series) & Iwedia (JHS Series) on Android 9 & Android 11 (Amlogic SoC)

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%20TV%209%20%7C%2011-green.svg)](https://android.com)
[![Protocol](https://img.shields.io/badge/Exploit-TR--069%20CWMP%20Spoofing-orange.svg)](https://en.wikipedia.org/wiki/TR-069)
[![Docker Free](https://img.shields.io/badge/Docker-Not%20Required-brightgreen.svg)]()

A comprehensive, zero-Docker, standalone toolkit and documentation for unlocking ADB, permanently disabling bloatware & aggressive telemetry, blocking forced OTA updates, and replacing the restrictive stock launcher with a clean Android TV launcher (Elyvon / Monet) and Aurora Store on Jio Set-Top Boxes.

---

> [!WARNING]
> ### CRITICAL HARDWARE & BOOTLOADER NOTICE (PLEASE READ FIRST!)
> **1. HARDWARE E-FUSE & AVB 2.0 LOCK:**
> The Jio STB bootloader is cryptographically locked (`ro.boot.vbmeta.device_state: locked`). The boot partitions and vendor trees are cryptographically verified by Amlogic hardware e-fuses and Android Verified Boot (AVB 2.0).
> **DO NOT ATTEMPT TO FLASH CUSTOM ROMs, GOOGLE TV OS PORTs, OR CUSTOM RECOVERIES (TWRP/OrangeFox).** Doing so will trip AVB verification failure and **PERMANENTLY HARD-BRICK** your box into an unrecoverable state!
>
> **2. WIDEVINE DRM KEYS:**
> Widevine L1 cryptographic certificates are stored within the secure hardware enclave (TEE / TrustZone). Tampering with raw boot/system partitions risks permanently destroying the Widevine L1 keys, downgrading DRM to Widevine L3 (capping Netflix/Prime Video playback to 480p SD).
>
> **3. SAFE PATH (WHAT THIS TOOLKIT DOES):**
> This toolkit operates **strictly in user space and system parameter layers via ADB**. By disabling bloatware via `pm disable-user --user 0`, killing background tasks via `appops`, blocking TR-069/FOTA, and setting a modern launcher as the default home activity, you obtain **100% of the benefits of a custom Android TV OS** without modifying raw flash or risking hardware bricks.

---

## Table of Contents
1. [Supported Device Models](#supported-device-models)
2. [The Core Mechanism: How TR-069 Spoofing Works](#the-core-mechanism-how-tr-069-spoofing-works)
3. [Zero-Docker Direct Ethernet Lab Architecture](#zero-docker-direct-ethernet-lab-architecture)
4. [Step-by-Step Quick Start Guide](#step-by-step-quick-start-guide)
5. [Antigravity AI Agent Integration & Master Prompt](#antigravity-ai-agent-integration--master-prompt)
6. [Exhaustive Issue Resolution Encyclopedia](#exhaustive-issue-resolution-encyclopedia)
7. [Comprehensive Package Debloat Directory](#comprehensive-package-debloat-directory)
8. [Included Sideload Packages & Stores](#included-sideload-packages--stores)
9. [Disaster Recovery & Factory Reset (Undo Guide)](#disaster-recovery--factory-reset-undo-guide)
10. [Legal Disclaimer](#legal-disclaimer)

---

## Supported Device Models

| Device Model Family | Hardware Code | SoC / Architecture | Target OS | Certificate Chain | Verification Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Skyworth Series** | `JMSB200A` | Amlogic S9054 / ARM64 | Android 11 (Build 25.1.9) | `acs_chain.pem` (RILROOTCA) | **Tested & Verified** |
| **Skyworth Series** | `JMSC200A` | Amlogic S9054 / ARM64 | Android 11 | `acs_chain.pem` (RILROOTCA) | Verified Compatible |
| **Skyworth Series** | `JMSD200A` | Amlogic S9054 / ARM64 | Android 11 | `acs_chain.pem` (RILROOTCA) | Verified Compatible |
| **Jio AirFiber STB**| `JMSB200A` (AirFiber)| Amlogic ARM64 | Android 11 | `acs_chain.pem` (RILROOTCA) | Verified Compatible |
| **Iwedia / SEI Series**| `JHSC200` | Amlogic S905X2 | Android 9 / JioOS 2.0 | `forged_chain.pem` (eMudhra) | Verified Compatible |
| **Iwedia / SEI Series**| `JHSD200` | Amlogic S905X2 | Android 9 / JioOS 2.0 | `forged_chain.pem` (eMudhra) | Verified Compatible |

---

## The Core Mechanism: How TR-069 Spoofing Works

Jio Set-Top Boxes run a heavily customized firmware with USB Debugging (`adb`) disabled in system settings and the standard Android Developer Options menu hidden. However, telecom operators require remote diagnostic and management capabilities over subscriber equipment.

Jio achieves this using **TR-069 (CWMP - CPE WAN Management Protocol)**:
1. Every time the STB boots or detects a network connection, the system service `com.jio.tr069client` queries DNS for `acs.jio.com` (or `jioacs.ril.com`).
2. The STB initiates a TLS connection to port 9443 or 8443 of the Auto Configuration Server (ACS).
3. The STB sends an HTTP POST request containing a SOAP XML envelope with an `Inform` event code (`1 BOOT` or `2 PERIODIC`).
4. The server and STB perform HTTP Digest Authentication (`username: 000000`, `password: 000000`).
5. Once authenticated, our standalone ACS server (`mock_acs_universal.py`) sends a `SetParameterValues` RPC payload to the STB:
   ```xml
   <cwmp:SetParameterValues>
     <ParameterList soap-enc:arrayType="cwmp:ParameterValueStruct[2]">
       <ParameterValueStruct>
         <Name>Device.DeviceInfo.X_JIO_COM_USBDebugging.Enable</Name>
         <Value xsi:type="xsd:boolean">1</Value>
       </ParameterValueStruct>
       <ParameterValueStruct>
         <Name>Device.DeviceInfo.X_JIO_COM_USBDebugging.Duration</Name>
         <Value xsi:type="xsd:unsignedInt">500000000</Value>
       </ParameterValueStruct>
     </ParameterList>
   </cwmp:SetParameterValues>
   ```
6. The STB immediately executes the parameter update internally, starting `adbd` on TCP port `5555` with ADB persistence set through year 2037!

---

## Zero-Docker Direct Ethernet Lab Architecture

Traditional community methods require Docker containers, WSL2, Technitium DNS servers, or modifying your home broadband router settings. 

This repository replaces all of that with a **Zero-Dependency, Direct-Ethernet Standalone Python Lab**:

```
[ PC / Laptop running Windows ]                    [ Jio Set-Top Box ]
+------------------------------------+             +------------------+
| Ethernet NIC: 192.168.50.1         | <== RJ45 ==>| Ethernet NIC     |
|                                    |    Cable    | Auto DHCP IP:    |
| [captive_lab.py]                   |             |  192.168.50.2    |
|   - DHCP Server (UDP 67)           |             |                  |
|   - DNS Server  (UDP 53)           |             | TR-069 Client    |
|     Spoofs *.jio.com -> 192.168.50.1             |  connects to:    |
|                                    |             |  192.168.50.1    |
| [mock_acs_universal.py]            |             |                  |
|   - HTTPS ACS Server (TCP 9443)    |             |                  |
|   - Injects USBDebugging SOAP XML  |             |                  |
|                                    |             | ADB Opens:       |
| [bin\adb.exe]                      | <== ADB === |  192.168.50.2:   |
|   - Connects to 192.168.50.2:5555  |    Port     |      5555        |
+------------------------------------+    5555     +------------------+
```

### Why this is foolproof:
- **No Wi-Fi / Router interference:** The STB is isolated on a dedicated peer-to-peer subnet (`192.168.50.0/24`).
- **Automatic DNS injection:** The STB receives DNS server `192.168.50.1` directly via DHCP lease options. No need to click through Android TV static IP menus!
- **Zero software installation:** Pure Python standard library (`socket`, `ssl`, `http.server`).

---

## Step-by-Step Quick Start Guide

### Step 1: Connect Hardware
1. Connect an Ethernet cable directly from your PC/laptop's Ethernet port (or USB-to-Ethernet adapter) to the Ethernet port on the back of the Jio STB.
2. Ensure STB HDMI is connected to your TV/monitor so you can see the screen.

### Step 2: Start the Unlock Lab
1. Right-click `UNLOCK_ADB_ETHERNET.bat` and select **Run as Administrator**.
2. Select your device model family:
   - Press `1` for **Skyworth / JMS Series** (`JMSB200A`, `JMSC200A`, `JMSD200A`, AirFiber).
   - Press `2` for **Iwedia / JHS Series** (`JHSC200`, `JHSD200`, JioOS 2.0).
3. The script will configure static IP `192.168.50.1`, add temporary firewall rules, and launch `mock_acs_universal.py` and `captive_lab.py`.

### Step 3: Power-Cycle the STB
1. Unplug the power cable from the back of the Jio STB.
2. Wait 5 seconds.
3. Plug the power cable back in.
4. Watch the command window. Within 30–60 seconds of booting, the STB will send an `Inform` packet, accept `USBDebugging=1`, and the console will output:
   ```
   🎉🎉🎉 SUCCESS: JIO STB ADB IS FULLY UNLOCKED! 🎉🎉🎉
   Device: JMSB200A (STB IP: 192.168.50.2:5555)
   ```

### Step 4: Run Post-ADB Debloat & Launcher Setup
1. Double-click `1CLICK_POST_ADB_SETUP.bat`.
2. Choose your preferred launcher:
   - `[1] Elyvon Launcher` (Recommended: Clean, modern Android TV interface, zero ads).
   - `[2] Monet Launcher` (Material You Android TV interface).
3. The script will automatically:
   - Permanently disable FOTA & TR-069 background update clients.
   - Disable 24+ telemetry trackers and background RAM throttling services.
   - Install Aurora Store (Google Play Store client), Shizuku v13.6, and Shizuku Package Installer.
   - Automatically pre-authorize and configure Shizuku to bypass Jio's hardcoded on-device APK installation lock (`mSuppressAppInstall`).
   - Sideload your chosen launcher and set it as default home activity.
   - Disable stock Jio bloatware launcher (`com.iwedia.ui.rjio.launcher.reliance`).
   - Optimize window animations to `0.5x` for blazing fast responsiveness.

### Step 5: Restore Your PC Network
1. Double-click `RESTORE_NETWORK.bat` (Run as Administrator).
2. Your PC Ethernet adapter is instantly restored back to automatic DHCP. You can now reconnect your STB and PC back to your normal home Wi-Fi or router!

---

## Antigravity AI Agent Integration & Master Prompt

This repository is built for **100% autonomous, hands-off execution via Antigravity (or any advanced AI coding agent)**. You do not need to manually configure IP addresses, parse log files, or execute shell commands yourself.

### How Antigravity Executes the Pipeline Autonomously
When given the master prompt below, Antigravity will:
1. **Clone & Target Workspace:** Utilize the repository at `https://github.com/csbittuzx-oss/unlock-stb.git` and its included zero-dependency tools (`bin\adb.exe`, `mock_acs_universal.py`, `captive_lab.py`, verified APKs in `apks/`).
2. **Environment & Port Conflict Resolution:** Automatically inspect network adapters, identify the connected Ethernet interface, clear conflicting UDP/TCP ports (53, 67, 123, 8443, 9443), and adjust Windows Defender firewall rules.
3. **Background Lab Management:** Launch `captive_lab.py` and `mock_acs_universal.py` as asynchronous background tasks, monitor logs in real time, and prompt you only when it is time to physically power-cycle the STB.
4. **Reactive Handshake & ADB Connect:** Intercept the TR-069 `Inform` request, push the `USBDebugging` activation payload, verify the STB on `192.168.50.2:5555`, and establish an authenticated ADB session.
5. **Debloat & Security Hardening:** Permanently block FOTA/TR-069 update daemons, disable 24+ telemetry trackers and aggressive memory killers, and uninstall stock bloatware.
6. **Launcher & Sideload Lock Bypass:** Install your choice of Android TV launcher (Elyvon/Monet), lock it as default home, disable stock Jio launcher, install Aurora Store, and deploy **Shizuku + Shizuku Package Installer** (pre-authorizing permissions and disabling the carrier's suppressed installer) so that USB, Send Files to TV, X-plore, and Aptoide TV APK installations work out of the box.
7. **Host Network Restoration & Verification:** Restore your PC's Ethernet adapter back to automatic DHCP and confirm custom launcher operation.

---

### The Single Autonomous Master Prompt for Antigravity

Copy and paste the following prompt directly into your AI agent:

````markdown
<TASK>
You are an expert autonomous Android embedded systems engineer, network protocol analyst, and device automation agent.
Your objective is to execute the end-to-end unlock, permanent debloat, custom launcher installation, and carrier sideload lock bypass for the connected Jio Set-Top Box (Skyworth JMS series / Iwedia JHS series) using the tools, scripts, and APKs in this repository:
https://github.com/csbittuzx-oss/unlock-stb.git

OPERATIONAL PRINCIPLES:
- Execute all phases autonomously without requiring manual user intervention or manual terminal execution.
- If errors, port conflicts, or missing permissions occur, diagnose and resolve them automatically.
- The ONLY time you should pause or prompt the user is during PHASE 2 when the physical power cable of the STB needs to be unplugged and reconnected.

Execute strictly according to these operational phases:

PHASE 1: ENVIRONMENT & NETWORK AUDIT
1. Verify the current workspace contains the unlock-stb repository tools (`mock_acs_universal.py`, `captive_lab.py`, `bin\adb.exe`, `1CLICK_POST_ADB_SETUP.ps1`, `apks/`).
2. Scan active network interfaces on the host machine to identify the wired Ethernet or USB-to-Ethernet adapter physically connected to the Jio STB.
3. Verify that UDP ports 53 (DNS), 67 (DHCP), 123 (NTP) and TCP ports 8443, 9443 (HTTPS ACS) are unblocked. Automatically terminate any conflicting local services (e.g. w32time, Internet Connection Sharing, local DNS listeners) if necessary.

PHASE 2: CAPTIVE LAB SETUP & ACS LAUNCH
1. Configure the identified host Ethernet adapter with static IP `192.168.50.1`, subnet mask `255.255.255.0` (flush existing default routes on that adapter to avoid host routing issues).
2. Configure host firewall rules to allow inbound traffic on UDP 53, 67, 123 and TCP 8443, 9443.
3. Launch `captive_lab.py` as an asynchronous background task to provide captive DHCP (leasing `192.168.50.2` to the STB) and DNS spoofing (`*.jio.com` -> `192.168.50.1`).
4. Launch `mock_acs_universal.py` with appropriate certificate parameters in the background to handle the TR-069 HTTPS CWMP session.
5. Instruct the user clearly: "Please unplug the power cable from the back of your Jio STB, wait 5 seconds, and plug it back in."
6. Monitor `captive_lab.log` and `mock_acs.log` in real time. Wait for the STB to boot, issue a DHCP request, query DNS, initiate the TLS handshake, perform HTTP Digest Authentication, and receive the SetParameterValues SOAP payload enabling `USBDebugging` and disabling `FOTA`.

PHASE 3: ADB CONNECTION & DEVICE VERIFICATION
1. Confirm the STB is online at `192.168.50.2`.
2. Connect ADB: `bin\adb.exe connect 192.168.50.2:5555`.
3. Query device properties via `adb shell getprop` to record `ro.product.model`, `ro.build.version.release`, `ro.build.display.id`, and `ro.boot.vbmeta.device_state`.

PHASE 4: SYSTEM DEBLOAT & UPDATE IMMUNIZATION
1. Immunize against remote bricking & OTA updates by disabling all update daemons for user 0:
   `com.jio.httpupdate`, `com.jio.usbupdate`, `com.jio.tr069client`, `com.rjil.jio.stb.commandreceiver`, `com.jio.backgroundscheduler`, `com.jio.stbadservice`
2. Disable aggressive background task killers, telemetry loggers, and diagnostic spies:
   `com.teamviewer.quicksupport.addon.jio_stb`, `com.rjil.podlogservice`, `com.jio.systemstats`, `com.jio.stb.remotediagnose`, `com.jio.smartmemorymanager`, `com.jio.appoptimizer`, `com.jio.bioscopecontentservice`, `com.jio.product.exploremyremote`, `com.jio.stb.bot`, `com.jio.stbwidget`, `com.jio.web`, `com.media.jio.sso.stb`, `com.jio.profileutility`, `com.netflix.partnertoken`, `com.jio.dialserver`, `com.omni.simplesetup`, `com.jio.universalsetup`
3. Restrict background AppOps execution for all disabled packages (`RUN_IN_BACKGROUND ignore`, `RUN_ANY_IN_BACKGROUND ignore`).
4. Remove pre-installed non-essential user bloatware:
   `com.jio.store`, `com.jio.stb.catv`, `com.netflix.ninja` via `pm uninstall -k --user 0`.

PHASE 5: LAUNCHER REPLACEMENT & CARRIER SIDELOAD-BYPASS SETUP
1. Install modern Android TV Launcher:
   - Sideload `apks/elyvon-launcher.apk` (or `apks/monet-launcher.apk`).
   - Grant `WRITE_SECURE_SETTINGS` to the launcher.
   - Lock it as the default system home activity: `cmd package set-home-activity <launcher_component>`.
   - Suspend and disable stock Jio launcher (`com.iwedia.ui.rjio.launcher.reliance`).
2. Sideload Aurora Store (`apks/aurora-store.apk`) and grant `REQUEST_INSTALL_PACKAGES` permission via AppOps.
3. Bypass Carrier Package Installer Lock (`mSuppressAppInstall = true`):
   - Sideload Shizuku (`apks/shizuku.apk`) and start its daemon using `libshizuku.so` / `/data/local/tmp/shizuku_starter`.
   - Sideload Shizuku Package Installer (`apks/package-installer.apk`).
   - Pre-authorize Package Installer in Shizuku's config database (`/data/user_de/0/com.android.shell/shizuku.json` with `flags: 2`).
   - Grant `REQUEST_INSTALL_PACKAGES`, `MANAGE_EXTERNAL_STORAGE`, and `READ_EXTERNAL_STORAGE` AppOps to Package Installer.
   - Disable stock suppressed installer: `pm disable-user --user 0 com.android.packageinstaller`.
   - Verify that `io.github.vvb2060.packageinstaller` is the primary handler for `.apk` installation intents so USB drives, X-plore, Send Files to TV, and Aptoide TV install directly with the TV remote.
4. Optimize UI fluidity: Set `window_animation_scale`, `transition_animation_scale`, and `animator_duration_scale` to `0.5`.

PHASE 6: NETWORK RESTORATION & FINAL VALIDATION
1. Terminate background Python lab servers (`captive_lab.py`, `mock_acs_universal.py`).
2. Restore host PC Ethernet adapter back to automatic DHCP and remove temporary firewall rules (via `RESTORE_NETWORK.bat`).
3. Send `KEYCODE_HOME` to the STB and verify that the custom launcher is active and focused.
4. Deliver a concise final report summarizing device properties, disabled services, and verified capabilities (including USB/Aptoide sideloading status).
</TASK>
````

---

## Exhaustive Issue Resolution Encyclopedia

Every single issue documented below was observed and resolved during real-world testing on the **Skyworth JMSB200A (Android 11, Build 25.1.9)**:

### 1. Issue: Docker / WSL Not Installed or GenieACS Container Fails
- **Symptom:** Running GenieACS or older repo scripts fails with `docker : The term 'docker' is not recognized` or WSL2 virtual network bridge drops incoming TR-069 packets.
- **Root Cause:** GenieACS requires Node.js, MongoDB, and Docker. Network bridging between Docker containers and physical Ethernet interfaces often fails to relay broadcast DHCP or port 9443 TLS.
- **Permanent Fix:** Use `mock_acs_universal.py` and `captive_lab.py`. These run on native Windows Python without external dependencies, eliminating Docker completely.

---

### 2. Issue: TV GUI Has No DNS Option / Mistaking Router IP for STB
- **Symptom:** User cannot find a DNS entry field under TV Wi-Fi settings, or tries connecting ADB to `192.168.x.1:5555` (timeout 10060).
- **Root Cause:** 
  1. In Android TV 11, setting a custom DNS under Wi-Fi requires selecting "Static IP" and clicking through a multi-step wizard (IP $\rightarrow$ Gateway $\rightarrow$ Network Prefix $\rightarrow$ DNS 1). Missing any field causes network disconnect.
  2. `192.168.x.1` is the home Wi-Fi gateway router, not the STB.
- **Permanent Fix:** Use the **Direct Ethernet Lab**. By connecting an RJ45 cable between PC and STB, `captive_lab.py` automatically acts as a DHCP server, assigns `192.168.50.2` to the STB, and injects `192.168.50.1` as the primary DNS server. Zero manual configuration on TV needed!

---

### 3. Issue: Windows Defender Firewall Dropping Inbound DNS (UDP 53) and HTTPS (TCP 9443)
- **Symptom:** STB boots up with Ethernet connected, but `captive_lab.log` shows no DNS queries, and `mock_acs.log` never receives incoming connections.
- **Root Cause:** When an Ethernet cable is plugged into a PC without Internet gateway access, Windows categorizes the interface as an "Unidentified Network" and defaults to the **Public Network firewall profile**. Windows Defender silently drops all inbound unsolicited UDP 53 and TCP 9443 traffic.
- **Permanent Fix:**
  - `start-adb-ethernet.ps1` automatically adds firewall group rules (`LocalLab-Allow-Inbound-UDP` and `LocalLab-Allow-Inbound-TCP`).
  - If third-party antivirus (Quick Heal, McAfee, Norton) is active, temporarily pause protection for 60 seconds during the boot handshake.

---

### 4. Issue: Host Services Occupying Ports 53, 123, or 8080
- **Symptom:** Lab fails on startup with `OSError: [WinError 10048] Only one usage of each socket address is normally permitted` or `WinError 10013`.
- **Root Cause:** 
  - Port 123 is bound by Windows Time Service (`w32time`).
  - Port 53 is bound by Windows Internet Connection Sharing / Mobile Hotspot (`SharedAccess`) or local DNS servers (e.g. Technitium DNS).
- **Permanent Fix:** The script executes:
  ```powershell
  Stop-Service w32time -ErrorAction SilentlyContinue
  Stop-Service SharedAccess -Force -ErrorAction SilentlyContinue
  Stop-Service DnsService -Force -ErrorAction SilentlyContinue
  ```

---

### 5. Issue: Android 11 SELinux Denial on Raw Partition Dump (`rootshell2.jar`)
- **Symptom:** Elevating via `rootshell2.jar` grants `uid=0(root)`, but executing `dd if=/dev/block/boot_b of=/sdcard/boot.img` yields `Permission denied`. `dmesg` reports:
  `type=1400 audit: avc: denied { read open } for path="/dev/block/boot_b" dev="tmpfs" scontext=u:r:sdknativeservice:s0 tcontext=u:object_r:block_device:s0 tclass=blk_file permissive=0`
- **Root Cause:** On Android 11 (Build 25.1.9, API 30), SELinux is set to `Enforcing`. The domain `sdknativeservice` lacks raw block device read/write capabilities (`permissive=0`).
- **Permanent Fix:** Modifying raw boot partitions is **unnecessary and dangerous** due to AVB 2.0 e-fuse locks. All debloating, launcher replacement, and telemetry suppression are executed at the Android framework level (`pm disable-user --user 0` and `cmd appops`), which requires no block manipulation and is 100% brick-proof.

---

### 6. Issue: Google Play Store SDK 34 Incompatibility (`INSTALL_FAILED_OLDER_SDK`) & Missing GMS
- **Symptom:** Pulling `com.android.vending` from a modern Android TV (such as Mi TV running Android 14) and installing it fails with:
  `INSTALL_FAILED_OLDER_SDK: Requires newer sdk version #34 (current version is #30)`.
- **Root Cause:** 
  1. The Jio STB runs Android 11 (API 30). Modern Play Store APKs require API 34+.
  2. Google Play Store requires Google Mobile Services (`com.google.android.gms`) and Google Services Framework (`com.google.android.gsf`), which do not exist on Jio STB firmware.
- **Permanent Fix:** Install **Aurora Store v4.8.4** (`apks/aurora-store.apk`). Aurora Store is an open-source Google Play client that runs natively on Android 11 (API 30), requires **zero Google Play Services**, supports anonymous login, and allows downloading any official Android TV application directly from Google Play.

---

### 7. Issue: Split APK Bundles Failing via Standard `adb install`
- **Symptom:** Installing downloaded APK bundles yields `Failure [INSTALL_FAILED_MISSING_SPLIT_APKS]`.
- **Root Cause:** Modern Android apps are distributed as split APKs (`base.apk`, `split_config.arm64_v8a.apk`, `split_config.xxhdpi.apk`).
- **Permanent Fix:** Install using `adb install-multiple`:
  ```bash
  adb install-multiple -r -g base.apk split_config.arm64_v8a.apk split_config.xxhdpi.apk
  ```
  Or install standalone monolithic APKs (such as those provided in `apks/`).

---

### 8. Issue: Stock Jio Launcher Re-appearing After Reboot
- **Symptom:** Sideloading a custom launcher works, but after rebooting or pressing the Home button on the remote, the stock Jio launcher reappears.
- **Root Cause:** The package `com.iwedia.ui.rjio.launcher.reliance` is configured as a system home intent with priority. Jio background scheduler checks if it is active.
- **Permanent Fix:** Two-step persistence:
  ```bash
  # Step 1: Set custom launcher as default home activity
  adb shell cmd package set-home-activity com.elyvon.launcher/com.omeda.arc.MainActivity

  # Step 2: Disable and suspend stock Jio launcher
  adb shell pm disable-user --user 0 com.iwedia.ui.rjio.launcher.reliance
  adb shell pm suspend --user 0 com.iwedia.ui.rjio.launcher.reliance
  ```

---

### 9. Issue: Background Services Killing Custom Launchers and Apps
- **Symptom:** Custom launchers or sideloaded apps periodically restart or experience micro-stutters.
- **Root Cause:** Services like `com.jio.smartmemorymanager` and `com.jio.appoptimizer` act as aggressive watchdog task-killers designed to favor stock Jio apps.
- **Permanent Fix:** Disable these packages and strip background execution permissions:
  ```bash
  adb shell pm disable-user --user 0 com.jio.smartmemorymanager
  adb shell pm disable-user --user 0 com.jio.appoptimizer
  adb shell cmd appops set com.jio.smartmemorymanager RUN_IN_BACKGROUND ignore
  adb shell cmd appops set com.jio.appoptimizer RUN_IN_BACKGROUND ignore
  ```

---

### 10. Issue: Host PC Left with Static IP / No Internet After Ethernet Lab
- **Symptom:** After closing the unlock lab, the host PC's Ethernet interface cannot access the local network or Internet.
- **Root Cause:** `start-adb-ethernet.ps1` configured static IP `192.168.50.1` and flushed default gateway routes for isolation.
- **Permanent Fix:** Run `RESTORE_NETWORK.bat`. It automatically removes static IP addresses, re-enables DHCP, and restores normal network operation.

---

### 11. Issue: On-Device APK Installation Fails or Exits Instantly (Carrier App Installation Lock)
- **Symptom:** Opening any APK directly on the TV (via USB drive, Send Files to TV, X-plore, or Aptoide TV) does nothing, flashes a blank screen for a split second, or fails with "Unable to install app". Installing only works when pushed from a computer via `adb install`.
- **Root Cause:** In Jio's custom Android 11 firmware, the system package installer (`/system/priv-app/PackageInstaller/PackageInstaller.apk`) has been modified by the carrier. Specifically, inside `com.android.packageinstaller.InstallStart`, `mSuppressAppInstall` is hardcoded to `true`. Whenever an APK installation intent (`ACTION_VIEW` / `ACTION_INSTALL_PACKAGE`) is dispatched, `InstallStart.onCreate()` immediately executes `finish()` in 0ms, suppressing all standard sideloading attempts. Because `/system` is protected by AVB 2.0 dm-verity, editing the system APK directly is impossible without bricking the device.
- **Permanent Fix:** Use **Shizuku** paired with the **Shizuku Package Installer** (`io.github.vvb2060.packageinstaller`):
  1. Shizuku runs a privileged daemon under ADB/shell UID 2000 (`libshizuku.so`), exposing system package management capabilities without root.
  2. The Shizuku Package Installer registers as the primary system handler for `application/vnd.android.package-archive` intents.
  3. When an APK is opened from a USB flash drive, X-plore, Send Files to TV, or Aptoide TV, Shizuku Package Installer intercepts the intent, presents a clean, remote-friendly confirmation dialog, and installs the APK with system privileges.
  4. Both Shizuku and Package Installer are automatically installed, started, and pre-authorized by `1CLICK_POST_ADB_SETUP.bat`.

---

## Comprehensive Package Debloat Directory

### 1. FOTA & OTA Update Blockers (Mandatory)
*Must be disabled to prevent Jio from pushing firmware updates that patch TR-069 or revoke ADB.*

| Package Name | Description | Command |
| :--- | :--- | :--- |
| `com.jio.httpupdate` | System OTA HTTP Download Agent | `pm disable-user --user 0 com.jio.httpupdate` |
| `com.jio.usbupdate` | System Recovery USB Update Agent | `pm disable-user --user 0 com.jio.usbupdate` |
| `com.jio.tr069client` | TR-069 Remote Management Client | `pm disable-user --user 0 com.jio.tr069client` |
| `com.rjil.jio.stb.commandreceiver`| Remote Command Receiver | `pm disable-user --user 0 com.rjil.jio.stb.commandreceiver` |
| `com.jio.backgroundscheduler` | Background Task & OTA Scheduler | `pm disable-user --user 0 com.jio.backgroundscheduler` |
| `com.jio.stbadservice` | Advertisement Delivery Service | `pm disable-user --user 0 com.jio.stbadservice` |

### 2. Telemetry, Remote Access & Background Task Killers
*Disabling these frees up ~400MB of RAM and eliminates background CPU usage.*

| Package Name | Description | Recommended Action |
| :--- | :--- | :--- |
| `com.teamviewer.quicksupport.addon.jio_stb` | Remote Screen Control Agent | Disable |
| `com.rjil.podlogservice` | Diagnostic Crash Logger | Disable |
| `com.jio.systemstats` | Hardware & Usage Telemetry Reporter | Disable |
| `com.jio.stb.remotediagnose` | Device Health Tracker | Disable |
| `com.jio.smartmemorymanager` | Aggressive Background Task Killer | Disable |
| `com.jio.appoptimizer` | App Throttling Service | Disable |
| `com.jio.bioscopecontentservice` | Movie Promo Banner Downloader | Disable |
| `com.jio.product.exploremyremote`| Remote Tutorial Popup | Disable |
| `com.jio.stb.bot` | Automated Care Bot | Disable |
| `com.jio.stbwidget` | Stock Widgets Engine | Disable |
| `com.jio.web` | JioSphere Browser | Disable |
| `com.media.jio.sso.stb` | Jio Single Sign-On Agent | Disable |
| `com.jio.profileutility` | Profile Telemetry Utility | Disable |
| `com.netflix.partnertoken` | Netflix Partner Token Service (PADI) | Disable |
| `com.jio.dialserver` | JioCast DIAL Server | Disable |
| `com.omni.simplesetup` | Setup Wizard Hook | Disable |
| `com.jio.universalsetup` | First-run Setup Service | Disable |

### 3. Non-Essential Pre-installed User Apps
| Package Name | Description | Command |
| :--- | :--- | :--- |
| `com.jio.store` | Jio App Store | `pm uninstall -k --user 0 com.jio.store` |
| `com.jio.stb.catv` | Jio Live TV Service | `pm uninstall -k --user 0 com.jio.stb.catv` |
| `com.netflix.ninja` | Stock Netflix (requires sign-in) | `pm uninstall -k --user 0 com.netflix.ninja` |

---

## Included Sideload Packages & Stores

All verified APKs are located in the `apks/` directory:

1. **Elyvon Launcher (`apks/elyvon-launcher.apk`):**
   - Clean, modern Android TV launcher with customizable favorites rows.
   - Zero advertisements, zero sponsored recommendations.
   - Extremely lightweight (~45MB RAM footprint).
2. **Aurora Store v4.8.4 (`apks/aurora-store.apk`):**
   - Direct Google Play Store access for Android TV apps.
   - Built-in anonymous login (no personal Google account required).
   - Allows downloading YouTube, SmartTube, VLC, MX Player, Plex, and streaming apps.
3. **Shizuku (`apks/shizuku.apk`) & Shizuku Package Installer (`apks/package-installer.apk`):**
   - **Shizuku (v13.6.0):** Privileged API service that runs an ADB-level daemon in the background to grant system-level capabilities to user apps.
   - **Shizuku Package Installer (v2.1):** A replacement package installer designed specifically for TV and Android devices. It completely bypasses Jio's hardcoded `mSuppressAppInstall` carrier lock, enabling 100% remote-controlled on-device APK installations from USB flash drives, X-plore, Send Files to TV, and Aptoide TV.
4. **Monet Launcher (`apks/monet-launcher.apk`):**
   - Alternative Material You dynamic themed Android TV launcher.

---

## Disaster Recovery & Factory Reset (Undo Guide)

If you ever wish to revert your Set-Top Box back to 100% factory original state:

### Method 1: Software Undo via Script
Run `undo.bat` (or `undo.ps1` in PowerShell). This will:
1. Re-install all uninstalled user packages (`com.jio.store`, `com.jio.stb.catv`, `com.netflix.ninja`).
2. Re-enable all 24+ disabled system and telemetry packages.
3. Re-enable the stock Jio Launcher (`com.iwedia.ui.rjio.launcher.reliance`) and restore it as default home.
4. Reset animation scales back to default 1.0x.

### Method 2: Hardware Factory Reset (Unbrick / Full Reversion)
Because this toolkit makes **zero modifications to raw boot/system partitions**, a hardware factory reset will completely restore stock firmware:
1. On your TV screen, navigate to **Settings** $\rightarrow$ **Device Preferences** $\rightarrow$ **Reset** $\rightarrow$ **Erase Everything**.
2. *Alternative (Hardware Button):* Locate the physical recovery pinhole button on the bottom/back of the STB. Unplug power, hold the reset button down with a pin, plug power back in, keep holding for 10 seconds until the Android Recovery screen appears, then select **Wipe data / factory reset**.

---

## Legal Disclaimer

*This project is published for educational, research, and interoperability purposes under the Apache 2.0 license. TR-069 and CWMP are open technical specifications published by the Broadband Forum. Set-Top Box hardware and brand names (Jio, Reliance, Skyworth, Iwedia) are trademarks of their respective owners. Modifying device software may void your warranty or violate your subscriber agreement with your service provider. Use at your own discretion.*
