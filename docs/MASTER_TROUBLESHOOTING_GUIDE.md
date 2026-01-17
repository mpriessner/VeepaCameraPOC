# Master Troubleshooting Guide: Veepa Camera Connection & Video Streaming

**Document Version**: 5.0 - Complete Analysis
**Date**: January 17, 2026
**Status**: All Documentation Reviewed (18 Potential Issues Identified)

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

### Issue 6: Virtual ID vs Real ID Confusion (NEW)

**Cause**: Using OKB virtual ID instead of resolved VSTH real device ID

**Evidence**:
- `CameraDevice.connect()` flags password errors if `realdeviceid != id` when using OKB virtual ID
- SDK expects the resolved VSTH ID for proper authentication
- Virtual ID lookups require cloud connectivity

**Fix**:
1. Use real device ID (VSTH prefix) when possible
2. Ensure cloud connectivity for virtual ID resolution
3. Cache initstring only after successful cloud resolution

### Issue 7: Wrong connectType for Virtual IDs (NEW)

**Cause**: P2PTestScreen uses `connectType=63` (LAN) but SDK default for virtual IDs is `connectType=126` (cloud assist)

**Evidence**:
- SDK code shows different connect types: 126 (P2P/cloud), 63 (LAN), 123 (relay)
- LAN-only mode fails for virtual IDs that need cloud resolution

**Fix**:
```dart
// For virtual IDs (OKB prefix):
connectType = 126;  // Cloud assist mode

// For LAN/AP mode with direct connection:
connectType = 63;   // LAN only mode
```

### Issue 8: Empty Password Rejection (NEW)

**Cause**: `AppP2PApi.clientLogin` rejects empty passwords, but CGI manual shows empty passwords can be valid

**Evidence**:
- CGI manual examples: `loginpas=` (empty password)
- SDK Dart wrapper throws error for empty password
- Some devices/modes may accept blank credentials

**Fix**: Temporarily allow empty passwords in `clientLogin` for testing:
```dart
// In app_p2p_api.dart - remove password validation for testing
// Test with blank password after 888888 fails
```

### Issue 9: Livestream Flow Order Wrong (NEW)

**Cause**: Test path sends `livestream.cgi` but doesn't wait for CMD 24631 before starting player

**Evidence**:
- Official flow: `startStream()` waits for CMD 24631
- Current test path starts player without waiting
- Player may not receive frames if started too early

**Fix**: Correct order:
```dart
// 1. Send livestream command
await device.startStream(resolution: VideoResolution.general);

// 2. Wait for CMD 24631 acknowledgment (handled internally by startStream)

// 3. THEN start player
player.start();
```

### Issue 10: Per-Device Password (NEW)

**Cause**: Device may have been provisioned with a per-device password, not the factory default

**Evidence**:
- Official docs show example with random password: `70312622c2eec424`
- QR provisioning may set unique passwords
- Eye4 app may change password during pairing

**Fix**:
1. Factory reset to restore `888888`
2. Or retrieve password from QR code/vendor provisioning system
3. Do NOT reconnect with Eye4 after reset

### Issue 11: Video May Work WITHOUT Login (NEW - FROM VENDOR FEEDBACK)

**Cause**: Vendor stated "SDK allows video data to be streamed directly" - login may not be required in all modes

**Evidence**:
- Vendor feedback: "There are no default passwords and authentication restrictions"
- In AP mode, direct CGI commands may work without P2P login
- `DEEP_DIVE_TROUBLESHOOTING.md` suggests trying video without login

**Fix**: Try skipping login entirely and sending livestream.cgi directly:
```dart
// Skip clientLogin() - go directly to video
await AppP2PApi().clientConnect(clientPtr, true, serviceParam, connectType: 63);
// Don't call clientLogin() - try stream directly
await AppP2PApi().clientWriteCgi(clientPtr, 'livestream.cgi?streamid=10&substream=2&');
```

### Issue 12: Camera Wake-Up State (Low Power Mode) (NEW)

**Cause**: Low-power cameras may be in sleep mode and won't respond until woken up

**Evidence**:
- `02_Function_Command_Documentation.md`: Low power mode commands
- `04_Alarm_Function_Development_Documentation.md`: Low-power device detection
- `wakeupState` can be `sleep`, `waking`, `awake`
- Must call `requestWakeupStatus()` for low-power devices

**Detection**: Check if camera is low-power type:
```dart
// From get_status.cgi response:
// support_low_power == 1 → Low-power device (battery, needs wake-up)
// support_low_power == null or 0 → Long-power device (always on)
```

