# VeepaCameraPOC - Integration Learnings

> This document captures all learnings from the POC for future SciSymbioLens integration.

## Last Updated
**2026-01-14** - Phase 2 Complete (Stories 6.1-9.2)

---

## Executive Summary

This POC successfully validated the Flutter Add-to-App approach for integrating Veepa IP cameras into a SwiftUI host application. Key achievements:

- **Architecture**: Flutter module embedded in SwiftUI via `FlutterContainerView`
- **Communication**: Bidirectional platform channels (Method + Event)
- **Test Coverage**: 428 Flutter tests, comprehensive iOS unit tests
- **Quality Gates**: All metrics within acceptable thresholds

The patterns established here are directly applicable to SciSymbioLens Phase 4.

---

## Phase 1 Learnings: Pure Flutter

### SDK Initialization
*VeepaConnectionManager singleton pattern*

- **Initialization**: Singleton with `ChangeNotifier` for state management
- **State Machine**: idle → connecting → connected → streaming → disconnected
- **Common Errors**: Network timeouts, invalid credentials
- **Workarounds**: Implement retry logic with exponential backoff

```dart
// Singleton pattern used
class VeepaConnectionManager extends ChangeNotifier {
  static final VeepaConnectionManager _instance = VeepaConnectionManager._internal();
  factory VeepaConnectionManager() => _instance;
}
```

### Camera Discovery
*Mock camera used for POC validation*

- **LAN Scan**: Not implemented in POC (mock devices used)
- **Discovery Timeout**: Configurable, recommend 5-10 seconds
- **Network Requirements**: Same subnet for LAN discovery, or P2P via cloud relay

### P2P Connection
*Connection flow documented*

- **Connection Modes**: LAN direct, P2P relay
- **Typical Connection Time**: Target < 10 seconds
- **Failure Cases**: Network unavailable, invalid device ID, authentication failure
- **Reconnection Strategy**: Automatic with exponential backoff

### Video Streaming
*Frame handling patterns*

- **Frame Format**: RGB frames via VeepaPlayerService
- **Target Frame Rate**: 15+ FPS (quality gate threshold: > 10 FPS)
- **Latency**: Minimize via direct frame callbacks
- **Memory Usage**: Use frame pooling, dispose frames promptly

### PTZ Controls
*Command patterns established*

- **Command Response Time**: Target < 500ms round-trip
- **Stop Command**: Required - movement continues until explicit stop
- **Speed Control**: 0-100 scale via `setPTZ(direction, speed)`
- **Zoom**: Separate `setZoom(level)` method (0.0-1.0)

---

## Phase 2 Learnings: Flutter Add-to-App

### Flutter Module Setup
*Critical configuration for Add-to-App*

**Module Configuration** (pubspec.yaml):
```yaml
flutter:
  # CRITICAL: Use 'module:' for Add-to-App (not regular app config)
  module:
    androidX: true
    androidPackage: com.example.veepa_camera_poc
    iosBundleIdentifier: com.example.veepaCameraPoc
```

**Build Frameworks**:
```bash
# Build iOS frameworks for embedding
cd flutter_veepa_module
flutter build ios-framework --output=../ios_host_app/Flutter
```

**iOS Integration Steps**:
1. Add `module:` directive to pubspec.yaml
2. Run `flutter build ios-framework`
3. Configure project.yml with framework dependencies
4. Create bridging header for GeneratedPluginRegistrant
5. Initialize FlutterEngine in AppDelegate

**Common Pitfalls**:
- Using regular app config instead of `module:` directive
- Missing bridging header for plugin registration
- Incorrect framework embed settings

### Platform Channels
*Bidirectional communication patterns*

**Method Channel (Swift → Dart)**:
- Use for command invocations (connect, disconnect, setPTZ)
- Async/await pattern with `CheckedContinuation`
- Handle `FlutterMethodNotImplemented` as identity check, not type check

```swift
// CORRECT: Identity comparison
if (result as AnyObject) === FlutterMethodNotImplemented {
    // Not implemented
}

// WRONG: Type check (compile error)
if result is FlutterMethodNotImplemented { // Error!
```

**Event Channel (Dart → Swift)**:
- EventChannel is native→Dart only!
- Use MethodChannel with `sendEvent` for Dart→Swift
- Include timestamp with all events

```dart
// Dart → Swift via MethodChannel (not EventChannel)
static const _methodChannel = MethodChannel('com.veepapoc/camera_events_out');

static Future<void> _sendEvent(Map<String, dynamic> event) async {
  event['timestamp'] = DateTime.now().millisecondsSinceEpoch;
  await _methodChannel.invokeMethod('sendEvent', event);
}
```

**Serialization Considerations**:
- Use primitive types: String, int, double, bool, List, Map
- Avoid custom objects - serialize to Map<String, dynamic>
- Include type discriminator in events: `event['type'] = 'frameRate'`

