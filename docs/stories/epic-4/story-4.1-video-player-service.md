# Story 4.1: Implement Video Player Service

> **Epic**: 4 - Video Streaming
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Large

---

## User Story

**As a** developer,
**I want** a video player service that wraps the SDK's player functionality,
**So that** I can display live camera video in a reusable way.

---

## Acceptance Criteria

- [ ] AC1: `VeepaPlayerService` class created wrapping SDK's AppPlayer
- [ ] AC2: Can start/stop video stream from connected camera
- [ ] AC3: Exposes player state (stopped, buffering, playing, error)
- [ ] AC4: Reports frame rate for diagnostics
- [ ] AC5: Handles stream errors gracefully with error callback
- [ ] AC6: Provides video texture or widget for display
- [ ] AC7: Supports pause/resume operations
- [ ] AC8: Memory efficient - cleans up when stopped

---

## Technical Specification

### Player State Machine

```
              ┌─────────────┐
              │   Stopped   │◄───────────────┐
              └──────┬──────┘                │
                     │                       │
          start()    │                       │ stop()
                     ▼                       │
              ┌─────────────┐                │
              │  Buffering  │────────────────┤
              └──────┬──────┘    error       │
                     │                       │
       data received │                       │
                     ▼                       │
              ┌─────────────┐                │
              │   Playing   │────────────────┤
              └──────┬──────┘    error       │
                     │                       │
          pause()    │                       │
                     ▼                       │
              ┌─────────────┐                │
              │   Paused    │────────────────┘
              └─────────────┘
```

### PlayerState Enum

Create `lib/models/player_state.dart`:

```dart
/// Video player state
enum PlayerState {
  /// Player not started
  stopped,

  /// Stream started, waiting for first frame
  buffering,

  /// Actively playing video
  playing,

  /// Playback paused
  paused,

  /// Error occurred
  error,
}

extension PlayerStateExtension on PlayerState {
  bool get isActive =>
      this == PlayerState.buffering ||
      this == PlayerState.playing ||
      this == PlayerState.paused;

  bool get isPlaying => this == PlayerState.playing;
  bool get canPlay => this == PlayerState.stopped || this == PlayerState.error;

  String get displayName {
    switch (this) {
      case PlayerState.stopped:
        return 'Stopped';
      case PlayerState.buffering:
        return 'Buffering...';
      case PlayerState.playing:
        return 'Playing';
      case PlayerState.paused:
        return 'Paused';
      case PlayerState.error:
        return 'Error';
    }
  }
}
```

### VeepaPlayerService

