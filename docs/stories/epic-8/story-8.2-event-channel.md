# Story 8.2: Implement Event Channel (Dart → Swift)

> **Epic**: 8 - Platform Bridge (Phase 2)
> **Status**: Draft
> **Priority**: P1 - Should Have
> **Estimated Effort**: Medium
> **Phase**: 2 - Flutter Add-to-App Integration

---

## User Story

**As a** developer,
**I want** Flutter to send events to Swift,
**So that** I can receive connection status and video frame updates.

---

## Acceptance Criteria

- [ ] AC1: EventChannel defined in both Dart and Swift
- [ ] AC2: Connection state changes streamed to Swift
- [ ] AC3: Video frame events available (optional)
- [ ] AC4: Frame rate metrics exposed
- [ ] AC5: Clean subscription management (no leaks)
- [ ] AC6: Performance suitable for status updates (not high-FPS data)

---

## Important: FFI Consideration for Video Frames

**EventChannel is NOT suitable for high-FPS video frame data.**

If SciSymbioLens Phase 4 needs to pass video frames from Flutter to Swift for Gemini API integration, EventChannel will be too slow due to serialization overhead.

### Recommended Approaches for Frame Data:

**Option 1: FFI (Foreign Function Interface)**
```dart
// Dart side - direct memory access
import 'dart:ffi';

// Share memory pointer with native code
final Pointer<Uint8> frameBuffer = calloc<Uint8>(frameSize);
// Write frame data directly to shared memory
// Native code reads from same memory location
```

**Option 2: Shared Memory via Platform Channel**
```swift
// Swift side - create shared CVPixelBuffer
let pixelBuffer: CVPixelBuffer = ...
let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
// Pass memory address to Flutter via method channel
// Flutter reads directly from that address
```

**Option 3: Native Frame Processing**
```swift
// Process frames entirely in native layer
// Only send frame metadata (not pixels) via EventChannel
// Swift code captures frames directly from video layer
```

### This Story's Scope

This story implements EventChannel for **status updates only**:
- Connection state changes
- Player state changes
- Frame rate metrics (numbers, not frame data)
- Error notifications

Video frame data transfer (if needed) should be handled in a **separate story** using FFI.

---

## Technical Specification

### Event Channel Definition

```dart
// Dart side - Event Producer
class CameraEventChannel {
  static const _channel = EventChannel('com.veepapoc/camera_events');
  static const _methodChannel = MethodChannel('com.veepapoc/camera_events_out');
  static StreamController<Map<String, dynamic>>? _eventController;

  static void setup() {
    _channel.receiveBroadcastStream().listen((_) {
      // This is for receiving from native - not used in this direction
    });

    // Create stream controller for sending events
    _eventController = StreamController<Map<String, dynamic>>.broadcast();

    // Listen to connection manager
    VeepaConnectionManager().stateStream.listen((state) {
      _sendEvent({
        'type': 'connectionState',
        'state': state.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });

    // Listen to player service
    VeepaPlayerService().stateStream.listen((state) {
      _sendEvent({
        'type': 'playerState',
        'state': state.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  static Future<void> _sendEvent(Map<String, dynamic> event) async {
    // EventChannel is native → Dart only
    // For Dart → native, use MethodChannel
    try {
      await _methodChannel.invokeMethod('sendEvent', event);
    } catch (e) {
      debugPrint('[CameraEventChannel] Failed to send event: $e');
    }
  }

  static void sendFrameRate(double fps) {
    _sendEvent({
      'type': 'frameRate',
      'fps': fps,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static void sendError(String error) {
    _sendEvent({
      'type': 'error',
      'message': error,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static void dispose() {
    _eventController?.close();
    _eventController = null;
  }
}
```

```swift
// Swift side - Event Receiver
class CameraEventReceiver: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?

    // Event callback for SwiftUI
    var onConnectionStateChanged: ((String) -> Void)?
    var onPlayerStateChanged: ((String) -> Void)?
    var onFrameRateUpdated: ((Double) -> Void)?
    var onError: ((String) -> Void)?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    // Setup with Flutter engine
    static func setup(messenger: FlutterBinaryMessenger) -> CameraEventReceiver {
        let receiver = CameraEventReceiver()

        // EventChannel for native → Dart (if needed)
        let eventChannel = FlutterEventChannel(
            name: "com.veepapoc/camera_events",
            binaryMessenger: messenger
        )
        eventChannel.setStreamHandler(receiver)

        // MethodChannel for Dart → native events
        let methodChannel = FlutterMethodChannel(
            name: "com.veepapoc/camera_events_out",
            binaryMessenger: messenger
        )
        receiver.methodChannel = methodChannel

        methodChannel.setMethodCallHandler { call, result in
            if call.method == "sendEvent" {
                if let args = call.arguments as? [String: Any] {
                    receiver.handleEvent(args)
                }
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return receiver
    }

    private func handleEvent(_ event: [String: Any]) {
        guard let type = event["type"] as? String else { return }

        switch type {
        case "connectionState":
            if let state = event["state"] as? String {
                onConnectionStateChanged?(state)
            }
        case "playerState":
            if let state = event["state"] as? String {
                onPlayerStateChanged?(state)
            }
        case "frameRate":
            if let fps = event["fps"] as? Double {
                onFrameRateUpdated?(fps)
            }
        case "error":
            if let message = event["message"] as? String {
                onError?(message)
            }
        default:
            print("[CameraEventReceiver] Unknown event type: \(type)")
        }
    }
}
```