**Performance Notes**:
- Batch events if sending > 30/second
- Use background isolate for heavy serialization
- Monitor memory for frequent large payloads

### SwiftUI Integration
*FlutterContainerView pattern*

**Flutter View Embedding**:
```swift
struct FlutterContainerView: UIViewControllerRepresentable {
    let engine: FlutterEngine

    func makeUIViewController(context: Context) -> FlutterViewController {
        FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    }
}
```

**Lifecycle Management**:
- Initialize FlutterEngine once in AppDelegate
- Reuse engine for multiple views
- Call `engine.run()` only once

**Memory Considerations**:
- FlutterEngine is heavy (~50MB)
- Warm up engine at app launch for faster first display
- Consider engine group for multiple Flutter screens

---

## Code Patterns to Reuse

### VeepaConnectionManager
```dart
class VeepaConnectionManager extends ChangeNotifier {
  static final _instance = VeepaConnectionManager._internal();
  factory VeepaConnectionManager() => _instance;
  VeepaConnectionManager._internal();

  VeepaConnectionState _state = VeepaConnectionState.idle;
  CameraDevice? _connectedDevice;

  VeepaConnectionState get state => _state;
  CameraDevice? get connectedDevice => _connectedDevice;

  Future<void> connect(String deviceId) async {
    _state = VeepaConnectionState.connecting;
    notifyListeners();

    try {
      // Connection logic
      _state = VeepaConnectionState.connected;
      notifyListeners();
    } catch (e) {
      _state = VeepaConnectionState.error;
      notifyListeners();
      rethrow;
    }
  }

  void reset() {
    _state = VeepaConnectionState.idle;
    _connectedDevice = null;
    notifyListeners();
  }
}
```

### VeepaPlayerService
```dart
class VeepaPlayerService extends ChangeNotifier {
  static final _instance = VeepaPlayerService._internal();
  factory VeepaPlayerService() => _instance;
  VeepaPlayerService._internal();

  PlayerState _state = PlayerState.idle;
  double _frameRate = 0;

  void startPlayback() {
    _state = PlayerState.playing;
    notifyListeners();
  }

  void onFrameReceived() {
    // Calculate FPS from frame intervals
    notifyListeners();
  }
}
```

### Platform Bridge (Swift)
```swift
class VeepaCameraChannel {
    private let channel: FlutterMethodChannel

    init(binaryMessenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "com.veepapoc/camera",
            binaryMessenger: binaryMessenger
        )
    }

    func connect(deviceId: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            channel.invokeMethod("connect", arguments: ["deviceId": deviceId]) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown"))
                } else if (result as AnyObject) === FlutterMethodNotImplemented {
                    continuation.resume(throwing: ChannelError.notImplemented("connect"))
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
```

### Platform Bridge (Dart)
```dart
class CameraMethodChannel {
  static const _channel = MethodChannel('com.veepapoc/camera');

  static void setup() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'connect':
        final deviceId = (call.arguments as Map?)?['deviceId'] as String?;
        await VeepaConnectionManager().connect(deviceId ?? '');
        return {'success': true};

      case 'getConnectionStatus':
        final manager = VeepaConnectionManager();
        return {
          'state': manager.state.name,
          'isConnected': manager.state.name == 'connected',
        };

      default:
        throw PlatformException(code: 'UNIMPLEMENTED');
    }
  }
}
```

---

## Pitfalls & Solutions

| Pitfall | Symptom | Solution |
|---------|---------|----------|
| FlutterMethodNotImplemented type check | Compile error: "expects a type on its right-hand side" | Use identity comparison: `(result as AnyObject) === FlutterMethodNotImplemented` |
| EventChannel direction | Dart→Swift events not received | EventChannel is native→Dart only; use MethodChannel for Dart→Swift |
| Missing bridging header | GeneratedPluginRegistrant not found | Create `VeepaPOC-Bridging-Header.h` with `#import "GeneratedPluginRegistrant.h"` |
| Flutter module config | Framework build fails | Use `module:` directive in pubspec.yaml, not regular app config |
| Property name mismatch | Runtime null errors | Ensure Dart service property names match what channel handler returns |
| Test target Info.plist | "Cannot code sign" error | Add `GENERATE_INFOPLIST_FILE: YES` to test target settings |

---

## Performance Metrics

| Metric | Target | Quality Gate |
|--------|--------|--------------|
| Engine Init Time | < 2s | N/A (warm up) |
| Discovery Time | < 5s | N/A (mock) |
| Connection Time | < 10s | PASS if < 10s |
| First Frame | < 5s | PASS if < 5s |
| Video FPS | 15+ | PASS if > 10 |
| PTZ Latency | < 500ms | PASS if < 500ms |
| Error Count | 0 | PASS if == 0 |

