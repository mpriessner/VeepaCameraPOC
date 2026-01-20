# Master Troubleshooting Guide: Veepa Camera Connection & Video Streaming

**Document Version**: 9.0 - Multi-Frame QR Implementation Complete
**Date**: January 19, 2026
**Status**: AP Mode WORKING - Multi-frame QR provisioning implemented (matching official app format)

---

## LATEST DISCOVERY: Camera WiFi Type Determines Provisioning Method (January 19, 2026)

### The Key Finding

Each Veepa camera has a **WiFi Type** value encoded in its physical QR code. This value determines which provisioning method the camera supports:

### Camera Physical QR Code Format

The QR code printed on the camera body contains:
```json
{"ACT":"Add","ID":"ZYLX0092354DSTM","WiFi":"15","S":"0"}
```

| Field | Description |
|-------|-------------|
| **ACT** | Action (ignore) |
| **ID** | Device VUID (unique identifier) |
| **WiFi** | **CRITICAL: Determines provisioning method** |
| **S** | If present, QR is dynamic |

### WiFi Type Values and Provisioning Methods

| WiFi Type | Provisioning Method | Description |
|-----------|---------------------|-------------|
| **0, 1, 6, 17, 18, 19** | **Sonic Wave** | Animated/flipping QR code pattern |
| **2, 8, 13** | **AP Configuration** | Connect to camera hotspot first |
| **3** | **Wired/LAN** | LAN search, no WiFi provisioning needed |
| **4** | **WiFi AP Socket** | Special AP mode |
| **5** | **Manual UID** | Manual entry only |
| **9, A** | **Bluetooth** | BLE provisioning |
| **15, 20, 25, 26** | **4G Camera** | Direct binding, no WiFi needed |
| **21, 22, 23, 24** | **Static QR Code** | Camera scans static QR from phone |
| **28** | **NVR** | Network Video Recorder |

### What is "Sonic Wave" Configuration?

The **Sonic Wave** method (WiFi types 0, 1, 6, 17, 18, 19) uses an **animated/flipping QR code** that changes rapidly (every ~0.5 seconds). This is NOT a standard QR code - it's a proprietary visual encoding system where:

1. The app displays rapidly changing patterns on screen
2. The camera watches the screen and decodes data from multiple frames
3. WiFi credentials are encoded across the animation sequence

**This method is NOT documented in the SDK** and appears to be proprietary to the official Veepa app.

### Static QR Code Format (WiFi types 21-24)

For cameras that support static QR provisioning, the phone generates:
```json
{
  "RS": "WiFiNetworkName",     // Router SSID (REQUIRED)
  "P": "WiFiPassword",         // Password (REQUIRED)
  "BS": "c8eaf8e038f1",        // Router BSSID/MAC (optional, no colons)
  "U": "15463733-OEM",         // User ID for cloud binding (optional)
  "A": "1"                     // Region: 1=Mainland, 2=Asia, 3=America, 4=Europe (optional)
}
```

### What We Implemented vs What's Needed

| Feature | Status | Notes |
|---------|--------|-------|
| Static QR Code Generation | ✅ Implemented | Works for WiFi types 21-24 |
| Cloud Polling (Hello API) | ✅ Implemented | Polls `api.eye4.cn/hello/query` |
| Sonic Wave (Animated QR) | ❌ NOT Implemented | Required for WiFi types 0,1,6,17,18,19 |
| Bluetooth Provisioning | ❌ NOT Implemented | Required for WiFi types 9, A |

### How to Determine Your Camera's WiFi Type

1. **Look at the camera's physical QR code** (printed on camera body)
2. **Scan it with any QR reader app** (or the official Veepa app)
3. **Find the "WiFi" value** in the JSON

Example: If `"WiFi":"17"` → Camera uses **Sonic Wave** (animated QR)

### Camera Physical QR Code Scan Result (January 19, 2026)

**Scanned from camera body:**
```json
{"ACT":"Add","ID":"OKB0379853SNLJ","DT":"BMW1","WiFi":"24"}
```

