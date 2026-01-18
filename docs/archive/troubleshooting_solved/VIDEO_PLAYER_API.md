# Veepa SDK Video Player API - Technical Summary

**Document ID**: VS-001 Deliverable
**Created**: January 16, 2026
**Status**: Complete

---

## Executive Summary

The Veepa SDK provides a complete video streaming solution through `AppPlayerController`. **Raw frame access for Gemini integration IS possible** via the `screenshot()` method, which saves frames to files that can be read and converted to Base64.

### Key Findings at a Glance

| Aspect | Finding | Impact |
|--------|---------|--------|
| **Raw Frame Access** | ✅ Via `screenshot(filePath)` | Gemini integration feasible |
| **Native Library** | arm64 only | Device-only testing (no simulator) |
| **Rendering** | Flutter Texture widget | Standard Flutter approach |
| **Cleanup** | `dispose()` method | Must call to prevent memory leaks |

---

## 1. Native Library Architecture

```bash
$ lipo -info libVSTC.a
Non-fat file: libVSTC.a is architecture: arm64
```

**Implications**:
- ❌ No simulator testing possible
- ✅ Physical iPhone required for all testing
- ✅ arm64 is native for modern iPhones (good performance)

---

## 2. Video Player API Overview

### Core Class: `AppPlayerController`

Located at: `lib/sdk/app_player.dart`

### Creation Pattern

```dart
// 1. Create controller with state change callback
AppPlayerController controller = AppPlayerController(
  changeCallback: (userData, videoStatus, voiceStatus, recordStatus, touchType) {
    // Handle state changes
  }
);

// 2. Create the player (async, returns textureId)
bool success = await controller.create();
// controller.textureId is now set

// 3. Use textureId with Flutter's Texture widget
Texture(textureId: controller.textureId)
```

### Video Source Types

| Source Type | Class | Use Case |
|-------------|-------|----------|
| **Live Stream** | `LiveVideoSource(clientPtr)` | Real-time camera feed ✅ **OUR USE CASE** |
| File Playback | `FileVideoSource(filePath)` | Playing recorded videos |
| TF Card | `CardVideoSource(clientPtr, size)` | Playback from camera SD card |
| Network | `NetworkVideoSource(urls)` | Streaming from URLs |
| Phone Camera | `CameraVideoSource(clientPtr, dir, frameRate)` | Phone's own camera |

### Key Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `create()` | `{int audioRate = 8000}` | `Future<bool>` | Creates player, sets `textureId` |
| `setVideoSource()` | `VideoSource source` | `Future<bool>` | Sets the video source |
| `start()` | - | `Future<bool>` | Starts playback |
| `stop()` | - | `Future<bool>` | Stops playback |
| `pause()` | - | `Future<bool>` | Pauses playback |
| `resume()` | - | `Future<bool>` | Resumes playback |
| `startVoice()` | - | `Future<bool>` | Enables audio |
| `stopVoice()` | - | `Future<bool>` | Disables audio |
| **`screenshot()`** | `String filePath, {...}` | `Future<bool>` | **Captures frame to file** |
| `dispose()` | - | `void` | **MUST call to cleanup** |

### Screenshot Method (Key for Gemini)

```dart
Future<bool> screenshot(
  String filePath, {
  String imageSize = "0",      // e.g., "1280x720" or "0" for original
  double widthPercent = 0,     // Crop percentage
  double heightPercent = 0,    // Crop percentage
  int sub = 0                  // Sub-player index
})
```

---

## 3. Video Resolution Options

| Resolution | Enum Value | Index | Typical Size |
|------------|------------|-------|--------------|
| Low | `VideoResolution.low` | 4 | ~480p |
| General | `VideoResolution.general` | 2 | ~720p (default) |
| High | `VideoResolution.high` | 1 | ~1080p |
| Super HD | `VideoResolution.superHD` | 100 | ~4K |

### Changing Resolution

