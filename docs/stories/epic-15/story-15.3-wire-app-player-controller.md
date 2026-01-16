# Story 15.3: Wire AppPlayerController to VeepaPlayerService

> **Epic**: 15 - SDK Integration Completion
> **Phase**: A (Tonight - Critical Path)
> **Status**: Ready
> **Priority**: P0 - Must Have
> **Estimated Effort**: Large (2-3 hours)
> **Depends On**: Story 15.1 (needs client handle)

---

## User Story

**As a** developer,
**I want** VeepaPlayerService to use the real AppPlayerController from the SDK,
**So that** actual video frames are decoded from the camera stream.

---

## Background

The Veepa SDK provides `AppPlayerController` in `lib/sdk/app_player.dart` which:
- Uses FFI to call native video decoder library (`libOKSMARTPLAY.so` / `libVSTC.a`)
- Accepts a `LiveVideoSource` with the P2P client handle
- Provides callbacks for frame data, state changes, errors
- Uses Flutter's `Texture` widget for rendering

Currently, `VeepaPlayerService._initializePlayer()` and `_startStream()` are placeholders.

---

## Acceptance Criteria

- [ ] AC1: VeepaPlayerService creates real AppPlayerController instance
- [ ] AC2: LiveVideoSource created with client handle from connection
- [ ] AC3: Player start/stop calls real SDK methods
- [ ] AC4: Frame callback wired to receive decoded frames
- [ ] AC5: State callback updates PlayerState correctly
- [ ] AC6: Error callback handles decode failures
- [ ] AC7: Texture ID exposed for rendering
- [ ] AC8: Clean resource disposal on stop

---

## Technical Specification

### 1. Study AppPlayerController API

From `lib/sdk/app_player.dart`:

```dart
class AppPlayerController<T> {
  // Platform channel for native communication
  static const MethodChannel app_player_channel = MethodChannel('app_player');
  static const EventChannel app_player_event = EventChannel("app_player/event");

  // Native library reference
  static final DynamicLibrary playerLib = Platform.isAndroid
      ? DynamicLibrary.open('libOKSMARTPLAY.so')
      : DynamicLibrary.process();

  // Player state
  int playerId = 0;  // Native player pointer
  int textureId = -1;  // Flutter texture ID for rendering

  // Callbacks
  StateChangeCallback<T>? changeCallback;

  // Key methods to use:
  Future<int> create();  // Creates native player, returns texture ID
  Future<void> start(VideoSource source);  // Starts playback
  Future<void> stop();  // Stops playback
  Future<void> dispose();  // Cleanup
}
```

### 2. Update VeepaPlayerService

