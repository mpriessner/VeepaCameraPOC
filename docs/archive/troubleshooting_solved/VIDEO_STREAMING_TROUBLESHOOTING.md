# Video Streaming Troubleshooting Log

**Document**: VS-004 Debugging Log
**Created**: January 16, 2026
**Last Updated**: January 16, 2026 18:15
**Status**: ROOT CAUSE IDENTIFIED - Password Authentication Failure

---

## CRITICAL FINDING (Latest)

**The camera is rejecting the password!**

The CMD 24577 (STATUS) response shows:
```
result=-1;vuid=OKB0379196OXYB;realdeviceid=OKB0379196OXYB;pwdfactory=1;
```

In the SDK code (`camera_device.dart:330-335`):
```dart
if (result.result == "-1" || result.result == "-2" || result.result == "-3") {
  connectState = CameraConnectState.password;  // PASSWORD ERROR!
}
```

**`result=-1` means the password is WRONG**, even though:
- `pwdfactory=1` suggests factory password mode is enabled
- We're using `admin/admin` which should be the factory default
- The low-level `clientLogin()` API returns `true`

This explains why:
- No `CMD 24631 (LIVESTREAM)` response is received
- No video frames are delivered
- The camera appears connected but won't stream

---

## Current Problem

**Video player connects but shows no video frames.**

The P2P connection works, the low-level login API returns true, but the camera's STATUS response shows `result=-1` (password error). No video data is received.

### Environment
- Camera: Veepa IP Camera (UID: OKB0379196OXYB)
- Connection: Direct WiFi to camera (no internet)
- Camera LED: Constant yellow (during connection)
- Device: Physical iPhone (arm64)

---

## What Works ✓

| Step | Status | Evidence |
|------|--------|----------|
| P2P Client Creation | ✓ | clientPtr is valid (large number) |
| P2P Connection (LAN mode) | ✓ | Returns CONNECT_STATUS_ONLINE |
| Login API Call | ✓ | `clientLogin()` returns true (request sent) |
| Command Listener | ✓ | Receiving CMD 24577 responses |
| Player Creation | ✓ | Returns true, textureId = 0 |
| Video Source Set | ✓ | LiveVideoSource(clientPtr) returns true |
| Livestream CGI Send | ✓ | Returns true (request sent) |
| Player Start | ✓ | Returns true |

## What Doesn't Work ✗

| Issue | Observation | Root Cause |
|-------|-------------|------------|
| **Password Auth** | `result=-1` in CMD 24577 | **Camera rejecting password** |
| Livestream Response | No CMD 24631 received | Camera won't stream without auth |
| Video frames | No `_onVideoProgress` callbacks | No stream = no frames |
| Head info | No `_onHeadInfo` callbacks | No stream = no metadata |
| VideoStatus | Never changes to PLAY | Player has no data to play |
| Texture display | Shows black | No video data received |

## Key Insight

**The low-level `clientLogin()` API returning `true` only means the request was SENT, not that authentication SUCCEEDED.** The actual auth result comes in the CMD 24577 response's `result` field. We were not checking this properly.

---

## Approaches Tried

### Approach 1: CameraDevice Class (Failed)
```dart
_cameraDevice = CameraDevice(_cameraUID, 'VideoCamera', user, pass, 'QW6-T');
_cameraDevice!.connectType = 63;
await _cameraDevice!.connect(lanScan: true);
```
**Result**: Connection failed - CameraDevice needs internet to resolve virtual UID to real clientId via API call.

### Approach 2: Low-Level P2P API with Cached Credentials (Partial Success)
```dart
// Use pre-cached credentials (fetched when internet was available)
final clientPtr = await AppP2PApi().clientCreate(credentials.clientId);
await AppP2PApi().clientConnect(clientPtr, true, credentials.serviceParam, connectType: 63);
await AppP2PApi().clientLogin(clientPtr, 'admin', 'admin');

// Create player
_playerController = AppPlayerController(changeCallback: ...);
await _playerController!.create();

// Set video source
final videoSource = LiveVideoSource(clientPtr);
await _playerController!.setVideoSource(videoSource);

// Send livestream command
await AppP2PApi().clientWriteCgi(clientPtr, 'livestream.cgi?streamid=10&substream=2&');

// Start player
await _playerController!.start();
```
**Result**: All steps return success, but no video frames received.

### Approach 3: Reordered Sequence (No Change)
- Start player BEFORE sending CGI
- Add callbacks before starting
- Add startVoice() call
- Add delays between steps

**Result**: Same - no frames received.

### Approach 4: Different CGI Parameters (Not Yet Tried)
Possible variations:
- `streamid=10` vs other values
- `substream=1` (high) vs `substream=2` (general) vs `substream=4` (low)

---

## Current Code Flow

```
1. Load cached credentials (clientId, serviceParam)
2. AppP2PApi().clientCreate(clientId) → clientPtr
3. AppP2PApi().clientConnect(clientPtr, lanScan=true, serviceParam, connectType=63)
4. AppP2PApi().clientLogin(clientPtr, 'admin', 'admin')
5. AppPlayerController.create() → textureId=0
6. LiveVideoSource(clientPtr) → setVideoSource()
7. AppPlayerController.start()
8. AppP2PApi().clientWriteCgi('livestream.cgi?streamid=10&substream=2&')
9. AppPlayerController.startVoice()
10. Wait for frames... (none arrive)
```

---

## Hypotheses

### H1: Data Channel Not Established
The low-level P2P API might only set up command channels. CameraDevice might do additional setup for video data channels that we're missing.