```dart
// On camera side
await device.startStream(resolution: VideoResolution.high);

// Or change during stream
await device.changeResolution(VideoResolution.low);
```

---

## 4. Frame Access for Gemini (PRIORITY #1)

### Answer: Yes, raw frame access IS possible

**Method**: Use `screenshot()` to save frame to file, then read and encode.

### Implementation Pattern

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> captureFrameAsBase64() async {
  // 1. Get a temp file path
  final directory = await getTemporaryDirectory();
  final filePath = '${directory.path}/frame_capture.jpg';

  // 2. Capture frame to file
  bool success = await controller.screenshot(filePath);
  if (!success) return null;

  // 3. Read file bytes
  final file = File(filePath);
  final bytes = await file.readAsBytes();

  // 4. Encode to Base64
  final base64String = base64Encode(bytes);

  // 5. Clean up temp file (optional)
  await file.delete();

  return base64String;
}
```

### Performance Considerations

- Screenshot captures current rendered frame
- File I/O adds ~10-50ms latency
- Consider running encoding in Isolate for UI smoothness
- Resize before encoding for faster Gemini API calls

---

## 5. Callbacks and Events

### Available Callbacks

```dart
// 1. State Change Callback (set in constructor)
StateChangeCallback<T?> changeCallback = (
  userData,
  VideoStatus videoStatus,   // STOP, STARTING, PLAY, PAUSE
  VoiceStatus voiceStatus,   // PLAY, STOP
  RecordStatus recordStatus, // PLAY, STOP
  SoundTouchType touchType
) { ... };

// 2. Progress Callback
controller.addProgressChangeCallback((
  userData,
  int totalSec,      // Total duration
  int playSec,       // Current position
  int progress,      // Progress percentage
  int loadState,     // Loading state
  int velocity,      // Bitrate/speed
  int timestamp      // Frame timestamp
) { ... });

// 3. Video Head Info Callback
controller.addHeadInfoCallback((
  userData,
  int resolution,    // Resolution index
  int channel,       // Channel number
  int type          // Video type
) { ... });
```

### Video Status Values

```dart
enum VideoStatus {
  STOP,      // Not playing
  STARTING,  // Initializing
  PLAY,      // Playing
  PAUSE      // Paused
}
```

---

## 6. Threading Model

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter UI Thread                        │
│  ┌─────────────────┐    ┌─────────────────────────────┐     │
│  │ AppPlayerView   │    │ AppPlayerController         │     │
│  │ (Texture widget)│    │ (Dart API)                  │     │
│  └────────┬────────┘    └──────────┬──────────────────┘     │
│           │                        │                         │
│           │ textureId              │ MethodChannel           │
│           │                        │ FFI Calls               │
├───────────┼────────────────────────┼─────────────────────────┤
│           │                        │                         │
│  ┌────────▼────────────────────────▼──────────────────┐     │
│  │              Native Layer (libVSTC.a)               │     │
│  │  - Video decoding                                   │     │
│  │  - Texture rendering                                │     │
│  │  - P2P data handling                                │     │
│  └─────────────────────────────────────────────────────┘     │
│                     Native Threads                           │
└─────────────────────────────────────────────────────────────┘
```

### Key Points

- Dart API is async (non-blocking)
- Callbacks delivered via `ReceivePort` (isolate-safe)
- Video decoding happens on native threads
- Texture updates directly on GPU (efficient)

---

## 7. Complete Live Streaming Flow

### Step-by-Step Implementation