| Field | Value | Meaning |
|-------|-------|---------|
| ACT | Add | Action type (ignore) |
| ID | OKB0379853SNLJ | Camera's unique device ID |
| DT | BMW1 | Device Type / Model |
| **WiFi** | **24** | **STATIC QR CODE SUPPORTED!** |

### Testing Results (January 19, 2026)

| Test | Camera WiFi Type | Method Used | Result |
|------|------------------|-------------|--------|
| Official App | 24 (Static QR) | Animated flipping QR | ✅ Camera connected |
| Our App | 24 (Static QR) | Static QR | ❌ Camera didn't respond |

**Key Finding**: Camera WiFi type 24 SHOULD support static QR, but our implementation didn't work. Possible reasons:
1. Camera was not in QR scanning/provisioning mode
2. QR code format differences from official app
3. QR code size/contrast/visibility issues
4. Official app may use animation even for static QR cameras (visual feedback)

### CRITICAL DISCOVERY: Official App QR Code Analysis (January 19, 2026)

**Screenshots captured from official app during WiFi provisioning:**

The official app generates **MULTIPLE alternating QR codes**, not a single combined QR:

| Frame | QR Content | Analysis |
|-------|------------|----------|
| Frame 1 | `{"P":"6wKe727e","A":"3"}` | Password + Region |
| Frame 2 | `{"S":"4G-Gateway-DE38F1","A":"3"}` | SSID + Region |
| Frame 3 | `303-62 88 25` | **BSSID (Router MAC Address)** - Formatted as "XXX-XX XX XX" |

**Frame 3 Analysis**: The `303-62 88 25` value is the router's BSSID (MAC address) formatted for display:
- Standard BSSID format: `30:3E:62:88:25:XX` (6 octets)
- Reformatted: `303-62 88 25` (first 5 octets, spaces/dashes added)
- This helps the camera identify the exact router, especially when multiple routers share the same SSID.

### Key Differences: Official App vs Our Implementation

| Aspect | Official App | Our Implementation (v1) | Our Implementation (v2 - Fixed) |
|--------|--------------|-------------------------|--------------------------------|
| SSID field name | **"S"** | "RS" ❌ | "S" ✅ |
| Data structure | Multiple QRs (split) | Single QR ❌ | Multiple QRs ✅ |
| Region field | "A":"3" included | Missing ⚠️ | Included ✅ |
| Animation | Flips every ~500ms | Static ❌ | Flips every 500ms ✅ |
| BSSID frame | Formatted as "XXX-XX XX XX" | Not included | Included ✅ |

### Region Code Values ("A" field)

| Value | Region |
|-------|--------|
| 1 | Mainland China |
| 2 | Asia |
| 3 | America |
| 4 | Europe |

### Why Our Static QR Didn't Work

**Root Cause**: The official app splits WiFi credentials across multiple QR codes that alternate rapidly. The camera expects to see multiple different QR codes and combines the data. Our single combined QR with wrong field names ("RS" instead of "S") was not recognized.

### Solution Implementation Status (January 19, 2026)

To make QR provisioning work, we implemented:

| Fix | Status | Details |
|-----|--------|---------|
| Change SSID field from "RS" to "S" | ✅ Done | Now uses "S" matching official app |
| Multi-frame QR display | ✅ Done | Alternates every 500ms like official app |
| Add Region field "A":"3" | ✅ Done | Included in both frames |
| Include BSSID as third frame | ✅ Done | Formatted as "XXX-XX XX XX" |

**Files Modified:**
- `lib/services/wifi_qr_generator_service.dart` - Added `generateMultiFrameQRData()` method
- `lib/screens/qr_provisioning_screen.dart` - Implemented alternating QR display with frame indicator

### Source Documentation

- **Official SDK docs**: `flutter_sdk_parameter_usage_instructions.md`
- **QR code logic**: `/Veepaisdk/flutter-sdk-demo/example/lib/wifi_connect/device_connect_logic.dart`
- **WiFi type reference**: `flutter sdk参数使用说明.pdf` (translated)

---

## CRITICAL FINDING: WiFi Provisioning Methods (January 19, 2026)

### Summary

After extensive investigation, we discovered that the official Veepa SDK uses **Bluetooth or QR Code** for initial WiFi provisioning, NOT the `set_wifi.cgi` CGI command we were attempting.