Create `lib/services/veepa_player_service.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/models/player_state.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';
import 'package:flutter_veepa_module/services/veepa_connection_manager.dart';

/// Manages video playback from Veepa camera
class VeepaPlayerService extends ChangeNotifier {
  /// Configuration
  static const Duration bufferingTimeout = Duration(seconds: 10);
  static const int targetFrameRate = 15;

  /// Player state
  PlayerState _state = PlayerState.stopped;
  PlayerState get state => _state;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Current device
  DiscoveredDevice? _device;
  DiscoveredDevice? get device => _device;

  /// Frame rate monitoring
  int _frameCount = 0;
  DateTime? _frameCountStart;
  double _currentFPS = 0;
  double get currentFPS => _currentFPS;

  /// State stream for external listeners
  final StreamController<PlayerState> _stateController =
      StreamController<PlayerState>.broadcast();
  Stream<PlayerState> get stateStream => _stateController.stream;

  /// Frame callback for video texture
  void Function(Uint8List frameData, int width, int height)? onFrameReceived;

  /// Timers
  Timer? _bufferingTimer;
  Timer? _fpsTimer;

  /// Connection manager reference
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// SDK Player reference (to be implemented with actual SDK)
  dynamic _sdkPlayer;

  /// Start video playback for device
  Future<bool> start(DiscoveredDevice device) async {
    if (_state.isActive) {
      debugPrint('[VeepaPlayer] Already active, stopping first');
      await stop();
    }

    _device = device;
    _errorMessage = null;
    _updateState(PlayerState.buffering);

    // Start buffering timeout
    _startBufferingTimeout();

    try {
      // Verify connection is active
      if (!_connectionManager.state.isConnected) {
        throw Exception('Not connected to camera');
      }

      // Initialize SDK player
      await _initializePlayer();

      // Start stream
      await _startStream();

      // Start FPS monitoring
      _startFPSMonitoring();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _updateState(PlayerState.error);
      return false;
    }
  }

  /// Initialize the SDK player
  Future<void> _initializePlayer() async {
    debugPrint('[VeepaPlayer] Initializing player...');

    // TODO: Replace with actual SDK player initialization
    // final p2pApi = VeepaSDKManager().p2pApi;
    // _sdkPlayer = AppPlayer(p2pApi);

    // Simulate initialization
    await Future.delayed(const Duration(milliseconds: 100));

    debugPrint('[VeepaPlayer] Player initialized');
  }

  /// Start the video stream
  Future<void> _startStream() async {
    debugPrint('[VeepaPlayer] Starting stream from ${_device?.name}');

    // TODO: Replace with actual SDK stream start
    // await _sdkPlayer.start(
    //   videoSource: LiveVideoSource(deviceId: _device!.deviceId),
    //   onFrame: _onFrameReceived,
    //   onError: _onStreamError,
    // );

    // Simulate first frame after delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_state == PlayerState.buffering) {
        _cancelBufferingTimeout();
        _updateState(PlayerState.playing);
      }
    });
  }

  /// Handle frame received from SDK
  void _onFrameReceived(Uint8List frameData, int width, int height) {
    // Update frame count for FPS calculation
    _frameCount++;

    // First frame - transition from buffering
    if (_state == PlayerState.buffering) {
      _cancelBufferingTimeout();
      _updateState(PlayerState.playing);
    }

    // Notify listeners
    onFrameReceived?.call(frameData, width, height);
  }

  /// Handle stream error
  void _onStreamError(dynamic error) {
    debugPrint('[VeepaPlayer] Stream error: $error');
    _errorMessage = error.toString();
    _updateState(PlayerState.error);
  }

  /// Stop video playback
  Future<void> stop() async {
    debugPrint('[VeepaPlayer] Stopping player');

    _cancelBufferingTimeout();
    _stopFPSMonitoring();

    try {
      // TODO: Replace with actual SDK stop
      // await _sdkPlayer?.stop();
      _sdkPlayer = null;
    } catch (e) {
      debugPrint('[VeepaPlayer] Error stopping: $e');
    }

    _device = null;
    _currentFPS = 0;
    _updateState(PlayerState.stopped);
  }

  /// Pause playback
  void pause() {
    if (_state != PlayerState.playing) return;

    debugPrint('[VeepaPlayer] Pausing');

    // TODO: Implement actual pause (may need to stop stream and cache frame)
    _updateState(PlayerState.paused);
  }

  /// Resume playback
  void resume() {
    if (_state != PlayerState.paused) return;

    debugPrint('[VeepaPlayer] Resuming');
    _updateState(PlayerState.playing);
  }

  /// Start buffering timeout
  void _startBufferingTimeout() {
    _cancelBufferingTimeout();
    _bufferingTimer = Timer(bufferingTimeout, () {
      if (_state == PlayerState.buffering) {
        _errorMessage = 'Buffering timeout - no video data received';
        _updateState(PlayerState.error);
      }
    });
  }

  /// Cancel buffering timeout
  void _cancelBufferingTimeout() {
    _bufferingTimer?.cancel();
    _bufferingTimer = null;
  }

  /// Start FPS monitoring
  void _startFPSMonitoring() {
    _frameCount = 0;
    _frameCountStart = DateTime.now();

    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _calculateFPS();
    });
  }

  /// Stop FPS monitoring
  void _stopFPSMonitoring() {
    _fpsTimer?.cancel();
    _fpsTimer = null;
  }

  /// Calculate current FPS
  void _calculateFPS() {
    if (_frameCountStart == null) return;

    final elapsed = DateTime.now().difference(_frameCountStart!).inSeconds;
    if (elapsed > 0) {
      _currentFPS = _frameCount / elapsed;

      // Log if FPS is below target
      if (_currentFPS < targetFrameRate && _state == PlayerState.playing) {
        debugPrint('[VeepaPlayer] Low FPS: ${_currentFPS.toStringAsFixed(1)}');
      }
    }

    // Reset counter every 5 seconds for rolling average
    if (elapsed >= 5) {
      _frameCount = 0;
      _frameCountStart = DateTime.now();
    }

    notifyListeners();
  }

  /// Update player state
  void _updateState(PlayerState newState) {
    if (_state == newState) return;

    debugPrint('[VeepaPlayer] State: ${_state.name} -> ${newState.name}');
    _state = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  /// Clean up resources
  @override
  void dispose() {
    _cancelBufferingTimeout();
    _stopFPSMonitoring();
    _stateController.close();
    _sdkPlayer = null;
    super.dispose();
  }
}
```