---

## Implementation Tasks

### Task 1: Create Dart Event Channel
Implement `CameraEventChannel` class.

**Verification**: No lint errors

### Task 2: Create Swift Event Receiver
Implement `CameraEventReceiver` class.

**Verification**: Compiles without errors

### Task 3: Integrate with Connection Manager
Connect event channel to VeepaConnectionManager.

**Verification**: State changes sent to Swift

### Task 4: Integrate with Player Service
Connect event channel to VeepaPlayerService.

**Verification**: Player states sent to Swift

### Task 5: Test Event Flow
Verify events received in Swift.

**Verification**: Events logged in Swift console

---

## Test Cases

### TC8.2.1: Connection State Events
**Type**: Integration Test
**Priority**: P0

```dart
test('connection state changes sent to Swift', () async {
  // Setup event channel
  CameraEventChannel.setup();

  // Trigger connection state change
  final connectionManager = VeepaConnectionManager();
  await connectionManager.connect(testDevice);

  // Verify event was sent (mock method channel)
  verify(mockMethodChannel.invokeMethod('sendEvent', {
    'type': 'connectionState',
    'state': 'connected',
    'timestamp': anyNamed('timestamp'),
  })).called(1);
});
```

**Given**: EventChannel setup complete
**When**: Connection state changes
**Then**: Event sent to native layer

---

### TC8.2.2: Frame Rate Updates
**Type**: Integration Test
**Priority**: P1

```dart
test('frame rate updates sent to Swift', () async {
  CameraEventChannel.setup();

  // Send frame rate
  CameraEventChannel.sendFrameRate(24.5);

  // Verify event was sent
  verify(mockMethodChannel.invokeMethod('sendEvent', {
    'type': 'frameRate',
    'fps': 24.5,
    'timestamp': anyNamed('timestamp'),
  })).called(1);
});
```

**Given**: EventChannel setup
**When**: sendFrameRate called
**Then**: Frame rate event sent to native

---

### TC8.2.3: Subscription Cleanup
**Type**: Unit Test
**Priority**: P1

```dart
test('disposes resources cleanly', () async {
  CameraEventChannel.setup();
  CameraEventChannel.dispose();

  // Stream controller should be closed
  // No errors on subsequent calls
});
```

**Given**: EventChannel active
**When**: dispose() called
**Then**: Resources cleaned up, no leaks

---

### TC8.2.4: Swift Event Reception
**Type**: Integration Test (Device Only)
**Priority**: P0

```swift
func testEventReception() {
    let receiver = CameraEventReceiver.setup(messenger: flutterEngine.binaryMessenger)

    var receivedState: String?
    receiver.onConnectionStateChanged = { state in
        receivedState = state
    }

    // Trigger Flutter event
    // Verify receivedState is set
}
```

**Given**: Swift receiver setup
**When**: Event sent from Dart
**Then**: Swift callback invoked

---

### TC8.2.5: High-Frequency Event Performance
**Type**: Performance Test (Device Only)
**Priority**: P1

```dart
test('handles frequent status updates', () async {
  CameraEventChannel.setup();

  // Send 100 events rapidly
  for (int i = 0; i < 100; i++) {
    CameraEventChannel.sendFrameRate(15.0 + (i % 10));
    await Future.delayed(Duration(milliseconds: 10));
  }

  // All events should be processed without dropping
  // No memory growth
});
```

**Given**: EventChannel under load
**When**: Many events sent rapidly
**Then**: Events processed, memory stable

---

## Test Environment Requirements

| Test Case | Simulator | Device |
|-----------|-----------|--------|
| TC8.2.1 | Yes (mocked) | Yes |
| TC8.2.2 | Yes (mocked) | Yes |
| TC8.2.3 | Yes | Yes |
| TC8.2.4 | No | **Required** |
| TC8.2.5 | No | **Required** |

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC6) verified
- [ ] All P0 test cases pass
- [ ] Events received in Swift
- [ ] No memory leaks
- [ ] Performance adequate for status updates
- [ ] Code committed with message: "feat(epic-8): Event channel - Story 8.2"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 8.1 (Method Channel)
- **Blocks**: Story 9.1 (E2E Testing)

---

## References

- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [EventChannel API](https://api.flutter.dev/flutter/services/EventChannel-class.html)
- [dart:ffi](https://dart.dev/guides/libraries/c-interop)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC8.2.1 | | | |
| TC8.2.2 | | | |
| TC8.2.3 | | | |
| TC8.2.4 | | | |
| TC8.2.5 | | | |

---