```dart
// lib/services/veepa_player_service.dart

import 'package:veepa_camera_poc/sdk/app_player.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';

class VeepaPlayerService extends ChangeNotifier {
  // ... existing code ...

  /// Real SDK player controller
  AppPlayerController? _playerController;

  /// Texture ID for rendering (-1 if not ready)
  int _textureId = -1;
  int get textureId => _textureId;

  /// Connection manager for client handle
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// Initialize the SDK player - REPLACE PLACEHOLDER
  Future<void> _initializePlayer() async {
    debugPrint('[VeepaPlayer] Initializing AppPlayerController...');

    // Create the player controller with state callback
    _playerController = AppPlayerController<VeepaPlayerService>(
      changeCallback: _onPlayerStateChanged,
      userData: this,
    );

    // Create native player and get texture ID
    final result = await _playerController!.create();

    if (result > 0) {
      _textureId = result;
      debugPrint('[VeepaPlayer] Player created with textureId: $_textureId');
    } else {
      throw Exception('Failed to create player: $result');
    }
  }

  /// Start the video stream - REPLACE PLACEHOLDER
  Future<void> _startStream() async {
    debugPrint('[VeepaPlayer] Starting stream from ${_device?.name}');

    // Get client handle from connection manager
    final clientHandle = _connectionManager.clientHandle;
    if (clientHandle == null || clientHandle <= 0) {
      throw Exception('No valid connection handle');
    }

    debugPrint('[VeepaPlayer] Using client handle: $clientHandle');

    // Create live video source with client handle
    final videoSource = LiveVideoSource(clientHandle);

    // Start the player with live source
    await _playerController!.start(videoSource);

    debugPrint('[VeepaPlayer] Stream started');
  }

  /// Player state callback from SDK
  void _onPlayerStateChanged(
    VeepaPlayerService? userData,
    VideoStatus videoStatus,
    VoiceStatus voiceStatus,
    RecordStatus recordStatus,
    SoundTouchType touchType,
  ) {
    debugPrint('[VeepaPlayer] SDK state: $videoStatus');

    switch (videoStatus) {
      case VideoStatus.STARTING:
        if (_state != PlayerState.buffering) {
          _updateState(PlayerState.buffering);
        }
        break;
      case VideoStatus.PLAY:
        _cancelBufferingTimeout();
        if (_state != PlayerState.playing) {
          _updateState(PlayerState.playing);
        }
        // Increment frame count for FPS
        _frameCount++;
        break;
      case VideoStatus.PAUSE:
        _updateState(PlayerState.paused);
        break;
      case VideoStatus.STOP:
        _updateState(PlayerState.stopped);
        break;
    }
  }

  /// Stop video playback - UPDATE
  Future<void> stop() async {
    debugPrint('[VeepaPlayer] Stopping player');

    _cancelBufferingTimeout();
    _stopFPSMonitoring();

    try {
      await _playerController?.stop();
      await _playerController?.dispose();
      _playerController = null;
      _textureId = -1;
    } catch (e) {
      debugPrint('[VeepaPlayer] Error stopping: $e');
    }

    _device = null;
    _currentFPS = 0;
    _updateState(PlayerState.stopped);
  }

  /// Pause playback - UPDATE
  void pause() {
    if (_state != PlayerState.playing) return;
    debugPrint('[VeepaPlayer] Pausing');
    _playerController?.pause();
    _updateState(PlayerState.paused);
  }

  /// Resume playback - UPDATE
  void resume() {
    if (_state != PlayerState.paused) return;
    debugPrint('[VeepaPlayer] Resuming');
    _playerController?.resume();
    _updateState(PlayerState.playing);
  }
}
```

### 3. Handle Error Callbacks

Add error handling from SDK:

```dart
// In _initializePlayer, add error callback if available
_playerController!.onError = (error) {
  debugPrint('[VeepaPlayer] SDK error: $error');
  _errorMessage = error.toString();
  _updateState(PlayerState.error);
};
```

### 4. Check SDK Methods Available

Review `app_player.dart` for exact method signatures:
- `create()` - May need parameters
- `start(VideoSource)` - Exact parameter type
- `stop()`, `pause()`, `resume()` - Available methods
- Callback signatures and how to register them

---

## Files to Modify

1. `lib/services/veepa_player_service.dart` - Main changes
2. `test/services/veepa_player_service_test.dart` - Update tests

---

## Integration Points

### From Story 15.1
```dart
// Get client handle for video source
final clientHandle = _connectionManager.clientHandle;
final videoSource = LiveVideoSource(clientHandle);
```

### To Story 15.4
```dart
// Expose texture ID for VideoScreen
int get textureId => _textureId;
```

---

## Testing Strategy

### Unit Tests
```dart
test('creates player with texture ID', () async {
  final mockController = MockAppPlayerController();
  when(mockController.create()).thenAnswer((_) async => 123);

  await playerService.start(testDevice);

  expect(playerService.textureId, equals(123));
});
```

### Integration Test
1. Connect to camera (Story 15.1)
2. Start player
3. Verify textureId is valid (> 0)
4. Verify state transitions: stopped -> buffering -> playing

---

## Definition of Done

- [ ] Real AppPlayerController created and managed
- [ ] LiveVideoSource uses connection client handle
- [ ] State callbacks update PlayerState
- [ ] Texture ID available for rendering
- [ ] Stop/dispose properly cleans up
- [ ] Tests pass

---

## Notes

- The native library `libVSTC.a` is arm64-only (no simulator)
- Testing must be on physical device
- Watch for memory leaks - native resources must be freed
- FPS counting should use frame callbacks, not simulated

---

## Reference: SDK Classes

```dart
// VideoSource types in app_player.dart
LiveVideoSource(int clientPtr)  // For live camera feed
FileVideoSource(String path)     // For recorded files
CardVideoSource(...)             // For SD card playback

// VideoStatus enum
enum VideoStatus { STOP, STARTING, PLAY, PAUSE }
```