### Video Frame Texture Widget

Create `lib/widgets/video_frame_widget.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Widget to display video frames
class VideoFrameWidget extends StatefulWidget {
  final Stream<VideoFrame>? frameStream;
  final BoxFit fit;
  final Widget? placeholder;

  const VideoFrameWidget({
    super.key,
    this.frameStream,
    this.fit = BoxFit.contain,
    this.placeholder,
  });

  @override
  State<VideoFrameWidget> createState() => _VideoFrameWidgetState();
}

class _VideoFrameWidgetState extends State<VideoFrameWidget> {
  Uint8List? _currentFrame;
  int _frameWidth = 0;
  int _frameHeight = 0;

  @override
  Widget build(BuildContext context) {
    if (_currentFrame == null) {
      return widget.placeholder ?? const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Image.memory(
      _currentFrame!,
      fit: widget.fit,
      gaplessPlayback: true, // Prevents flickering between frames
    );
  }
}

/// Video frame data
class VideoFrame {
  final Uint8List data;
  final int width;
  final int height;
  final DateTime timestamp;

  VideoFrame({
    required this.data,
    required this.width,
    required this.height,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
```

---

## Implementation Tasks

### Task 1: Create PlayerState Enum
Create `lib/models/player_state.dart`.

**Verification**: No lint errors

### Task 2: Create VeepaPlayerService
Create `lib/services/veepa_player_service.dart`.

**Verification**: No lint errors

### Task 3: Create VideoFrameWidget
Create `lib/widgets/video_frame_widget.dart`.

**Verification**: No lint errors

### Task 4: Integrate with SDK Player
Replace placeholder code with actual SDK player calls.

**Verification**: Video frames received

### Task 5: Test FPS Monitoring
Verify FPS calculation works correctly.

**Verification**: FPS displays accurately

### Task 6: Unit Tests
Create comprehensive unit tests.

**Verification**: All tests pass

---

## Test Cases

### TC4.1.1: Player State Transitions
**Type**: Unit Test
**Priority**: P0

```dart
// test/services/veepa_player_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/veepa_player_service.dart';
import 'package:flutter_veepa_module/models/player_state.dart';

void main() {
  group('VeepaPlayerService', () {
    test('initial state is stopped', () {
      final service = VeepaPlayerService();
      expect(service.state, PlayerState.stopped);
    });

    test('start transitions to buffering then playing', () async {
      final service = VeepaPlayerService();
      final states = <PlayerState>[];

      service.stateStream.listen(states.add);

      // Would need mock device and connection
      // Verify: stopped -> buffering -> playing
    });
  });
}
```

**Given**: Stopped player
**When**: start() called
**Then**: Transitions through buffering to playing

---

### TC4.1.2: Buffering Timeout
**Type**: Unit Test
**Priority**: P0

```dart
test('buffering timeout triggers error state', () async {
  final service = VeepaPlayerService();

  // Start without actual stream (will timeout)
  // After bufferingTimeout, should be in error state

  await Future.delayed(VeepaPlayerService.bufferingTimeout + Duration(seconds: 1));

  expect(service.state, PlayerState.error);
  expect(service.errorMessage, contains('timeout'));
});
```

**Given**: Player buffering
**When**: No frames received within timeout
**Then**: Transitions to error state

