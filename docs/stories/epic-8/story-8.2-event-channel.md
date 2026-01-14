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

---

## Technical Specification

### Event Channel Definition

```dart
// Dart side - Event Producer
class CameraEventChannel {
  static const _channel = EventChannel('com.veepapoc/camera_events');
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
      });
    });

    // Listen to player service
    VeepaPlayerService().stateStream.listen((state) {
      _sendEvent({
        'type': 'playerState',
        'state': state.name,
      });
    });
  }

  static void _sendEvent(Map<String, dynamic> event) {
    // Events sent via method channel (EventChannel is native → Dart)
    // For Dart → native, use MethodChannel callback
  }

  static void sendFrameRate(double fps) {
    _sendEvent({
      'type': 'frameRate',
      'fps': fps,
    });
  }
}
```

```swift
// Swift side - Event Receiver
class CameraEventReceiver: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

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
        let channel = FlutterEventChannel(
            name: "com.veepapoc/camera_events",
            binaryMessenger: messenger
        )
        channel.setStreamHandler(receiver)
        return receiver
    }
}
```

---

## Test Cases

### TC8.2.1: Connection State Events
**Type**: Integration Test
**Priority**: P0

### TC8.2.2: Frame Rate Updates
**Type**: Integration Test
**Priority**: P1

### TC8.2.3: Subscription Cleanup
**Type**: Unit Test
**Priority**: P1

---

## Definition of Done

- [ ] Events received in Swift
- [ ] No memory leaks
- [ ] Code committed with message: "feat(epic-8): Event channel - Story 8.2"
