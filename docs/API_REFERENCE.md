# Veepa Camera POC - API Reference

## Overview

This document provides a comprehensive API reference for the Veepa Camera Flutter module.

## Core Services

### VeepaConnectionManager

Manages camera connections using P2P or LAN modes.

```dart
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';

final manager = VeepaConnectionManager();

// Connect to a camera
final success = await manager.connect(
  DeviceInfo(
    deviceId: 'VSTC_ABC123',
    password: 'admin',
    name: 'Living Room Camera',
  ),
);

// Check connection state
print(manager.state); // ConnectionState.connected

// Disconnect
await manager.disconnect();
```

#### Properties
- `state` - Current connection state
- `isConnected` - Boolean connection status
- `connectedDevice` - Currently connected device info

#### Methods
- `connect(DeviceInfo device)` - Connect to a camera
- `disconnect()` - Disconnect current camera
- `reconnect()` - Reconnect to last device

### VeepaPlayerService

Handles video streaming from connected cameras.

```dart
import 'package:veepa_camera_poc/services/veepa_player_service.dart';

final player = VeepaPlayerService(connectionManager: manager);

// Start playback
await player.start();

// Listen for state changes
player.addListener(() {
  print('Player state: ${player.state}');
});

// Stop playback
await player.stop();
```

#### Properties
- `state` - Current player state
- `isPlaying` - Boolean playing status
- `statistics` - Video statistics (FPS, bitrate, etc.)

#### Methods
- `start()` - Start video playback
- `stop()` - Stop video playback
- `pause()` - Pause playback
- `resume()` - Resume playback

### VeepaPTZService

Controls camera pan/tilt/zoom functions.

```dart
import 'package:veepa_camera_poc/services/veepa_ptz_service.dart';

final ptz = VeepaPTZService(connectionManager: manager);

// Move camera
await ptz.moveUp(speed: 50);
await ptz.moveLeft(speed: 30);

// Stop movement
await ptz.stop();

// Zoom
await ptz.zoomIn();
await ptz.zoomOut();
await ptz.stopZoom();

// Presets
await ptz.goToPreset(1);
await ptz.savePreset(2);
```

#### Properties
- `currentDirection` - Current movement direction
- `currentZoom` - Current zoom state
- `speed` - Movement speed (0-100)

## WiFi Provisioning Services

### WifiDiscoveryService

Monitors WiFi connections to detect camera APs.

```dart
import 'package:veepa_camera_poc/services/wifi_discovery_service.dart';

final wifi = WifiDiscoveryService();

// Start monitoring
await wifi.startMonitoring();

// Check if connected to camera AP
if (wifi.isConnectedToVeepaAP) {
  print('Connected to camera: ${wifi.currentWifi.ssid}');
}

// Callbacks
wifi.onVeepaAPDetected = () {
  print('Camera AP detected!');
};
```

### CameraConfigService

Configures camera WiFi settings via CGI commands.

```dart
import 'package:veepa_camera_poc/services/camera_config_service.dart';

final config = CameraConfigServiceFactory.forAPMode();

// Set WiFi credentials
final result = await config.setWifiConfig(
  ssid: 'HomeNetwork',
  password: 'password123',
  encryption: WifiEncryption.wpa2,
);

// Reboot camera
await config.rebootCamera();
```

## QR Code Services

### QRCodeParser

Parses QR codes from Veepa cameras.

```dart
import 'package:veepa_camera_poc/utils/qr_code_parser.dart';

final data = QRCodeParser.parse('VSTC:ABC123:admin:ModelX');

print(data.deviceId);  // ABC123
print(data.password);  // admin
print(data.model);     // ModelX
```

#### Supported Formats
- VSTC format: `VSTC:DEVICE_ID:PASSWORD:MODEL`
- URL format: `vstc://DEVICE_ID/password/model`
- JSON format: `{"id":"DEVICE_ID","pwd":"PASSWORD"}`

### DeviceStorageService

Persists device information locally.

```dart
import 'package:veepa_camera_poc/services/device_storage_service.dart';

final storage = DeviceStorageService();
await storage.initialize();

// Save device
await storage.saveDevice(StoredDevice(
  id: 'ABC123',
  name: 'Camera 1',
  password: 'admin',
  addedAt: DateTime.now(),
));

// Get all devices
final devices = await storage.getAllDevices();

// Delete device
await storage.deleteDevice('ABC123');
```

## SDK Integration

### SDKIntegrationService

Manages mock vs real SDK switching.

```dart
import 'package:veepa_camera_poc/services/sdk_integration_service.dart';

final sdk = SDKIntegrationService();

// Use mock mode for testing
sdk.setMode(SDKMode.mock);
await sdk.initialize();

// Use real mode for hardware
sdk.setMode(SDKMode.real);
await sdk.initialize();
```

## Testing Framework

### HardwareTestRunner

Runs hardware integration tests.

```dart
import 'package:veepa_camera_poc/testing/hardware_test_runner.dart';

final runner = HardwareTestRunner(
  deviceId: 'VSTC_ABC123',
  password: 'admin',
);

// Run all tests
final results = await runner.runAllTests();

print('Pass rate: ${results.passRate}%');
```

### QualityGateValidator

Validates test results against quality gates.

```dart
import 'package:veepa_camera_poc/testing/quality_gate_validator.dart';

final report = QualityGateValidator.validate(testResults: results);

if (report.allPassed) {
  print('All quality gates passed!');
} else {
  final recommendations = QualityGateValidator.getRecommendations(report);
  for (final rec in recommendations) {
    print(rec);
  }
}
```

## UI Components

### CameraPreview

Displays video stream from connected camera.

```dart
CameraPreview(
  connectionManager: manager,
  playerService: player,
  showControls: true,
)
```

### PTZControls

Joystick-style PTZ control widget.

```dart
PTZControls(
  service: ptz,
  size: 200,
  showZoom: true,
)
```

### QRScannerScreen

Full-screen QR code scanner.

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => QRScannerScreen(
      onScan: (data) {
        print('Scanned: ${data.deviceId}');
      },
    ),
  ),
);
```

## Data Models

### DeviceInfo

Camera device information.

```dart
DeviceInfo(
  deviceId: 'VSTC_ABC123',
  name: 'Living Room',
  username: 'admin',
  password: 'admin',
  ipAddress: '192.168.1.100',
)
```

### WifiInfo

WiFi connection information.

```dart
WifiInfo.connected('VEEPA_ABC123');
WifiInfo.disconnected();
```

### VeepaQRData

Parsed QR code data.

```dart
VeepaQRData(
  deviceId: 'ABC123',
  password: 'admin',
  model: 'VSTC-200',
)
```

## Enumerations

### ConnectionState
- `disconnected`
- `connecting`
- `connected`
- `disconnecting`
- `error`

### PlayerState
- `idle`
- `initializing`
- `buffering`
- `playing`
- `paused`
- `stopped`
- `error`

### PTZDirection
- `stop`
- `up`, `down`, `left`, `right`
- `upLeft`, `upRight`, `downLeft`, `downRight`

### ZoomDirection
- `stop`
- `zoomIn`
- `zoomOut`

### WifiEncryption
- `none`
- `wep`
- `wpa`
- `wpa2`
- `wpa3`
