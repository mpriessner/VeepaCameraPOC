# Story 8.1: Implement Method Channel (Swift → Dart)

> **Epic**: 8 - Platform Bridge (Phase 2)
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium
> **Phase**: 2 - Flutter Add-to-App Integration

---

## User Story

**As a** developer,
**I want** Swift to call Flutter methods,
**So that** I can control the camera from native code.

---

## Acceptance Criteria

- [ ] AC1: MethodChannel defined in both Swift and Dart
- [ ] AC2: `connect(deviceId)` callable from Swift
- [ ] AC3: `disconnect()` callable from Swift
- [ ] AC4: `setPTZ(direction, speed)` callable from Swift
- [ ] AC5: Error handling for failed calls
- [ ] AC6: Async/await support in Swift

---

## Technical Specification

### Channel Definition

```swift
// Swift side
class VeepaCameraChannel {
    private let channel: FlutterMethodChannel
    static let channelName = "com.veepapoc/camera"

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: VeepaCameraChannel.channelName,
            binaryMessenger: messenger
        )
    }

    func connect(deviceId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            channel.invokeMethod("connect", arguments: ["deviceId": deviceId]) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown"))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func disconnect() async throws {
        try await withCheckedThrowingContinuation { continuation in
            channel.invokeMethod("disconnect", arguments: nil) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown"))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func setPTZ(direction: String, speed: Int) async throws {
        try await withCheckedThrowingContinuation { continuation in
            channel.invokeMethod("setPTZ", arguments: [
                "direction": direction,
                "speed": speed
            ]) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown"))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

enum ChannelError: Error {
    case flutter(String)
}
```

```dart
// Dart side
class CameraMethodChannel {
  static const _channel = MethodChannel('com.veepapoc/camera');

  static void setup() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'connect':
        final deviceId = call.arguments['deviceId'] as String;
        return await _handleConnect(deviceId);

      case 'disconnect':
        return await _handleDisconnect();

      case 'setPTZ':
        final direction = call.arguments['direction'] as String;
        final speed = call.arguments['speed'] as int;
        return await _handleSetPTZ(direction, speed);

      default:
        throw PlatformException(code: 'NOT_IMPLEMENTED');
    }
  }

  static Future<void> _handleConnect(String deviceId) async {
    final connectionManager = VeepaConnectionManager();
    final device = DiscoveredDevice(
      deviceId: deviceId,
      name: 'External Camera',
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );
    await connectionManager.connect(device);
  }

  static Future<void> _handleDisconnect() async {
    await VeepaConnectionManager().disconnect();
  }

  static Future<void> _handleSetPTZ(String direction, int speed) async {
    final ptzService = VeepaPTZService();
    ptzService.speed = speed;
    await ptzService.startMovement(PTZDirection.values.firstWhere(
      (d) => d.name == direction,
      orElse: () => PTZDirection.stop,
    ));
  }
}
```

---

## Test Cases

### TC8.1.1: Connect Method Works
**Type**: Integration Test
**Priority**: P0

### TC8.1.2: Disconnect Method Works
**Type**: Integration Test
**Priority**: P0

### TC8.1.3: PTZ Method Works
**Type**: Integration Test
**Priority**: P1

### TC8.1.4: Error Handling
**Type**: Unit Test
**Priority**: P1

---

## Definition of Done

- [ ] All methods callable from Swift
- [ ] Errors properly propagated
- [ ] Code committed with message: "feat(epic-8): Method channel - Story 8.1"