```dart
// Prerequisites: P2P connection established, device.clientPtr available

// Step 1: Create controller
AppPlayerController controller = AppPlayerController(
  changeCallback: _onStateChange
);

// Step 2: Create player (async)
bool created = await controller.create();
if (!created) {
  print('Failed to create player');
  return;
}
print('Player created, textureId: ${controller.textureId}');

// Step 3: Set video source
LiveVideoSource source = LiveVideoSource(device.clientPtr!);
bool sourceSet = await controller.setVideoSource(source);
if (!sourceSet) {
  print('Failed to set video source');
  return;
}

// Step 4: Tell camera to start streaming
await device.startStream(resolution: VideoResolution.general);

// Step 5: Start the player
bool started = await controller.start();
print('Player started: $started');

// Step 6: Add progress callback for monitoring
controller.addProgressChangeCallback(_onProgress);

// Step 7: Display in UI
// In build():
return AspectRatio(
  aspectRatio: 16/9,
  child: controller.isCreated
    ? Texture(textureId: controller.textureId)
    : Container(color: Colors.black, child: Text('Loading...')),
);
```

### Cleanup (CRITICAL)

```dart
@override
void dispose() {
  // Remove callbacks
  controller.removeProgressChangeCallback(_onProgress);

  // Stop and dispose player
  controller.dispose();  // This calls stop() internally

  super.dispose();
}
```

---

## 8. Pre-built Widget: `AppPlayerView`

The SDK provides a ready-to-use widget:

```dart
class AppPlayerView extends StatelessWidget {
  const AppPlayerView({Key? key, required this.controller}) : super(key: key);
  final AppPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      if (controller.isCreated == false) {
        return FutureBuilder(
          builder: (context, asyncSnapshot) {
            if (asyncSnapshot.connectionState == ConnectionState.done) {
              if (asyncSnapshot.data == true) {
                return Container(
                  color: Colors.black,
                  child: Texture(textureId: controller.textureId),
                );
              }
            }
            return Container();
          },
          future: controller.create(),
        );
      }
      return Container(
        color: Colors.black,
        child: Texture(textureId: controller.textureId),
      );
    });
  }
}
```

**Usage**:
```dart
AppPlayerView(controller: controller)
```

---

## 9. Limitations and Concerns

### Known Limitations

1. **Device-Only Testing**: arm64 library means no simulator support
2. **No Direct Frame Callback**: Must use `screenshot()` for frame access
3. **File I/O for Screenshots**: Adds latency vs. direct memory access

### Potential Issues

| Issue | Mitigation |
|-------|------------|
| Memory leaks | Always call `dispose()` |
| UI jank during screenshot | Run encoding in Isolate |
| Stale texture | Check `isCreated` before rendering |
| Connection drops | Handle in state callback |

---

## 10. Files Already in Our POC

Our `lib/sdk/` already contains the necessary SDK files:

- `app_player.dart` - Main player controller
- `app_dart.dart` - Native callback bridge
- `camera_player.dart` - High-level player wrapper
- `camera_device/commands/video_command.dart` - Video control commands

**No additional SDK files needed.**

---

## 11. Implementation Recommendations

### For VS-002 (Add Video Player Widget)
- Use `AspectRatio(aspectRatio: 16/9)` container
- Show placeholder until `controller.isCreated`
- Add state-based UI (Connecting, Streaming, Error)

### For VS-003 (Initialize Video Player)
- Create controller in state
- Call `create()` after P2P connection succeeds
- Store `device.clientPtr` from successful login

### For VS-004 (Display Live Video)
- Use `Texture(textureId: controller.textureId)`
- Call `device.startStream()` before `controller.start()`
- Add progress callback for frame rate monitoring

### For VS-006 (Screenshot)
- Use `controller.screenshot(filePath)`
- Read file, encode Base64
- Delete temp file after use

---

## Appendix: Code Location Reference

| Component | Path |
|-----------|------|
| AppPlayerController | `lib/sdk/app_player.dart:180` |
| LiveVideoSource | `lib/sdk/app_player.dart:56` |
| VideoStatus enum | `lib/sdk/app_player.dart:126` |
| AppPlayerView widget | `lib/sdk/app_player.dart:1001` |
| screenshot() method | `lib/sdk/app_player.dart:870` |
| dispose() method | `lib/sdk/app_player.dart:984` |
| VideoCommand (startStream) | `lib/sdk/camera_device/commands/video_command.dart:55` |

---

*Document complete. Ready for VS-002 implementation.*
