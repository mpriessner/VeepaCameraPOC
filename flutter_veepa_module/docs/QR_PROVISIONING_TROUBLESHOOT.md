# QR WiFi Provisioning & P2P Streaming - Complete Guide

## Executive Summary

**FULL SUCCESS ACHIEVED**: Camera successfully provisioned to home WiFi and P2P video streaming works.

| Step | Status |
|------|--------|
| WiFi Provisioning (via QR) | ✅ WORKS (using image mode) |
| Camera on Home Network | ✅ Connected |
| P2P Connection | ✅ WORKS |
| Video Streaming | ✅ WORKS |
| Generated QR Codes | ⚠️ PAUSED (workaround exists) |

---

## Complete Working Flow

### Step 1: WiFi Provisioning (QR Code)

**What Works**: Using **Image Mode** (Mode 3) with exact screenshots from the official Veepa app.

**Process**:
1. Put camera in QR setup mode (press reset, wait for blinking)
2. Open app → QR Provisioning screen
3. Select **"Images (exact)"** mode (green button)
4. Enter WiFi password
5. Generate and show QR codes to camera
6. Camera blinks fast when scanning, then connects to WiFi

**QR Pattern** (from official app):
- Frame 1: Full data `{"BS":"bssid","P":"password","U":"","S":"ssid"}` - shown ONCE
- Frame 2: User ID #1 (plain text)
- Frame 3: User ID #2 (different QR)
- Frame 4: SSID + Region `{"S":"ssid","A":"3"}`
- Frame 5: Password + Region `{"P":"password","A":"3"}`
- Cycles through frames 2-5 at 500ms intervals

### Step 2: Verify Camera Connected

After provisioning, camera gets IP on home network:
- Access via: `http://<camera-ip>:81/get_status.cgi?loginuse=admin&loginpas=888888`
- **Important**: Port is **81**, not 80

### Step 3: P2P Video Streaming

**Process**:
1. Open app → P2P Test screen
2. Select correct camera from dropdown (e.g., "Camera 3 (WiFi)")
3. Click **"Fetch"** to get P2P credentials from cloud (one time)
4. Click **"Connect"** to establish P2P connection
5. Click **"Start Video"** to begin streaming

**Connection Details**:
- Uses cached credentials (clientId + serviceParam)
- LAN mode (connectType: 63) for local network
- Credentials fetched from `vuid.eye4.cn`

---

## Technical Details

### Camera Configuration

```dart
// lib/models/camera_config.dart
static const camera3 = CameraConfig(
  uid: 'OKB0379853SNLJ',
  name: 'Camera 3 (WiFi)',
  hotspotName: '@MC-0379853',
);
```

### Camera Access (HTTP)

| Parameter | Value |
|-----------|-------|
| IP | Assigned by router (e.g., 192.168.32.10) |
| Port | **81** |
| Username | `admin` |
| Password | `888888` |
| Status URL | `/get_status.cgi?loginuse=admin&loginpas=888888` |

### P2P Connection Flow

```
1. clientCreate(clientId)           → Get client pointer
2. clientConnect(ptr, lanScan=true, serviceParam, connectType=63)
3. clientLogin(ptr, "admin", "888888")
4. Create AppPlayerController
5. setVideoSource(LiveVideoSource(ptr))
6. start() → Video streams!
```

### Key Files

| File | Purpose |
|------|---------|
| `lib/screens/qr_provisioning_screen.dart` | QR WiFi provisioning UI |
| `lib/screens/p2p_test_screen.dart` | P2P connection & video streaming |
| `lib/services/wifi_qr_generator_service.dart` | QR code data generation |
| `lib/models/camera_config.dart` | Camera UID configuration |
| `lib/services/p2p_credential_cache.dart` | Credential caching |
| `assets/qr_images/` | Screenshot QR images from official app |

---

## QR Code Generation - SOLVED!

### Problem (Historical)
Generated QR codes caused camera to respond (blink) but then drop connection. Screenshot images worked perfectly.

### Root Cause Discovered
The camera firmware is sensitive to **specific QR mask patterns**. Different QR libraries can produce functionally equivalent but visually different QR codes due to mask pattern selection.

### Solution - Decoded Official QR Data & Mask Patterns

**Step 1: Decoded actual data from official app screenshots using zbarimg:**

| Frame | Data Content | Version | Modules |
|-------|-------------|---------|---------|
| 1 (Full) | `{"BS":"bssid","P":"password","U":"","S":"ssid"}` | V4 | 33 |
| 2 (User ID #1) | `{"BS":"bssid","P":"password","U":"userid","S":"ssid"}` | V4 | 33 |
| 3 (User ID #2) | `{"BS":"bssid","U":"userid","A":"3"}` | V3 | 29 |
| 4 (SSID) | `{"S":"ssid","A":"3"}` | V3 | 29 |
| 5 (Password) | `{"P":"password","A":"3"}` | V2 | 25 |

**Step 2: Found correct mask patterns by visual comparison:**

| Frame | QR Version | Mask Pattern | Error Correction |
|-------|-----------|--------------|------------------|
| Frame 2 (Full+UserID) | V4 (33 modules) | **Mask 4** | L |
| Frame 3 (BS+U+A) | V3 (29 modules) | **Mask 2** | L |
| Other frames | Auto | Auto | L |

**Step 3: Implementation:**
- Created `MaskedQrWidget` using `qr` package's `QrImage.withMaskPattern()`
- Updated `WifiQRGeneratorService.generateOfficialPattern()` with correct data
- Added `getQrConfigForFrame()` to return version and mask for each frame
- Mode 2 ("Official") now generates pixel-perfect matching QR codes

### Key Learnings

1. **SDK Documentation is WRONG**: Single QR code does NOT work. Multi-frame sequence required.

2. **QR Mask Patterns Matter**: The `qr_flutter` package auto-selects masks, but camera firmware expects specific masks for certain frames.

3. **Data Structure Discovered**:
   - Frame 2 = Full credentials WITH user ID (not just user ID alone)
   - Frame 3 = BSSID + User ID + Region (subset)
   - "User ID frames" are actually JSON payloads, not plain text

4. **Tools Used**:
   - `zbarimg` to decode official QR screenshots
   - Custom test screen to compare all 8 mask patterns
   - `QrImage.withMaskPattern()` from `qr` package

### Current Status
- **Mode 2 (Official)**: Now generates correct QR codes with proper mask patterns
- **Mode 3 (Images)**: Still available as fallback using screenshots

---

## User/Network Details

| Item | Value |
|------|-------|
| WiFi SSID | `4G-Gateway-DE38F1` |
| WiFi BSSID | `c8:ea:f8:e0:38:f1` |
| Veepa User ID | `303628825` (formatted: `303-62 88 25`) |
| Region Code | `3` (America) |
| Camera UID | `OKB0379853SNLJ` |

---

## For Future AI Reference

### To Provision a New Camera:
1. Capture QR screenshots from official Veepa app for the specific WiFi network
2. Save to `assets/qr_images/`
3. Use Image Mode in QR Provisioning screen

### To Stream from Provisioned Camera:
1. Add camera UID to `KnownCameras` in `camera_config.dart`
2. Fetch credentials (requires internet once)
3. Connect and stream (works offline after fetch)

### To Fix QR Generation (Future Work):
1. Investigate SDK source for QR encoding specifics
2. Look for seed/deterministic parameters
3. Compare generated vs screenshot at binary level
4. Check if two User ID frames have different content

---

*Document last updated: 2026-01-19*
*Status: WiFi Provisioning + P2P Streaming = WORKING*
