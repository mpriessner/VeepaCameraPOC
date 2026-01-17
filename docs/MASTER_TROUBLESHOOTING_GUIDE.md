# Master Troubleshooting Guide: Veepa Camera Connection & Video Streaming

**Document Version**: 3.0 - Final
**Date**: January 17, 2026
**Status**: Comprehensive Analysis Complete

---

## Executive Summary

After analyzing the original SDK, vendor feedback, and **official documentation**, we have identified the root cause of the connection issues:

### THE MAIN PROBLEM: WRONG PASSWORD

| What We Used | Official Default | Source |
|--------------|------------------|--------|
| `admin` | **`888888`** | `flutter_sdk_parameter_usage_instructions.md` |

**Official Documentation Quote:**
> **password:** Device password (**factory default is 888888**, can be changed after connecting).
> **username:** Login username for the device (**admin**, cannot be changed).

---

## Part 1: Official Documentation Findings

### From `flutter_sdk_parameter_usage_instructions.md`

```dart
CameraDevice mDevice = CameraDevice(
  String id,        // Device ID from camera body label
  String name,      // Device name
  String username,  // Login username (admin, cannot be changed)
  String password,  // Device password (factory default is 888888)
  String model      // Device model (e.g., 4g/wifi)
)
```

### Connection States (Official)

| State | Meaning |
|-------|---------|
| `connecting` | Connecting... |
| `logging` | Logging in... |
| `connected` | **Online and ready** |
| `timeout` | Connection timeout |
| `disconnect` | Disconnected |
| `password` | **Password error** |
| `maxUser` | Too many users watching |
| `offline` | Device offline |
| `illegal` | Illegal device |

### This Confirms:
- `result=-1`, `-2`, `-3` → Maps to `CameraConnectState.password` (Password Error)
- The official default password is `888888`, NOT `admin`

---

## Part 2: SDK Code Analysis

### Password Usage in Demo App

```dart
// device.dart line 14
Future<bool> init(String did, {String psw = "888888", ...})

// main_state.dart line 9
String psw = "888888";

// home_logic.dart line 48-49
String psw = await DeviceListManager.getInstance().getDevicePsw(uid) ?? "888888";

// status_command.dart line 512
if (password == "888888") return "初始密码";  // "Initial password"
```

### HTTP Direct Access (AP Mode)

```dart
// p2p_device.dart line 285
"http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888"
```

---

## Part 3: What Could Be Wrong

### Issue 1: Wrong Password (CONFIRMED - HIGH PROBABILITY)

**Cause**: We've been using `admin` as password instead of `888888`

**Evidence**:
- Official docs say factory default is `888888`
- SDK demo uses `888888` everywhere
- HTTP CGI uses `loginpas=888888`

**Fix**: Change password to `888888`

### Issue 2: Password Changed by Eye4 App

**Cause**: When you pair camera with Eye4 app, it may change the password

**Evidence**:
- `pwdfactory=1` in response suggests factory mode
- But still getting `result=-1`
- Eye4 app may have changed password during pairing

**Fix**:
1. Factory reset camera (10+ seconds)
2. Do NOT reconnect with Eye4 after reset
3. Connect directly with our app using `888888`

### Issue 3: SDK Files Modified

**Cause**: Our SDK files differ from the original

**Evidence**:
```
Files that differ:
- app_p2p_api.dart
- app_player.dart
- camera_device.dart
- status_command.dart
- video_command.dart
- p2p_device.dart
```

**Fix**: Compare and sync with original SDK, or use original files

### Issue 4: Command Listener Timing

**Cause**: Command listener not set up before login attempt

**Evidence**:
- Login response (CMD 24577) may be lost if listener not ready
- `waitCommandResult()` times out instead of receiving response

**Fix**: Ensure `setCommandListener()` is called immediately after P2P connect

### Issue 5: Not Using CameraDevice Class Properly