### H2: LiveVideoSource Binding Issue
`LiveVideoSource(clientPtr)` might expect a clientPtr from a fully-initialized CameraDevice, not from raw P2P API. The native layer might check for specific state.

### H3: CGI Command Not Correct
The livestream CGI might need different parameters, or the camera might need additional commands to start streaming.

### H4: Camera State Issue
Yellow LED might indicate camera is not ready to stream. Might need to send wake-up command or wait for specific state.

### H5: Native Callback Registration
The native layer might need explicit callback registration for video data that CameraDevice handles but we're not doing.

---

## SDK Code References

### Livestream CGI (from video_command.dart:55-74)
```dart
Future<bool> startStream({required VideoResolution resolution}) async {
  int index = resolution.index;
  if (resolution == VideoResolution.superHD) {
    index = 100;
  }
  bool ret = await writeCgi("livestream.cgi?streamid=10&substream=$index&");
  if (ret == true) {
    waitCommandResult((cmd, data) {
      return cmd == 24631;
    }, 3).then((result) {
      ret = result?.isSuccess ?? false;
    });
  }
  return ret;
}
```

### Video Resolution Mapping
| Resolution | Index | Typical Size |
|------------|-------|--------------|
| high | 1 | ~1080p |
| general | 2 | ~720p |
| low | 4 | ~480p |
| superHD | 100 | ~4K |

---

## Questions for Investigation

1. **What does CameraDevice.connect() do differently?** Does it set up video data channels?

2. **Is there a native callback registration we're missing?** Check if CameraDevice registers video callbacks.

3. **What does the yellow LED indicate?** Is the camera in a ready state?

4. **Should we wait for command result 24631?** The SDK waits for this after sending livestream CGI.

5. **Is there a different initialization sequence in the SDK demo?** Check play_logic.dart more carefully.

---

## Next Steps to Try

### Priority 1: Fix Password Issue
1. **Perform full factory reset** - Hold reset button 10+ seconds until voice prompt
2. **Use Eye4 app** to change password to a known value
3. **Try different default passwords** - some cameras use blank password or "888888"
4. **Verify with "Full SDK" button** - if CameraDevice also fails, confirms password issue

### Priority 2: If Password Is Fixed
1. **Wait for command result 24631** after CGI
2. **Try CameraDevice with pre-set credentials** (if possible)
3. **Check SDK demo's exact initialization sequence**
4. **Try different streamid values** (1, 7, 10, 16)

### Understanding the Login Flow
The SDK's login process:
1. `AppP2PApi().clientLogin()` - sends login request (returns true if sent)
2. Wait for `CMD 24577` response - contains actual result
3. Check `result` field:
   - `result=0` = SUCCESS
   - `result=-1` = Wrong password
   - `result=-2` = Wrong username
   - `result=-3` = Auth error
   - `result=-4` = Illegal/banned

Our code calls `clientLogin()` which returns `true` (request sent), but we weren't checking the actual response. The camera responds with `result=-1` = password wrong.

---

## File Locations

| File | Purpose |
|------|---------|
| `lib/screens/p2p_test_screen.dart` | Test screen with video player |
| `lib/sdk/app_player.dart` | AppPlayerController class |
| `lib/sdk/app_p2p_api.dart` | Low-level P2P API |
| `lib/sdk/camera_device/camera_device.dart` | High-level CameraDevice |
| `lib/sdk/camera_device/commands/video_command.dart` | Video streaming commands |

---

## Raw Debug Output

### After Connect Button:
```
[18:08:50] === CONNECTED ===
[18:08:50] clientPtr: 4844126980
[18:08:50] textureId: 0
[18:08:50] Ready to stream video!
[18:08:51] >>> CMD 24577 (STATUS): result=-1;vuid=OKB0379196OXYB;realdeviceid=OKB0379196OXYB;pwdfactory=1;
```

### After Start Video Button:
```
[18:09:05] === STREAMING ===
[18:09:05] textureId: 0
[18:09:05] Frames should appear below...
[18:09:07] >>> CMD 24577 (STATUS): result=-1;vuid=OKB0379196OXYB;realdeviceid=OKB0379196OXYB;pwdfactory=1;
```

**Notable:**
- `result=-1` = Password authentication failed
- `pwdfactory=1` = Factory password mode enabled (but still failing)
- No `CMD 24631 (LIVESTREAM)` = Camera never acknowledged stream request
- No `>>> FRAME` entries = No video data received

---

## Password Issue Analysis

### Why `pwdfactory=1` but `result=-1`?

Possible explanations:
1. **Camera not fully factory reset** - Needs 10+ second reset hold
2. **Different default password** - Some models use blank or "888888"
3. **Camera was cloud-paired** - Eye4 may have set a different password
4. **Password cached in camera** - Previous setup still active

### Solutions (in order of preference)

1. **Full Factory Reset**
   - Disconnect power
   - Hold reset button while powering on
   - Keep holding 10+ seconds until voice prompt
   - Camera should announce "Reset successful" or similar

2. **Use Eye4 App to Set Known Password**
   - Connect phone to camera's WiFi hotspot
   - Open Eye4 app and add camera
   - Go to device settings → Security → Change Password
   - Set to "admin" or another known value

3. **Try Alternative Default Passwords**
   - Empty password (just press login)
   - "888888"
   - "123456"
   - Last 6 digits of camera serial number

4. **Capture Password from Eye4 App**
   - Use Wireshark/Proxyman while changing password
   - Decode the P2P command to learn the format
   - Send same command from our app

---

*Last updated: January 16, 2026 18:15*