**Fix**:
```dart
// Check if device is low-power
final status = await device.getStatus();
if (status.support_low_power == "1") {
  // Low-power device - must wake up first
  await device.requestWakeupStatus();
  // Wait for wakeupState == awake before proceeding
  while (device.wakeupState != WakeupState.awake) {
    await Future.delayed(Duration(milliseconds: 500));
  }
}
// Now safe to connect and stream
```

### Issue 13: Yellow LED Indicates Not Ready (NEW)

**Cause**: Camera LED state may indicate it's not ready to stream

**Evidence**:
- Yellow LED observed during connection attempts
- LED color/state may indicate initialization in progress

**Fix**:
1. Wait for LED to change to expected color (usually blue or green)
2. Check `get_status.cgi` for device readiness

### Issue 14: LiveVideoSource Binding Mismatch (NEW)

**Cause**: `LiveVideoSource(clientPtr)` may expect a pointer from fully-initialized CameraDevice, not raw P2P API

**Evidence**:
- Demo app always uses `device.clientPtr` from CameraDevice
- Raw P2P API may create clientPtr in different state
- Native layer may check for specific initialization flags

**Fix**: Use CameraDevice class instead of raw API to ensure proper initialization:
```dart
CameraDevice device = CameraDevice(uid, name, 'admin', '888888', model);
await device.connect();
// Now device.clientPtr is properly initialized
LiveVideoSource source = LiveVideoSource(device.clientPtr!);
```

### Issue 15: Missing Pre-Login CGI Commands (NEW)

**Cause**: CameraDevice may send status/param commands before login that our raw API approach is missing

**Evidence**:
- Demo app calls `requestWakeupStatus`, `getStatus` before stream
- `DEEP_DIVE_TROUBLESHOOTING.md`: Log official command sequence
- Camera may need "handshake" commands

**Fix**: Log and replicate the official CameraDevice command sequence:
```dart
// Add logging to p2p_device.dart writeCgi()
print('[P2P_DEVICE_LOG] Writing CGI: $cgi');
// Then replicate the exact sequence in your code
```

### Issue 16: Duplicate Login Call is Intentional (NEW)

**Cause**: Login is called TWICE in SDK code - this is intentional, not a bug

**Evidence**:
- `status_command.dart` lines 528-529:
  ```dart
  AppP2PApi().clientLogin(clientPtr!, username, password);  // Fire and forget
  bool ret = await AppP2PApi().clientLogin(clientPtr!, username, password);  // Await result
  ```
- First call initiates, second waits for response

**Fix**: If using raw API, call login twice as SDK does:
```dart
AppP2PApi().clientLogin(clientPtr, 'admin', '888888'); // Don't await
await AppP2PApi().clientLogin(clientPtr, 'admin', '888888'); // Await this one
```

### Issue 17: AP Mode vs Cloud Mode Auth Differences (NEW)

**Cause**: Camera in AP mode (direct WiFi) may have different auth requirements than cloud mode

**Evidence**:
- AP mode IP: 192.168.168.1:81
- HTTP CGI works in AP mode without P2P
- connectType differences: 63 (LAN), 126 (cloud), 123 (relay)

**Fix**: For AP mode, try direct HTTP instead of P2P:
```dart
// In AP mode, try HTTP directly
final response = await http.get(Uri.parse(
  'http://192.168.168.1:81/livestream.cgi?loginuse=admin&loginpas=888888&streamid=10&substream=2'
));
```

### Issue 18: serviceParam Must Match Device Prefix (NEW)

**Cause**: When fetching initstring from cloud, must use correct device ID prefix

**Evidence**:
- `authentication.eye4.cn/getInitstring` requires UID prefix
- Virtual ID (OKB) vs Real ID (VSTH) have different prefixes
- Using wrong prefix returns wrong serviceParam

**Fix**: Extract correct prefix from device ID:
```dart
// Get first 4 chars of device ID
String prefix = deviceId.substring(0, 4); // e.g., "OKB0" or "VSTH"
// Use in getInitstring request
body: jsonEncode({"uid": [prefix]})
```

---

## Part 4: Action Plan (Updated with Travel Shoot Insights)

### Step 1: Test HTTP Access (IMMEDIATE)

1. Connect phone to camera's AP WiFi (@MC-0379196)
2. Open Safari
3. Go to: `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888`
4. **Expected**: Camera status data (confirms password works)
5. **If fails**: Try `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=admin`
6. **Also try**: Empty password `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=`

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
4. Connect directly with our app using `888888`

### Step 4: Fix connectType for Virtual IDs (NEW)

```dart
// For virtual IDs (OKB prefix) - use cloud assist:
connectType = 126;

// For direct LAN/AP mode:
connectType = 63;
```