---

### TC4.1.3: FPS Calculation
**Type**: Unit Test
**Priority**: P1

```dart
test('FPS calculated correctly', () {
  final service = VeepaPlayerService();

  // Simulate 30 frames over 2 seconds
  // Expected FPS: 15

  // Note: This requires access to internal _onFrameReceived method
  // or mocking the frame stream
});
```

**Given**: Frames arriving at known rate
**When**: FPS calculated
**Then**: Reports accurate frame rate

---

### TC4.1.4: Stop Cleans Up Resources
**Type**: Unit Test
**Priority**: P0

```dart
test('stop cleans up all resources', () async {
  final service = VeepaPlayerService();

  // Start player
  // ...

  await service.stop();

  expect(service.state, PlayerState.stopped);
  expect(service.device, isNull);
  expect(service.currentFPS, 0);
});
```

**Given**: Playing player
**When**: stop() called
**Then**: All state cleaned up

---

### TC4.1.5: Pause/Resume Works
**Type**: Unit Test
**Priority**: P1

```dart
test('pause and resume work correctly', () {
  final service = VeepaPlayerService();

  // Assume playing state
  service.pause();
  expect(service.state, PlayerState.paused);

  service.resume();
  expect(service.state, PlayerState.playing);
});
```

**Given**: Playing player
**When**: pause() then resume() called
**Then**: State transitions correctly

---

### TC4.1.6: Error Handling
**Type**: Unit Test
**Priority**: P0

```dart
test('stream error triggers error state', () {
  final service = VeepaPlayerService();

  // Simulate stream error
  service._onStreamError('Test error');

  expect(service.state, PlayerState.error);
  expect(service.errorMessage, 'Test error');
});
```

**Given**: Playing player
**When**: Stream error occurs
**Then**: Error state with message

---

### TC4.1.7: Integration with Real Camera
**Type**: Manual/Integration
**Priority**: P0

**Preconditions**:
- Veepa camera connected
- Connection manager showing connected state

**Steps**:
1. Start player service with connected device
2. Observe buffering state
3. Wait for first frame
4. Check FPS counter
5. Stop player
6. Verify clean stop

**Expected Results**:
- [ ] Player starts successfully
- [ ] First frame received within 10 seconds
- [ ] FPS shows reasonable value (10+)
- [ ] No memory leaks after stop
- [ ] Console shows state transitions

---

### TC4.1.8: State Stream Emissions
**Type**: Unit Test
**Priority**: P1

```dart
test('state stream emits all transitions', () async {
  final service = VeepaPlayerService();
  final states = <PlayerState>[];

  final sub = service.stateStream.listen(states.add);

  // Perform lifecycle
  // ...

  await sub.cancel();

  // Verify all expected states were emitted
  expect(states, containsAll([
    PlayerState.buffering,
    PlayerState.playing,
    PlayerState.stopped,
  ]));
});
```

**Given**: Stream subscription active
**When**: Player lifecycle executed
**Then**: All state changes emitted

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] Video frames can be received from camera
- [ ] FPS monitoring functional
- [ ] Error handling comprehensive
- [ ] Code committed with message: "feat(epic-4): Implement video player service - Story 4.1"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 3.1 (Connection Manager must be connected)
- **Blocks**: Story 4.2 (Video Display UI)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SDK player API unclear | High | Medium | Study demo app implementation |
| Frame format incompatible | High | Medium | Support multiple formats |
| Memory leak from frames | High | Medium | Proper dispose and cleanup |
| Low FPS on older devices | Medium | Medium | Frame rate adaptation |

---

## References

- [Veepa SDK app_player.dart](/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/app_player.dart)
- [Flutter Texture](https://api.flutter.dev/flutter/widgets/Texture-class.html)
- [Video Frame Processing](https://docs.flutter.dev/development/platform-integration/platform-channels)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC4.1.1 | | | |
| TC4.1.2 | | | |
| TC4.1.3 | | | |
| TC4.1.4 | | | |
| TC4.1.5 | | | |
| TC4.1.6 | | | |
| TC4.1.7 | | | |
| TC4.1.8 | | | |

---
