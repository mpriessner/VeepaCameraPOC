# Veepa Camera Integration Guide

## Overview

This guide explains how to integrate the Veepa Camera Flutter module into an iOS application using the Flutter Add-to-App approach.

## Prerequisites

- Flutter 3.0+ installed
- Xcode 15.0+ with iOS 17+ SDK
- Real Veepa camera for hardware testing
- Swift 5.9+

## Project Structure

```
VeepaCameraPOC/
├── flutter_veepa_module/     # Flutter module (add-to-app)
│   ├── lib/
│   │   ├── screens/          # UI screens
│   │   ├── services/         # Business logic
│   │   ├── widgets/          # Reusable widgets
│   │   ├── sdk/              # SDK wrappers
│   │   └── testing/          # Hardware tests
│   └── test/                 # Unit tests
└── ios_host_app/             # SwiftUI host application
    └── VeepaPOC/             # Xcode project
```

## Step 1: Add Flutter Module

### pubspec.yaml

The Flutter module is configured as an add-to-app module:

```yaml
name: veepa_camera_poc
module:
  androidX: true
  androidPackage: com.veepapoc.veepa_camera_poc
  iosBundleIdentifier: com.veepapoc.veepaCameraPoc
```

### Build Flutter Framework

```bash
cd flutter_veepa_module
flutter build ios-framework --output=../ios_host_app/Flutter
```

## Step 2: Configure iOS Host App

### Add Framework References

In your `project.yml` (XcodeGen) or Xcode project settings:

```yaml
targets:
  VeepaPOC:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - VeepaPOC
    settings:
      ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES: YES
    dependencies:
      - framework: Flutter/Release/Flutter.xcframework
      - framework: Flutter/Release/App.xcframework
```

### Initialize Flutter Engine

```swift
import Flutter

class AppDelegate: NSObject, UIApplicationDelegate {
    lazy var flutterEngine = FlutterEngine(name: "veepa_engine")

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        flutterEngine.run()
        return true
    }
}
```

## Step 3: Create Platform Channels

### Swift Side

```swift
class CameraBridge: ObservableObject {
    private var channel: FlutterMethodChannel?

    func setup(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: "veepa_camera/control",
            binaryMessenger: messenger
        )

        channel?.setMethodCallHandler { [weak self] call, result in
            switch call.method {
            case "getWifiSSID":
                result(self?.getCurrentSSID())
            case "openWifiSettings":
                self?.openWifiSettings()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
```

### Flutter Side

```dart
class NativeBridge {
  static const _channel = MethodChannel('veepa_camera/control');

  static Future<String?> getWifiSSID() async {
    return await _channel.invokeMethod('getWifiSSID');
  }

  static Future<void> openWifiSettings() async {
    await _channel.invokeMethod('openWifiSettings');
  }
}
```

## Step 4: Present Flutter Views

### SwiftUI Integration

```swift
struct FlutterCameraView: UIViewControllerRepresentable {
    @EnvironmentObject var appDelegate: AppDelegate

    func makeUIViewController(context: Context) -> FlutterViewController {
        FlutterViewController(
            engine: appDelegate.flutterEngine,
            nibName: nil,
            bundle: nil
        )
    }

    func updateUIViewController(_ uiViewController: FlutterViewController, context: Context) {}
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            FlutterCameraView()
                .navigationTitle("Camera")
        }
    }
}
```

## Step 5: Camera Connection Flow

### 1. Scan QR Code

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => QRScannerScreen(
      onScan: (data) {
        // data contains deviceId, password, model
        _onDeviceScanned(data);
      },
    ),
  ),
);
```

### 2. WiFi Provisioning (First-Time Setup)

```dart
// Check if connected to camera AP
final wifi = WifiDiscoveryService();
await wifi.startMonitoring();

if (wifi.isConnectedToVeepaAP) {
  // Show WiFi provisioning screen
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => WifiProvisioningScreen(
        onProvisioningComplete: () {
          // Camera will reboot and connect to home WiFi
        },
      ),
    ),
  );
}
```

### 3. Connect to Camera

```dart
final manager = VeepaConnectionManager();

final success = await manager.connect(DeviceInfo(
  deviceId: scannedData.deviceId,
  password: scannedData.password,
  name: scannedData.model,
));

if (success) {
  // Start video player
  await _playerService.start();
}
```

## Step 6: Video Streaming

### Display Video

```dart
Widget build(BuildContext context) {
  return CameraPreview(
    connectionManager: _connectionManager,
    playerService: _playerService,
    showControls: true,
  );
}
```

### Handle Player States

```dart
_playerService.addListener(() {
  switch (_playerService.state) {
    case PlayerState.playing:
      // Video is streaming
      break;
    case PlayerState.buffering:
      // Show loading indicator
      break;
    case PlayerState.error:
      // Handle error
      break;
  }
});
```

## Step 7: PTZ Controls

### Add Controls

```dart
PTZControls(
  service: _ptzService,
  size: 200,
  onDirectionChanged: (direction) {
    // Optional: track direction changes
  },
)
```

### Programmatic Control

```dart
// Move camera
await _ptzService.moveUp(speed: 50);
await Future.delayed(Duration(seconds: 2));
await _ptzService.stop();

// Zoom
await _ptzService.zoomIn();
await Future.delayed(Duration(seconds: 1));
await _ptzService.stopZoom();

// Go to preset
await _ptzService.goToPreset(1);
```

## Testing

### Run Unit Tests

```bash
cd flutter_veepa_module
flutter test
```

### Run Hardware Tests

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => HardwareTestScreen(
      deviceId: 'YOUR_DEVICE_ID',
      password: 'YOUR_PASSWORD',
    ),
  ),
);
```

## Quality Gates

The following quality gates must pass for production:

| Gate | Threshold |
|------|-----------|
| Connection Time | < 10 seconds |
| Time to First Frame | < 5 seconds |
| Frame Rate | > 10 FPS |
| PTZ Latency | < 500ms |
| Error Rate | 0 |

## Troubleshooting

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues and solutions.