### Step 5: Use CameraDevice Class with Proper Flow

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
  // Wait for startStream to complete (handles CMD 24631 internally)
  await device.startStream(resolution: VideoResolution.general);
  // THEN start player
  player.start();
}
```

### Step 6: Verify Command Listener Timing (NEW)

Ensure listener is registered BEFORE login:
```dart
// 1. Create client
final clientPtr = await AppP2PApi().clientCreate(id);

// 2. Set up command listener IMMEDIATELY
AppP2PApi().setCommandListener(clientPtr, (cmd, content) {
  if (cmd == 24577) {
    // Parse login response
    print('Login result: ${content['result']}');
  }
  if (cmd == 24631) {
    // Livestream acknowledged - NOW start player
    print('Stream ready');
  }
});

// 3. Connect
await AppP2PApi().clientConnect(clientPtr, ...);

// 4. Login
await AppP2PApi().clientLogin(clientPtr, 'admin', '888888');
```

### Step 7: Compare SDK Files

```bash
# Compare original vs our copy
diff /Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/camera_device/camera_device.dart \
     /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk/camera_device/camera_device.dart
```

### Step 8: Test Empty Password (If All Else Fails)

Temporarily modify `app_p2p_api.dart` to allow empty passwords:
```dart
// Remove or comment out password validation
// Then test with empty string
await AppP2PApi().clientLogin(clientPtr, 'admin', '');
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

## Part 12: Systematic Troubleshooting Framework (Travel Shoot Allegory)

This framework provides a systematic approach to debugging, treating each phase as a "scene" in a documentary shoot.

### Act 1: The Passport Office (Credentials + IDs)

**Goal**: Validate traveler identity (real device ID + password)

**Shot List**:
1. Try password `888888` explicitly (official default)
2. Try empty password by temporarily allowing blank in `clientLogin`
3. Retrieve actual password from QR provisioning if device has per-device password
4. Use real device ID (VSTH) instead of virtual ID (OKB) when possible

### Act 2: The Ferry (P2P Tunnel)

**Goal**: Establish P2P tunnel in correct mode for the ID type

**Shot List**:
1. Switch video `connectType` to 126 for virtual IDs
2. Log `clientCheckMode()` to verify P2P vs relay mode
3. Ensure internet connectivity for cloud-assisted connections

### Act 3: Customs (Authentication Confirmation)

**Goal**: Confirm CMD 24577 `result=0` before proceeding

**Shot List**:
1. Register command listener BEFORE login
2. Parse CMD 24577 and log: `result`, `realdeviceid`, `pwdfactory`
3. Only proceed to streaming if `result=0`

### Act 4: The Dock (Livestream Start)

**Goal**: Receive CMD 24631 before starting player

**Shot List**:
1. Call `startStream()` which waits for 24631 internally
2. If 24631 never arrives, try different `substream` values: 1, 2, 4, 100
3. Only start player AFTER 24631 confirmed

### Act 5: The Camera Rig (Playback Binding)

**Goal**: Verify player is bound correctly and receiving frames

**Shot List**:
1. Use `screenshot()` to confirm frames even if texture appears black
2. Log progress/head info callbacks
3. Verify correct `clientPtr` is bound to player

### Act 6: The Producer Notes (Cloud + Vendor Reality)

**Goal**: Handle cloud requirements for virtual IDs

**Shot List**:
1. Ensure device AND phone have internet during connect
2. Cache initstring only after successful cloud resolution
3. Still use cloud mode (126) for OKB virtual IDs

---

## Part 13: Official Documentation Contradictions

| Topic | Vendor Feedback | Official Docs | Resolution |
|-------|----------------|---------------|------------|
| Default password | "No default passwords" | "Factory default is 888888" | Use `888888` first |
| Auth restrictions | "No auth restrictions" | Login errors via result codes | Password errors are real |
| Empty password | Not mentioned | CGI allows `loginpas=` | SDK rejects but may work via CGI |

---

## Part 14: Updated Troubleshooting Checklist

### Pre-Connection
- [ ] Using password `888888` (not `admin`)?
- [ ] Using real device ID (VSTH) or properly resolved virtual ID?
- [ ] Correct connectType (126 for virtual, 63 for LAN)?
- [ ] Phone connected to camera's WiFi or same network?
- [ ] Internet available for cloud-assisted connections?

### Connection
- [ ] P2P connect succeeds? (`CONNECT_STATUS_ONLINE`)
- [ ] Command listener registered BEFORE login?
- [ ] Login sent with correct credentials?
- [ ] CMD 24577 received with `result=0`?

### Video Streaming
- [ ] `startStream()` called (not raw CGI)?
- [ ] CMD 24631 received before player start?
- [ ] Player created with correct texture binding?
- [ ] Frames arriving? (check with screenshot)

---

## Part 15: Issue Summary Table (All 18 Issues)

