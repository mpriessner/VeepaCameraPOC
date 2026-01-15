# Story 14.3: Camera Connection Detection

## Story
As a user, I need the app to automatically detect when my camera has successfully connected to my home WiFi after scanning the QR code, so I know provisioning succeeded.

## Acceptance Criteria
- [ ] Poll for camera on home network after QR displayed
- [ ] Support multiple detection methods (P2P, LAN scan, cloud)
- [ ] Configurable timeout (default 60 seconds)
- [ ] Progress feedback during detection
- [ ] Success confirmation when camera found
- [ ] Failure handling with retry option

## Technical Details

### Detection Methods

#### Method 1: P2P Connection Attempt
```dart
// Try connecting to camera via P2P using known device ID
final success = await connectionManager.connect(deviceInfo);
```

#### Method 2: LAN Discovery
```dart
// Scan local network for camera
final devices = await discoveryService.scanNetwork();
final camera = devices.firstWhere((d) => d.deviceId == expectedDeviceId);
```

#### Method 3: Cloud Status Check (if supported)
```dart
// Check cloud service for camera online status
final status = await cloudService.getDeviceStatus(deviceId);
```

### Implementation

#### CameraConnectionDetector Service
```dart
class CameraConnectionDetector extends ChangeNotifier {
  DetectionState _state = DetectionState.idle;
  int _attemptCount = 0;

  /// Start detecting camera on home network
  Future<DetectionResult> startDetection({
    required String deviceId,
    required String password,
    Duration timeout = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 3),
  });

  /// Cancel ongoing detection
  void cancelDetection();

  /// Get current detection progress (0.0 - 1.0)
  double get progress;
}

enum DetectionState {
  idle,
  detecting,
  found,
  timeout,
  error,
}

class DetectionResult {
  final bool success;
  final String? ipAddress;
  final Duration? connectionTime;
  final String? errorMessage;
}
```

### Detection Flow
```
┌──────────────────────────────────────────────────────────────┐
│                    DETECTION FLOW                            │
└──────────────────────────────────────────────────────────────┘

1. User shows QR to camera
2. Start detection timer (60 seconds)
3. Loop every 3 seconds:
   ├─ Attempt P2P connection
   ├─ If fails, try LAN discovery
   ├─ If fails, continue loop
   └─ If success, return result
4. If timeout reached:
   └─ Return failure with retry option
```

### User Feedback States
| State | UI Display |
|-------|------------|
| Detecting | Spinner + "Waiting for camera to connect..." |
| Attempt N | "Checking... (attempt 5/20)" |
| Found | Checkmark + "Camera connected!" |
| Timeout | Warning + "Camera not found" + Retry button |

### Files to Create
- `flutter_veepa_module/lib/services/camera_connection_detector.dart`
- `flutter_veepa_module/lib/widgets/detection_progress_indicator.dart`
- `flutter_veepa_module/test/services/camera_connection_detector_test.dart`

### Integration with Existing Services
- Uses `VeepaConnectionManager` for P2P attempts
- Uses `DeviceDiscoveryService` for LAN scanning
- Uses `DeviceStorageService` to get device credentials

## Definition of Done
- [ ] Detection service implemented
- [ ] Multiple detection methods supported
- [ ] Progress indicator works
- [ ] Timeout handling works
- [ ] Success/failure states handled
- [ ] Unit tests passing
- [ ] Integration tested with mock services
- [ ] Code committed
