# Story 15.6: PTZ Controls Integration

> **Epic**: 15 - SDK Integration Completion
> **Phase**: C (After Video Validated)
> **Status**: Ready
> **Priority**: P1 - Should Have
> **Estimated Effort**: Medium (1-2 hours)
> **Depends On**: Story 15.1 (needs connection), Independent of Video

---

## User Story

**As a** user,
**I want** to control the camera's pan, tilt, and zoom,
**So that** I can adjust the camera view remotely.

---

## Background

The Veepa SDK provides PTZ control through `CameraDevice` commands. Currently, `VeepaPTZService` has stub implementations. We need to wire it to real SDK calls.

---

## Acceptance Criteria

- [ ] AC1: Pan left/right sends real SDK commands
- [ ] AC2: Tilt up/down sends real SDK commands
- [ ] AC3: Zoom in/out sends real SDK commands
- [ ] AC4: Stop command halts movement
- [ ] AC5: Speed parameter affects movement rate
- [ ] AC6: Response latency < 500ms (quality gate)
- [ ] AC7: PTZ UI on video screen works

---

## Technical Specification

### 1. Study SDK PTZ API

From `lib/sdk/camera_device/`:
```dart
// PTZ command codes (from basis_device.dart or similar)
class PTZCommand {
  static const int UP = 1;
  static const int DOWN = 2;
  static const int LEFT = 3;
  static const int RIGHT = 4;
  static const int STOP = 0;
  static const int ZOOM_IN = 5;
  static const int ZOOM_OUT = 6;
}

// CameraDevice has sendPTZ method
class CameraDevice {
  Future<bool> sendPTZ(int clientHandle, int command, int speed);
}
```

### 2. Update VeepaPTZService

```dart
// lib/services/veepa_ptz_service.dart

import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/sdk/camera_device/basis_device.dart';

class VeepaPTZService extends ChangeNotifier {
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// Send PTZ command to camera
  Future<bool> sendCommand(PTZDirection direction, {int speed = 5}) async {
    final clientHandle = _connectionManager.clientHandle;
    if (clientHandle == null || clientHandle <= 0) {
      debugPrint('[PTZ] No connection');
      return false;
    }

    final commandCode = _directionToCode(direction);
    final startTime = DateTime.now();

    debugPrint('[PTZ] Sending: $direction, speed: $speed');

    try {
      // Get camera device from SDK
      final cameraDevice = CameraDevice();
      final result = await cameraDevice.sendPTZ(clientHandle, commandCode, speed);

      final latency = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint('[PTZ] Response in ${latency}ms, result: $result');

      // Track latency for quality gate
      _lastLatency = latency;
      notifyListeners();

      return result;
    } catch (e) {
      debugPrint('[PTZ] Error: $e');
      return false;
    }
  }

  int _directionToCode(PTZDirection direction) {
    switch (direction) {
      case PTZDirection.up: return PTZCommand.UP;
      case PTZDirection.down: return PTZCommand.DOWN;
      case PTZDirection.left: return PTZCommand.LEFT;
      case PTZDirection.right: return PTZCommand.RIGHT;
      case PTZDirection.stop: return PTZCommand.STOP;
    }
  }

  /// Zoom control
  Future<bool> zoom(bool zoomIn, {int speed = 5}) async {
    final clientHandle = _connectionManager.clientHandle;
    if (clientHandle == null) return false;

    final command = zoomIn ? PTZCommand.ZOOM_IN : PTZCommand.ZOOM_OUT;

    try {
      final cameraDevice = CameraDevice();
      return await cameraDevice.sendPTZ(clientHandle, command, speed);
    } catch (e) {
      debugPrint('[PTZ] Zoom error: $e');
      return false;
    }
  }

  /// Stop all movement
  Future<bool> stop() async {
    return sendCommand(PTZDirection.stop);
  }

  /// Latency tracking for quality gate
  int _lastLatency = 0;
  int get lastLatency => _lastLatency;
}
```

### 3. Add PTZ Controls to Video Screen

```dart
// In video_screen.dart, add PTZ control overlay

Widget _buildPTZControls() {
  return Positioned(
    right: 16,
    bottom: 100,
    child: Column(
      children: [
        // Up
        _ptzButton(Icons.arrow_upward, () => _ptzService.sendCommand(PTZDirection.up)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left
            _ptzButton(Icons.arrow_back, () => _ptzService.sendCommand(PTZDirection.left)),
            const SizedBox(width: 40),
            // Right
            _ptzButton(Icons.arrow_forward, () => _ptzService.sendCommand(PTZDirection.right)),
          ],
        ),
        // Down
        _ptzButton(Icons.arrow_downward, () => _ptzService.sendCommand(PTZDirection.down)),
        const SizedBox(height: 16),
        // Zoom
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ptzButton(Icons.zoom_out, () => _ptzService.zoom(false)),
            const SizedBox(width: 16),
            _ptzButton(Icons.zoom_in, () => _ptzService.zoom(true)),
          ],
        ),
      ],
    ),
  );
}

Widget _ptzButton(IconData icon, VoidCallback onPressed) {
  return GestureDetector(
    onTapDown: (_) => onPressed(),
    onTapUp: (_) => _ptzService.stop(),
    onTapCancel: () => _ptzService.stop(),
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white),
    ),
  );
}
```

---

## Files to Modify

1. `lib/services/veepa_ptz_service.dart` - Real SDK integration
2. `lib/screens/video_screen.dart` - Add PTZ controls
3. `test/services/veepa_ptz_service_test.dart` - Update tests

---

## Quality Gate

| Metric | Target | How to Measure |
|--------|--------|----------------|
| PTZ Latency | < 500ms | `_lastLatency` property |

---

## Definition of Done

- [ ] PTZ commands use real SDK
- [ ] All directions work (up/down/left/right)
- [ ] Zoom in/out works
- [ ] Stop command works
- [ ] Latency < 500ms
- [ ] PTZ controls visible on video screen