| # | Issue | Probability | Effort | Priority |
|---|-------|-------------|--------|----------|
| 1 | Wrong Password (888888 vs admin) | **HIGH** | Low | 1 |
| 2 | Password Changed by Eye4 App | Medium | Medium | 2 |
| 3 | SDK Files Modified | Low | High | 8 |
| 4 | Command Listener Timing | Medium | Low | 3 |
| 5 | Not Using CameraDevice Class | Medium | Medium | 4 |
| 6 | Virtual ID vs Real ID | Medium | Low | 5 |
| 7 | Wrong connectType (63 vs 126) | **HIGH** | Low | 1 |
| 8 | Empty Password Rejection | Low | Low | 9 |
| 9 | Livestream Flow Order Wrong | Medium | Low | 6 |
| 10 | Per-Device Password | Low | Medium | 10 |
| 11 | Video Without Login | Medium | Low | 3 |
| 12 | Camera Wake-Up State | Low | Low | 11 |
| 13 | Yellow LED Not Ready | Low | Low | 12 |
| 14 | LiveVideoSource Binding | Medium | Medium | 7 |
| 15 | Missing Pre-Login CGI | Low | Medium | 13 |
| 16 | Duplicate Login Intentional | Low | Low | 14 |
| 17 | AP Mode vs Cloud Auth | Low | Medium | 15 |
| 18 | serviceParam Prefix Mismatch | Low | Low | 16 |

---

## Part 16: Recommended Experiment Order

### Phase 1: Quick Wins (Try First)
1. **Change password to `888888`** - Single line change, highest probability
2. **Change connectType to `126`** - Single line change, high probability
3. **Try video WITHOUT login** - Test vendor claim about direct streaming

### Phase 2: Configuration Fixes
4. **Set command listener BEFORE login** - Timing fix
5. **Use CameraDevice class** - Proper SDK usage
6. **Use real device ID (VSTH)** - Avoid virtual ID issues

### Phase 3: Flow Order Fixes
7. **Wait for CMD 24631 before player** - Proper streaming sequence
8. **Try duplicate login call** - Match SDK behavior
9. **Send get_status.cgi before login** - Handshake command

### Phase 4: Hardware/Reset Actions
10. **Factory reset camera** - 10+ seconds, no Eye4 reconnection
11. **Test HTTP in AP mode** - Bypass P2P entirely
12. **Check camera LED state** - Wait for ready state

---

## Part 17: Quick Test Script

```dart
// COMPREHENSIVE TEST - Try all high-priority fixes at once
Future<void> testWithAllFixes() async {
  final cameraUID = 'OKB0379196OXYB';

  // 1. Use CameraDevice with CORRECT password and listeners
  CameraDevice device = CameraDevice(
    cameraUID,
    'TestCamera',
    'admin',      // Username (fixed)
    '888888',     // Password (factory default!)
    'QW6-T'
  );

  // 2. Set up listeners BEFORE connecting
  device.addListener<CameraConnectChanged>((dev, state) {
    print('Connect state: $state');
  });
  device.addListener<StatusChanged>((dev, status) {
    print('Status: ${status.result}'); // Check for result=0
  });

  // 3. Connect (uses proper connectType internally)
  var state = await device.connect();
  print('Final state: $state');

  if (state == CameraConnectState.connected) {
    // 4. Start stream (waits for CMD 24631 internally)
    await device.startStream(resolution: VideoResolution.general);

    // 5. Create and bind player
    var player = AppPlayerController();
    await player.create();
    await player.setVideoSource(LiveVideoSource(device.clientPtr!));
    await player.start();

    print('Streaming should now work!');
  } else if (state == CameraConnectState.password) {
    print('Password error - try factory reset');
  }
}
```

---

## Documents Reviewed for This Analysis

| Document | Key Contribution |
|----------|-----------------|
| CAMERA_CONNECTION_ANALYSIS.md | AP mode details, offline test results |
| DEEP_DIVE_TROUBLESHOOTING.md | Video without login hypothesis |
| VIDEO_STREAMING_TROUBLESHOOTING.md | result=-1 analysis, CMD 24577 |
| VIDEO_STREAMING_ANALYSIS_V2.md | connectType 126 vs 63 |
| SDK_DEEP_ANALYSIS_v2.md | Password 888888 discovery |
| flutter_sdk_parameter_usage_instructions.md | Official password confirmation |
| 02_Function_Command_Documentation.md | Wake-up state, CGI commands |
| STREAMING_TROUBLESHOOT_TRAVEL_SHOOT.md | Travel Shoot framework |

---

*Document compiled from official Veepa documentation, SDK analysis, vendor feedback, Travel Shoot troubleshooting framework, and comprehensive review of all project documentation (January 17, 2026).*