### What We Tried (CGI Method) - DID NOT WORK FOR INITIAL PROVISIONING

| Attempt | Method | Result |
|---------|--------|--------|
| HTTP Direct via Safari | `http://192.168.168.1:81/set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=...&pass=...&authtype=3&enctype=4` | Returns `result=0` but camera doesn't save config |
| P2P CGI via our app | `clientWriteCgi('set_wifi.cgi?...')` | Command sent, camera reboots, but doesn't connect to router |
| Various parameter formats | Different `authtype`, `enctype`, `wpa_psk` vs `pass` | None worked for initial provisioning |

### Why CGI Method Fails for Initial Provisioning

The `set_wifi.cgi` command in the SDK (`camera_command.dart:1955-1978`) is:
1. **Designed for an EXISTING P2P connection** - requires authenticated session
2. **Likely for CHANGING WiFi** on an already-cloud-connected camera
3. **Not used by the official app** for initial setup (we verified: `configWiFi()` is never called in the example app)

### What the Official SDK Actually Uses

**Source files examined:**
- `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/example/lib/bluetooth_connect/bluetooth_connect_logic.dart`
- `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/example/lib/wifi_connect/device_connect_logic.dart`

#### Method 1: Bluetooth Provisioning (Primary Method)
```
1. Camera broadcasts Bluetooth as "MC-0379832" or "IPC-XXXXXX"
2. Phone connects via BLE (service UUID: FFF0, characteristic: FFF1)
3. Phone sends WiFi credentials via BLE packets (BluePackage.toData())
4. Camera receives credentials, connects to router WiFi
5. Camera registers with Veepa cloud ("hello" service)
6. App polls cloud API to detect camera online
```

**Key code (bluetooth_connect_logic.dart:214-218):**
```dart
state!.wifiData = BluePackage.toData(
    "15463733-OEM", state!.wifiName.value, state!.wifiPsw, 1)
    .buffer.asUint8List();
```

#### Method 2: QR Code Provisioning (Alternative)
```
1. App generates QR code with WiFi credentials
2. User shows QR to camera's lens
3. Camera scans QR, extracts credentials
4. Camera connects to router, registers with cloud
5. App polls cloud to detect camera online
```

**QR format (device_connect_logic.dart:75-76):**
```dart
qrContent = '{"BS":"${bssid}","P":"${password}","U":"userid","RS":"${ssid}"}';
```

### Key Insight: Cloud Registration is Required

Both official methods involve the camera **registering with Veepa's cloud** after connecting to WiFi. The app then detects the camera via cloud polling, NOT direct local connection.