**Cause**: Using raw `AppP2PApi` instead of `CameraDevice` class

**Evidence**:
- Demo app uses `CameraDevice` with proper listener setup
- We're calling API methods directly

**Fix**: Use `CameraDevice` class as designed:
```dart
CameraDevice device = CameraDevice(uid, 'Test', 'admin', '888888', 'QW6-T');
device.addListener<StatusChanged>(statusListener);
device.addListener<CameraConnectChanged>(connectListener);
var state = await device.connect();
```

---

## Part 4: Action Plan

### Step 1: Test HTTP Access (IMMEDIATE)

1. Connect phone to camera's AP WiFi (@MC-0379196)
2. Open Safari
3. Go to: `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888`
4. **Expected**: Camera status data (confirms password works)
5. **If fails**: Try `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=admin`

### Step 2: Update Code to Use `888888`

Change all password references from `admin` to `888888`:

```dart
// In p2p_test_screen.dart
await AppP2PApi().clientLogin(clientPtr, 'admin', '888888');
```

### Step 3: Factory Reset (If Step 1 Fails)

1. Hold reset button for 10+ seconds
2. Wait for voice prompt
3. Do NOT open Eye4 app
4. Connect directly with our app

### Step 4: Use CameraDevice Class

Instead of raw API calls:
```dart
// Current (problematic):
final clientPtr = await AppP2PApi().clientCreate(id);
await AppP2PApi().clientConnect(clientPtr, ...);
await AppP2PApi().clientLogin(clientPtr, 'admin', 'admin');

// Recommended (official way):
CameraDevice device = CameraDevice(cameraUID, 'Test', 'admin', '888888', 'QW6-T');
device.addListener<CameraConnectChanged>((device, state) {
  print('State: $state');
});
var state = await device.connect();
if (state == CameraConnectState.connected) {
  await device.startStream(resolution: VideoResolution.general);
}
```

### Step 5: Compare SDK Files

```bash
# Compare original vs our copy
diff /Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/camera_device/camera_device.dart \
     /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/camera_device/camera_device.dart
```

---

## Part 5: Complete Connection Flow (Official)

### From `veepai_device_adding_and_usage_process.md`

```
1. Create CameraDevice Object
   └─▶ CameraDevice mDevice = CameraDevice('DEVICE_ID', 'Name', 'admin', '888888', 'model');

2. Connect to Device
   └─▶ var connectState = await mDevice.connect();

3. Handle Connection Result
   └─▶ Check connectState for: connected, password, timeout, offline, etc.

4. Read/Write Data (if connected)
   └─▶ mDevice.writeCgi(...)
   └─▶ mDevice.waitCommandResult(...)

5. Live Streaming
   └─▶ Create AppPlayerController
   └─▶ mDevice.startStream()
```

---

## Part 6: CGI Commands Reference

### Authentication in CGI

```
HTTP Basic Auth: loginuse=admin&loginpas=888888
Example: http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888
```

### Key CGI Commands

| Command | Purpose |
|---------|---------|
| `get_status.cgi?` | Get device status |
| `get_camera_params.cgi?` | Get camera parameters |
| `livestream.cgi?streamid=10&substream=2&` | Start video stream |
| `camera_control.cgi?param=X&value=Y&` | Control camera settings |

---

## Part 7: Vendor Feedback Explained

### Statement: "No default passwords and authentication restrictions"

**Interpretation**:
- The vendor may mean there's no UNIVERSAL default
- Each camera model/batch may have different defaults
- But official docs clearly state `888888` is factory default

### Statement: "SDK allows video data to be streamed directly"

**Interpretation**:
- Video CAN stream once properly authenticated
- May also work without login in AP mode
- The SDK is capable, we just need correct credentials

---

## Part 8: Troubleshooting Checklist

### Pre-Connection
- [ ] Credentials cached? (green box in app)
- [ ] Phone connected to camera's WiFi or same network?
- [ ] Using password `888888` (not `admin`)?
- [ ] Using username `admin`?

