# SDK Deep Analysis v2 - Critical Findings

**Date**: January 17, 2026
**Status**: CRITICAL DISCOVERIES - Action Required

---

## CRITICAL FINDING #1: Wrong Default Password!

### We've Been Using the Wrong Password!

| What We Used | What The SDK Uses |
|--------------|-------------------|
| `admin` | `888888` |

**Evidence from original SDK demo app:**

```dart
// device.dart line 14:
Future<bool> init(String did, {String psw = "888888", ...})

// main_state.dart line 9:
String psw = "888888";

// main_logic.dart line 26:
state!.psw = "888888";

// status_command.dart line 512:
if (password == "888888") return "初始密码";  // "Initial password"

// p2p_device.dart line 285 (HTTP direct access):
"http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888"
```

### The Fix
Change password from `admin` to `888888` in all connection attempts!

---

## CRITICAL FINDING #2: Direct HTTP Access Works!

When connected to camera's AP WiFi, you can bypass P2P entirely:

```
URL: http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888
```

This is used by the SDK's `checkDeviceAp()` function to verify camera identity.

### Test This Immediately
1. Connect phone to camera's AP WiFi (@MC-0379196)
2. Open Safari
3. Go to: `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888`
4. If you see camera status data, the password `888888` works!

---

## CRITICAL FINDING #3: SDK Files Differ

Our repo has **modified versions** of the SDK files. These files differ from the original:

| File | Status |
|------|--------|
| `app_p2p_api.dart` | MODIFIED |
| `app_player.dart` | MODIFIED |
| `camera_device.dart` | MODIFIED |
| `status_command.dart` | MODIFIED |
| `video_command.dart` | MODIFIED |
| `p2p_device.dart` | MODIFIED |

**Risk**: We may have introduced bugs or broken functionality.

### Recommendation
Consider syncing our SDK files with the original or carefully reviewing the differences.

---

## CRITICAL FINDING #4: Login is Called Twice (Intentional)

In `status_command.dart` lines 528-529:

```dart
AppP2PApi().clientLogin(clientPtr!, username, password);  // Fire and forget
bool ret = await AppP2PApi().clientLogin(clientPtr!, username, password);  // Await result
```

This is NOT a bug - it's intentional. The first call initiates, the second waits for response.

---

## CRITICAL FINDING #5: Vendor Claim Explained

> "There are no default passwords and authentication restrictions"

**This is TRUE because:**
- Every camera may have a unique factory password
- But the SDK demo uses `888888` as the standard default
- The vendor may mean there's no GLOBAL default - each camera line may differ

> "The SDK allows video data to be streamed directly"

**This is TRUE because:**
- In AP mode, you can potentially stream without P2P login
- Direct CGI commands work via HTTP
- The SDK can capture video frames directly from the player

---

## Connection Types Reference

| Code | Hex | Name | Use Case |
|------|-----|------|----------|
| 126 | 0x7E | P2P Direct | Default - direct connection |
| 123 | 0x7B | Relay | Through cloud relay servers |
| 63 | 0x3F | AP Mode | Camera's WiFi hotspot |
| 121 | 0x79 | Socket | Offline detection only |

---

## Demo App Flow (What Works)

```dart
// 1. Create device with CORRECT password
CameraDevice device = CameraDevice(did, name, 'admin', '888888', 'QW6-T');

// 2. Add listeners BEFORE connecting
device.addListener<StatusChanged>(statusListener);
device.addListener<CameraConnectChanged>(_connectStateListener);
device.addListener<WakeupStateChanged>(_wakeupStateListener);

// 3. Connect
CameraConnectState connectState = await device.connect();

// 4. If connected, get params
if (connectState == CameraConnectState.connected) {
  var result = await device.getParams(cache: false);
}

// 5. Start video
var videoSource = LiveVideoSource(device.clientPtr!);
await controller.setVideoSource(videoSource);
await device.startStream(resolution: VideoResolution.general);
await controller.start();
```

---

## Experiments to Try (Priority Order)

### Experiment 1: Test Password via HTTP (HIGHEST PRIORITY)
```
1. Connect to camera's AP WiFi
2. Open Safari: http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888
3. Does it return camera data?
```

### Experiment 2: Use Password `888888`
```dart
// Change in your connection code:
await AppP2PApi().clientLogin(clientPtr, 'admin', '888888');
```

### Experiment 3: Use CameraDevice Class Properly
```dart
// Instead of raw AppP2PApi calls:
CameraDevice device = CameraDevice(cameraUID, 'Test', 'admin', '888888', 'QW6-T');
await device.connect();
await device.startStream(resolution: VideoResolution.general);
```

### Experiment 4: Compare SDK Files
```bash
diff -r /Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib \
        /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/sdk
```

---

## Files to Compare

| Original SDK | Our Copy |
|--------------|----------|
| `/Veepaisdk/flutter-sdk-demo/lib/app_p2p_api.dart` | `lib/sdk/app_p2p_api.dart` |
| `/Veepaisdk/flutter-sdk-demo/lib/camera_device/camera_device.dart` | `lib/sdk/camera_device/camera_device.dart` |
| `/Veepaisdk/flutter-sdk-demo/lib/camera_device/commands/status_command.dart` | `lib/sdk/camera_device/commands/status_command.dart` |

---

## Password History

| Source | Password Used |
|--------|---------------|
| Our POC app | `admin` (WRONG) |
| SDK Demo app | `888888` (CORRECT) |
| HTTP CGI | `loginpas=888888` |
| SDK documentation | "初始密码" = Initial password = `888888` |

---

## Quick Action Items

1. [ ] **Test HTTP access**: `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888`
2. [ ] **Change password to `888888`** in all connection code
3. [ ] **Compare SDK files** for differences
4. [ ] **Test using CameraDevice class** instead of raw AppP2PApi
5. [ ] **Check if video streams** after password fix

---

## Summary

**The main problem is likely the wrong password!**

We've been using `admin` but the SDK uses `888888` as the default factory password.

Test this immediately by:
1. Connecting to camera's AP WiFi
2. Accessing `http://192.168.168.1:81/get_status.cgi?loginuse=admin&loginpas=888888` in Safari
3. If it works, update all code to use `888888`