Quality gate validation in E2EMetrics:
```swift
var passedAllQualityGates: Bool {
    connectionTime < 10 &&
    firstFrameTime < 5 &&
    averageFPS > 10 &&
    ptzLatency < 0.5 &&
    errorCount == 0
}
```

---

## SciSymbioLens Integration Checklist

When ready to integrate into SciSymbioLens:

- [x] Validate Flutter Add-to-App approach works
- [x] Establish platform channel patterns
- [x] Create E2E metrics collection
- [x] Document all learnings

**For SciSymbioLens Phase 4**:

- [ ] Copy `flutter_veepa_module` to SciSymbioLens project
- [ ] Add Flutter frameworks to iOS project
- [ ] Implement `CameraSourceProtocol` for Veepa cameras
- [ ] Create `RemoteCameraSource` wrapping Flutter module
- [ ] Update `LocalCameraSource` (existing AVFoundation code) to protocol
- [ ] Add camera source switching UI
- [ ] Integrate E2EMetrics for performance monitoring
- [ ] Test with both local and remote cameras
- [ ] Performance benchmarking
- [ ] Documentation update

---

## Open Questions Resolved

| Question | Answer | Date |
|----------|--------|------|
| Can Flutter Add-to-App work with SwiftUI? | Yes, via UIViewControllerRepresentable | 2026-01-14 |
| How to send events Dart → Swift? | Use MethodChannel (EventChannel is native→Dart only) | 2026-01-14 |
| FlutterMethodNotImplemented handling? | Identity comparison, not type check | 2026-01-14 |
| Module vs App configuration? | Use `module:` directive in pubspec.yaml | 2026-01-14 |

---

## File Structure Reference

```
VeepaCameraPOC/
├── flutter_veepa_module/
│   ├── lib/
│   │   ├── main.dart                    # App entry, channel setup
│   │   ├── services/
│   │   │   ├── veepa_connection_manager.dart
│   │   │   ├── veepa_player_service.dart
│   │   │   ├── camera_method_channel.dart  # Swift → Dart
│   │   │   └── camera_event_channel.dart   # Dart → Swift
│   │   ├── models/
│   │   │   └── camera_device.dart
│   │   └── utils/
│   │       └── e2e_metrics.dart
│   └── test/                            # 428 tests
│
├── ios_host_app/
│   ├── project.yml                      # XcodeGen config
│   ├── VeepaPOC/
│   │   ├── App/
│   │   │   ├── VeepaPOCApp.swift
│   │   │   ├── AppDelegate.swift        # FlutterEngine init
│   │   │   └── VeepaPOC-Bridging-Header.h
│   │   ├── Views/
│   │   │   ├── ContentView.swift
│   │   │   ├── FlutterContainerView.swift
│   │   │   └── FlutterCameraView.swift
│   │   ├── Services/
│   │   │   ├── FlutterEngineManager.swift
│   │   │   ├── VeepaCameraChannel.swift
│   │   │   └── CameraEventReceiver.swift
│   │   ├── Models/
│   │   │   ├── E2EMetrics.swift
│   │   │   └── CameraError.swift
│   │   └── Protocols/
│   │       ├── CameraSourceProtocol.swift
│   │       └── MockCameraSource.swift
│   ├── Tests/
│   └── Flutter/                         # Built frameworks
│       ├── Debug/
│       └── Release/
│
└── docs/
    ├── LEARNINGS.md                     # This file
    ├── architecture.md
    ├── brief.md
    ├── prd.md
    └── stories/
```

---

## Troubleshooting Guide

### Build Errors

**"GeneratedPluginRegistrant.h not found"**
```bash
# Ensure bridging header exists and is configured in project.yml
settings:
  base:
    SWIFT_OBJC_BRIDGING_HEADER: VeepaPOC/App/VeepaPOC-Bridging-Header.h
```

**"Flutter.xcframework not found"**
```bash
# Rebuild Flutter frameworks
cd flutter_veepa_module
flutter clean
flutter build ios-framework --output=../ios_host_app/Flutter
```

### Runtime Errors

**"Method not implemented"**
- Check method name matches exactly in Swift and Dart
- Verify channel name is identical on both sides
- Ensure `CameraMethodChannel.setup()` called at startup

**"Null result from channel"**
- Ensure Dart handler returns a value (not void)
- Check property names match between platforms
- Verify arguments map keys are correct

---

## References

- Veepa SDK Analysis: `/Users/mpriessner/windsurf_repos/Veepaisdk/SDK_ANALYSIS.md`
- SciSymbioLens PRD: `/Users/mpriessner/windsurf_repos/SciSymbioLens/docs/prd.md`
- Flutter Add-to-App: https://docs.flutter.dev/add-to-app
- Platform Channels: https://docs.flutter.dev/platform-integration/platform-channels

---

*This document was completed as part of Story 9.2 during Phase 2 implementation.*