This explains why:
- Official app works even through NAT/firewalls
- Our direct P2P to router IP failed (camera doesn't expose ports in STA mode)
- Camera HTTP ports (80, 81) are closed when connected to router

### Verified Working in Our App

| Feature | Status | Notes |
|---------|--------|-------|
| AP Mode P2P Connection | ✅ WORKING | Phone connected to camera hotspot |
| AP Mode Video Streaming | ✅ WORKING | Live video displays correctly |
| Router Mode P2P (via cached credentials) | ❌ TIMEOUT | Camera on router, phone on router - times out |

### Recommendations for Router WiFi Support

**Option A: Implement Bluetooth Provisioning**
- Requires: `flutter_blue_plus` package, BLE permissions
- Complexity: High (BLE protocol, packet formatting)
- Advantage: Native feel, works offline

**Option B: Implement QR Code Provisioning**
- Requires: QR generation, cloud API integration
- Complexity: Medium
- Advantage: Simpler than BLE, familiar UX

**Option C: Use Official App for Provisioning**
- User provisions camera with official Veepa app
- Our app connects via P2P using cached cloud credentials
- Limitation: Dependency on official app

### Files Modified During Investigation

| File | Change |
|------|--------|
| `lib/main.dart:66` | Changed `SDKMode.mock` to `SDKMode.real` |
| `lib/models/camera_config.dart` | Added camera selector (Camera 1 & 2) |
| `lib/screens/wifi_setup_screen.dart` | Added camera dropdown, WiFi config attempts |
| `lib/screens/p2p_test_screen.dart` | Added camera dropdown |
| `ios/Podfile` | Added VeepaSDK pod |
| `ios/Runner/Runner-Bridging-Header.h` | Added VsdkPlugin import |
| `ios/Runner/AppDelegate.swift` | Registered VsdkPlugin |

---

## Current Status

### MILESTONE ACHIEVED: Direct WiFi Connection Works!

| Feature | Status | Notes |
|---------|--------|-------|
| App Restart | **WORKING** | Fixed by using Release Flutter frameworks |
| Direct WiFi Connection (AP Mode) | **WORKING** | Phone connects to camera's hotspot |
| P2P Connection (AP Mode) | **WORKING** | Uses password `888888` |
| Video Streaming (AP Mode) | **WORKING** | Live video displays correctly |
| Router WiFi Connection (STA Mode) | **BLOCKED** | Requires Bluetooth or QR provisioning |
| Camera UID Selector | **WORKING** | Switch between Camera 1 & Camera 2 |
| Real SDK Mode | **WORKING** | Changed from mock to real mode |

---

## What We Solved

### Issue 1: Wrong Password (SOLVED)
- **Problem**: Using `admin` as password
- **Solution**: Changed to `888888` (factory default)
- **File Changed**: `p2p_test_screen.dart`

### Issue 2: App Crash on Restart (SOLVED)
- **Problem**: Debug Flutter frameworks required debugger connection
- **Solution**: Switched to Release Flutter frameworks in `project.yml`
- **Root Cause**: Debug frameworks crash when launched without Xcode attached

### Issue 3: Singleton State on Restart (SOLVED)
- **Problem**: `AppP2PApi` singleton retained stale EventChannel state
- **Solution**: Added `resetInstance()` method, called on app startup
- **Files Changed**: `app_p2p_api.dart`, `main.dart`

---

## Next Goal: Router WiFi Connection

### Current Setup (Working)
```
Phone ──WiFi──> Camera Hotspot (@MC-0379196)
                     │
                  Camera
```
- Phone connects directly to camera's WiFi hotspot
- IP: 192.168.168.1
- This is "AP Mode" (Access Point Mode)

### Target Setup (To Implement)
```
Phone ──WiFi──> Home Router <──WiFi── Camera
                     │
                 Internet
```
- Both phone AND camera connect to the same WiFi router
- Camera needs to be configured for "STA Mode" (Station Mode)
- This enables remote access and is more practical for real use

### How to Configure Camera for Router WiFi

#### Option 1: Via Eye4 App
1. Open Eye4 app
2. Add camera (if not added)
3. Go to camera settings → WiFi settings
4. Select your home WiFi and enter password
5. Camera will restart and connect to router

#### Option 2: Via CGI Command (While in AP Mode)
```
http://192.168.168.1:81/set_wifi.cgi?loginuse=admin&loginpas=888888&ssid=YOUR_WIFI_NAME&pass=YOUR_WIFI_PASSWORD&authtype=2&enctype=4
```

#### Option 3: Via Our App (To Implement)
- Add WiFi configuration screen
- Send `set_wifi.cgi` command
- Handle camera restart and reconnection

### Testing Router Connection

Once camera is on router WiFi:
1. Find camera's new IP address (from router admin or `get_status.cgi`)
2. Update device ID or use cloud connection
3. Test P2P connection with `connectType=126` (cloud assist mode)

---

## Quick Reference

### Credentials
| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `888888` |

### Connection Modes
| Mode | connectType | Use Case |
|------|-------------|----------|
| LAN/AP (Direct WiFi) | 63 | Phone on camera hotspot |
| Cloud Assist | 126 | Both on router, may need cloud |
| Relay | 123 | Fallback mode |

### Device IDs
| Type | Prefix | Example |
|------|--------|---------|
| Virtual ID | OKB | OKB0379196OXYB |
| Real ID | VSTH | VSTH285556GJXNB |

---

## Archived Documentation

The following troubleshooting docs have been archived (issues solved):
- `archive/troubleshooting_solved/DEEP_DIVE_TROUBLESHOOTING.md`
- `archive/troubleshooting_solved/VIDEO_STREAMING_TROUBLESHOOTING.md`
- `archive/troubleshooting_solved/VIDEO_STREAMING_ANALYSIS_V2.md`
- `archive/troubleshooting_solved/CAMERA_CONNECTION_ANALYSIS.md`
- `archive/troubleshooting_solved/SDK_DEEP_ANALYSIS_v2.md`
- `archive/troubleshooting_solved/STREAMING_TROUBLESHOOT_TRAVEL_SHOOT.md`

---

## Files Modified for Solutions

| File | Change |
|------|--------|
| `flutter_veepa_module/lib/screens/p2p_test_screen.dart` | Password changed to `888888` |
| `flutter_veepa_module/lib/sdk/app_p2p_api.dart` | Added `resetInstance()` method |
| `flutter_veepa_module/lib/main.dart` | Call `resetInstance()` on startup |
| `ios_host_app/project.yml` | Changed to Release Flutter frameworks |
| `ios_host_app/VeepaPOC/Services/FlutterEngineManager.swift` | Added debug logging |
| `ios_host_app/VeepaPOC/App/AppDelegate.swift` | Added lifecycle logging |

---

---

## Investigation Timeline

| Date | Finding |
|------|---------|
| Jan 18, 2026 | AP Mode P2P + Video streaming working |
| Jan 18, 2026 | Discovered `set_wifi.cgi` format via HTTP testing |
| Jan 19, 2026 | Router mode P2P timeout despite correct credentials |
| Jan 19, 2026 | Found AP isolation setting on router (fixed, still timeout) |
| Jan 19, 2026 | Discovered camera closes HTTP ports in STA mode |
| Jan 19, 2026 | **CRITICAL**: Found official SDK uses Bluetooth/QR, not CGI |
| Jan 19, 2026 | Implemented Static QR Code provisioning with cloud polling |
| Jan 19, 2026 | Added iOS location permission for WiFi SSID detection |
| Jan 19, 2026 | **CRITICAL**: Discovered WiFi Type determines provisioning method |
| Jan 19, 2026 | Found "Sonic Wave" (animated QR) is different from static QR |
| Jan 19, 2026 | Static QR didn't work - camera likely requires Sonic Wave |

---

## Files Created/Modified for QR Provisioning (January 19, 2026)

| File | Change |
|------|--------|
| `lib/services/hello_api_service.dart` | **NEW**: Cloud API service for polling camera registration |
| `lib/screens/qr_provisioning_screen.dart` | **NEW**: Full QR provisioning screen with cloud polling |
| `lib/services/wifi_qr_generator_service.dart` | Added `generateOfficialVeepaQRData()` method |
| `lib/main.dart` | Added "QR WiFi Setup (Recommended)" button |
| `pubspec.yaml` | Added `network_info_plus`, `http` dependencies |
| `ios/Podfile` | Added `PERMISSION_LOCATION` for permission_handler |
| `ios/Runner/Info.plist` | Added location permission descriptions |
| `ios/Runner/Runner.entitlements` | **NEW**: Added WiFi info entitlement |
| `ios/Runner.xcodeproj/project.pbxproj` | Added entitlements to all build configs |

---

## Next Steps for Router WiFi Support

### Option 1: Implement Sonic Wave (Complex)
- Reverse engineer the animated QR pattern
- Requires understanding the frame encoding
- **NOT recommended** - proprietary and undocumented

### Option 2: Implement Bluetooth Provisioning (Recommended)
- SDK includes `bluetooth_connect_logic.dart` with protocol details
- Requires `flutter_blue_plus` package
- BLE service UUID: `FFF0`, characteristic: `FFF1`
- Uses `BluePackage.toData()` for credential encoding

### Option 3: Use Official App for Provisioning
- User provisions camera with official Veepa/Eye4 app
- Our app connects via P2P using cached credentials
- **Simplest approach** - camera already works after official app setup

### Option 4: Check if Camera Supports Static QR
- Scan camera's physical QR code
- Check if WiFi type is 21, 22, 23, or 24
- If yes, static QR should work (our implementation)

---

*Document updated January 19, 2026 - Version 8.0*
*Discovery: Camera WiFi type determines which provisioning method works*
*Next step: Determine camera's WiFi type or implement Bluetooth provisioning*