### Connection
- [ ] P2P connect succeeds? (`CONNECT_STATUS_ONLINE`)
- [ ] Command listener set up?
- [ ] Login sent with correct credentials?
- [ ] CMD 24577 response received?
- [ ] `result=0` in response? (not `-1`)

### Video
- [ ] `startStream()` called?
- [ ] CMD 24631 response received?
- [ ] Player created with texture?
- [ ] Frames arriving?

---

## Part 9: Error Code Reference

### Login Result Codes (CMD 24577)

| Code | Meaning | Action |
|------|---------|--------|
| `result=0` | Success | Proceed to video |
| `result=-1` | Login failure (password/other) | Check password, try `888888` |
| `result=-2` | Retry 2 failed | Same as -1 |
| `result=-3` | Retry 3 failed | Same as -1 |
| `result=-4` | Illegal device | Check virtual ID |

### Connection States

| State | Meaning |
|-------|---------|
| `CONNECT_STATUS_ONLINE` | P2P connected, ready for login |
| `CONNECT_STATUS_CONNECTING` | P2P connecting |
| `CONNECT_STATUS_CONNECT_FAILED` | P2P failed |
| `CONNECT_STATUS_CONNECT_TIMEOUT` | P2P timeout |
| `CONNECT_STATUS_OFFLINE` | Device offline |

---

## Part 10: Files Reference

### Official Documentation
| File | Content |
|------|---------|
| `flutter_sdk_parameter_usage_instructions.md` | **Key: Factory default password is `888888`** |
| `veepai_device_adding_and_usage_process.md` | Connection flow guide |
| `CGI_COMMAND_MANUAL_v12_20231223.md` | CGI command reference |
| `Function_Command_Document_0125.md` | Feature-specific commands |

### SDK Files
| File | Purpose |
|------|---------|
| `camera_device.dart` | Main device class with `connect()` |
| `status_command.dart` | Login and status commands |
| `video_command.dart` | Video streaming commands |
| `p2p_device.dart` | P2P connection base class |
| `app_p2p_api.dart` | Low-level P2P API |

---

## Part 11: Quick Reference Card

```
┌─────────────────────────────────────────────────────────┐
│           VEEPA CAMERA QUICK REFERENCE                   │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  DEFAULT CREDENTIALS:                                    │
│    Username: admin                                       │
│    Password: 888888  (NOT "admin"!)                      │
│                                                          │
│  AP MODE (Direct WiFi):                                  │
│    Camera IP: 192.168.168.1                              │
│    Port: 81                                              │
│    Test URL:                                             │
│    http://192.168.168.1:81/get_status.cgi?               │
│           loginuse=admin&loginpas=888888                 │
│                                                          │
│  CONNECTION FLOW:                                        │
│    1. CameraDevice(id, name, 'admin', '888888', model)   │
│    2. device.addListener(...)                            │
│    3. await device.connect()                             │
│    4. Check state == CameraConnectState.connected        │
│    5. await device.startStream()                         │
│                                                          │
│  RESULT CODES:                                           │
│    result=0  → Success                                   │
│    result=-1 → Login failed (wrong password?)            │
│                                                          │
│  FACTORY RESET:                                          │
│    Hold reset button 10+ seconds                         │
│    Wait for voice prompt                                 │
│    Password resets to: 888888                            │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

---

## Conclusion

**The primary issue is almost certainly the wrong password.**

We've been using `admin` but the official documentation clearly states the factory default is `888888`.

### Immediate Actions:
1. Test HTTP access with `888888`
2. Update all code to use `888888`
3. If still failing, factory reset camera
4. Use `CameraDevice` class properly with listeners

### Secondary Issues to Address:
- Compare SDK files with original
- Fix app crash on restart (error handling added)
- Implement proper authentication state checking

---

*Document compiled from official Veepa documentation, SDK analysis, and vendor feedback.*
