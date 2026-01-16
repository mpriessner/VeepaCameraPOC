# Video Streaming Troubleshooting Log

**Document**: VS-004 Debugging Log
**Created**: January 16, 2026
**Status**: In Progress - Seeking Solutions

---

## Current Problem

**Video player connects but shows no video frames.**

The P2P connection works, login succeeds, player is created, but no video data is received by the player. The Texture widget shows black screen.

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
| Camera Login | ✓ | Returns true with admin/admin |
| Player Creation | ✓ | Returns true, textureId = 0 |
| Video Source Set | ✓ | LiveVideoSource(clientPtr) returns true |
| Livestream CGI | ✓ | Returns true |
| Player Start | ✓ | Returns true |
| Voice Start | ✓ | Returns true |

## What Doesn't Work ✗

| Issue | Observation |
|-------|-------------|
| Video frames | No `_onVideoProgress` callbacks received |
| Head info | No `_onHeadInfo` callbacks received |
| VideoStatus | Stays at initial state, never changes to PLAY |
| Texture display | Shows black (no video data) |

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

1. **Wait for command result 24631** after CGI
2. **Try CameraDevice with pre-set credentials** (if possible)
3. **Check SDK demo's exact initialization sequence**
4. **Try different streamid values** (1, 7, 10, 16)
5. **Add native-level debugging** if possible

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

*Last updated: January 16, 2026*
