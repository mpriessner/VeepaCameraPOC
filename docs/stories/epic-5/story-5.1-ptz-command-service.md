# Story 5.1: Implement PTZ Command Service

> **Epic**: 5 - PTZ Controls
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** developer,
**I want** a PTZ command service that sends camera movement commands,
**So that** I can control camera pan/tilt/zoom programmatically.

---

## Acceptance Criteria

- [ ] AC1: `VeepaPTZService` class created for PTZ control
- [ ] AC2: Pan left/right commands implemented
- [ ] AC3: Tilt up/down commands implemented
- [ ] AC4: Zoom in/out commands implemented
- [ ] AC5: Stop command stops all movement
- [ ] AC6: Commands sent only when connected
- [ ] AC7: Command response time logged for diagnostics
- [ ] AC8: Speed parameter supported for movement commands

---

## Technical Specification

### PTZ Command Types

```dart
/// PTZ movement directions
enum PTZDirection {
  /// No movement (stop)
  stop,

  /// Pan camera left
  panLeft,

  /// Pan camera right
  panRight,

  /// Tilt camera up
  tiltUp,

  /// Tilt camera down
  tiltDown,

  /// Pan left and tilt up
  panLeftTiltUp,

  /// Pan left and tilt down
  panLeftTiltDown,

  /// Pan right and tilt up
  panRightTiltUp,

  /// Pan right and tilt down
  panRightTiltDown,
}

/// Zoom direction
enum ZoomDirection {
  stop,
  zoomIn,
  zoomOut,
}

extension PTZDirectionExtension on PTZDirection {
  /// Get SDK command code for this direction
  int get commandCode {
    switch (this) {
      case PTZDirection.stop:
        return 0;
      case PTZDirection.panLeft:
        return 4;
      case PTZDirection.panRight:
        return 6;
      case PTZDirection.tiltUp:
        return 2;
      case PTZDirection.tiltDown:
        return 8;
      case PTZDirection.panLeftTiltUp:
        return 1;
      case PTZDirection.panLeftTiltDown:
        return 7;
      case PTZDirection.panRightTiltUp:
        return 3;
      case PTZDirection.panRightTiltDown:
        return 9;
    }
  }
}
```

### VeepaPTZService

Create `lib/services/veepa_ptz_service.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_veepa_module/services/veepa_connection_manager.dart';

/// PTZ (Pan-Tilt-Zoom) control service for Veepa cameras
class VeepaPTZService {
  static final VeepaPTZService _instance = VeepaPTZService._internal();
  factory VeepaPTZService() => _instance;
  VeepaPTZService._internal();

  /// Configuration
  static const int defaultSpeed = 50; // 0-100 scale
  static const Duration commandDebounce = Duration(milliseconds: 50);

  /// Connection manager reference
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// Current movement state
  PTZDirection _currentDirection = PTZDirection.stop;
  PTZDirection get currentDirection => _currentDirection;

  ZoomDirection _currentZoom = ZoomDirection.stop;
  ZoomDirection get currentZoom => _currentZoom;

  /// Movement speed (0-100)
  int _speed = defaultSpeed;
  int get speed => _speed;
  set speed(int value) {
    _speed = value.clamp(0, 100);
  }

  /// Debounce timer
  Timer? _debounceTimer;

  /// Command latency tracking
  final List<int> _latencyHistory = [];
  double get averageLatency {
    if (_latencyHistory.isEmpty) return 0;
    return _latencyHistory.reduce((a, b) => a + b) / _latencyHistory.length;
  }

  /// Start PTZ movement
  Future<bool> startMovement(PTZDirection direction) async {
    if (!_canSendCommand()) {
      debugPrint('[PTZ] Cannot send command - not connected');
      return false;
    }

    if (_currentDirection == direction) {
      debugPrint('[PTZ] Already moving in this direction');
      return true;
    }

    _currentDirection = direction;

    return _sendPTZCommand(direction);
  }

  /// Stop PTZ movement
  Future<bool> stopMovement() async {
    if (_currentDirection == PTZDirection.stop) {
      return true;
    }

    _currentDirection = PTZDirection.stop;
    return _sendPTZCommand(PTZDirection.stop);
  }

  /// Start zoom
  Future<bool> startZoom(ZoomDirection direction) async {
    if (!_canSendCommand()) {
      debugPrint('[PTZ] Cannot send zoom - not connected');
      return false;
    }

    _currentZoom = direction;
    return _sendZoomCommand(direction);
  }

  /// Stop zoom
  Future<bool> stopZoom() async {
    if (_currentZoom == ZoomDirection.stop) {
      return true;
    }

    _currentZoom = ZoomDirection.stop;
    return _sendZoomCommand(ZoomDirection.stop);
  }

  /// Stop all movement and zoom
  Future<void> stopAll() async {
    await stopMovement();
    await stopZoom();
  }

  /// Check if can send commands
  bool _canSendCommand() {
    return _connectionManager.state.isConnected;
  }

  /// Send PTZ command to camera
  Future<bool> _sendPTZCommand(PTZDirection direction) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('[PTZ] Sending: ${direction.name} (speed: $_speed)');

      // TODO: Replace with actual SDK command
      // Based on Veepa SDK motor_command.dart:
      // await _connectionManager.connectedDevice?.sendMotorCommand(
      //   command: direction.commandCode,
      //   speed: _speed,
      // );

      // Simulated command
      await Future.delayed(const Duration(milliseconds: 20));

      stopwatch.stop();
      _recordLatency(stopwatch.elapsedMilliseconds);

      debugPrint('[PTZ] Command sent in ${stopwatch.elapsedMilliseconds}ms');
      return true;

    } catch (e) {
      debugPrint('[PTZ] Command failed: $e');
      return false;
    }
  }

  /// Send zoom command to camera
  Future<bool> _sendZoomCommand(ZoomDirection direction) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('[PTZ] Zoom: ${direction.name}');

      // TODO: Replace with actual SDK command
      // Based on Veepa SDK, zoom is typically:
      // - Zoom in: command code 16
      // - Zoom out: command code 32
      // - Stop: command code 0

      await Future.delayed(const Duration(milliseconds: 20));

      stopwatch.stop();
      _recordLatency(stopwatch.elapsedMilliseconds);

      debugPrint('[PTZ] Zoom sent in ${stopwatch.elapsedMilliseconds}ms');
      return true;

    } catch (e) {
      debugPrint('[PTZ] Zoom failed: $e');
      return false;
    }
  }

  /// Record command latency
  void _recordLatency(int ms) {
    _latencyHistory.add(ms);

    // Keep only last 20 measurements
    if (_latencyHistory.length > 20) {
      _latencyHistory.removeAt(0);
    }

    // Warn if latency is high
    if (ms > 500) {
      debugPrint('[PTZ] Warning: High latency ${ms}ms');
    }
  }

  /// Preset positions (if supported by camera)
  Future<bool> goToPreset(int presetNumber) async {
    if (!_canSendCommand()) return false;

    debugPrint('[PTZ] Going to preset $presetNumber');

    // TODO: Implement preset command
    return true;
  }

  /// Save current position as preset
  Future<bool> savePreset(int presetNumber) async {
    if (!_canSendCommand()) return false;

    debugPrint('[PTZ] Saving preset $presetNumber');

    // TODO: Implement preset save
    return true;
  }

  /// Reset latency history
  void resetLatencyHistory() {
    _latencyHistory.clear();
  }

  /// Clean up
  void dispose() {
    _debounceTimer?.cancel();
    stopAll();
  }
}
```

### PTZ Command Integration

Based on the Veepa SDK's motor_command.dart structure:

```dart
/// SDK integration example (to be implemented with actual SDK)
class VeepaPTZCommands {
  /// Send motor control command
  static Future<void> sendMotorCommand({
    required dynamic p2pApi,
    required int command,
    int speed = 50,
  }) async {
    // Format: [CMD_TYPE][DIRECTION][SPEED]
    // Actual format depends on SDK documentation

    // Using SDK's motor command structure:
    // MotorCommand.move(direction, speed)

    debugPrint('[PTZ] SDK motor command: $command @ $speed');
  }

  /// Command codes based on SDK
  static const int cmdPanLeft = 4;
  static const int cmdPanRight = 6;
  static const int cmdTiltUp = 2;
  static const int cmdTiltDown = 8;
  static const int cmdStop = 0;
  static const int cmdZoomIn = 16;
  static const int cmdZoomOut = 32;
}
```

---

## Implementation Tasks

### Task 1: Create PTZ Enums
Create direction and zoom enums.

**Verification**: No lint errors

### Task 2: Create VeepaPTZService
Create the PTZ service class.

**Verification**: No lint errors

### Task 3: Integrate with SDK
Implement actual SDK command sending.

**Verification**: Commands reach camera

### Task 4: Add Latency Tracking
Implement latency measurement and logging.

**Verification**: Latency recorded accurately

### Task 5: Create Unit Tests
Test command logic and state management.

**Verification**: All tests pass

---

## Test Cases

### TC5.1.1: Direction Commands
**Type**: Unit Test
**Priority**: P0

```dart
// test/services/veepa_ptz_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/veepa_ptz_service.dart';

void main() {
  group('VeepaPTZService', () {
    test('startMovement updates current direction', () async {
      final service = VeepaPTZService();

      await service.startMovement(PTZDirection.panLeft);
      expect(service.currentDirection, PTZDirection.panLeft);

      await service.stopMovement();
      expect(service.currentDirection, PTZDirection.stop);
    });

    test('all direction codes are unique', () {
      final codes = PTZDirection.values.map((d) => d.commandCode).toSet();
      expect(codes.length, PTZDirection.values.length);
    });
  });
}
```

**Given**: PTZ service
**When**: Movement commands sent
**Then**: State updated correctly

---

### TC5.1.2: Zoom Commands
**Type**: Unit Test
**Priority**: P0

```dart
test('zoom commands work correctly', () async {
  final service = VeepaPTZService();

  await service.startZoom(ZoomDirection.zoomIn);
  expect(service.currentZoom, ZoomDirection.zoomIn);

  await service.stopZoom();
  expect(service.currentZoom, ZoomDirection.stop);
});
```

**Given**: PTZ service
**When**: Zoom commands sent
**Then**: Zoom state updated

---

### TC5.1.3: Speed Parameter
**Type**: Unit Test
**Priority**: P1

```dart
test('speed is clamped to valid range', () {
  final service = VeepaPTZService();

  service.speed = 150;
  expect(service.speed, 100);

  service.speed = -10;
  expect(service.speed, 0);

  service.speed = 50;
  expect(service.speed, 50);
});
```

**Given**: PTZ service
**When**: Speed set
**Then**: Value clamped to 0-100

---

### TC5.1.4: Connection Check
**Type**: Unit Test
**Priority**: P0

```dart
test('commands rejected when not connected', () async {
  final service = VeepaPTZService();

  // Assuming not connected
  final result = await service.startMovement(PTZDirection.panLeft);

  // Should fail gracefully
  expect(result, isFalse);
});
```

**Given**: Not connected to camera
**When**: PTZ command sent
**Then**: Returns false, no crash

---

### TC5.1.5: Latency Tracking
**Type**: Unit Test
**Priority**: P2

```dart
test('latency history maintained', () async {
  final service = VeepaPTZService();
  service.resetLatencyHistory();

  // Send some commands (need connection mock)
  // Verify averageLatency calculation
});
```

**Given**: Multiple commands sent
**When**: Getting average latency
**Then**: Returns accurate average

---

### TC5.1.6: Stop All
**Type**: Unit Test
**Priority**: P1

```dart
test('stopAll stops both movement and zoom', () async {
  final service = VeepaPTZService();

  await service.startMovement(PTZDirection.panLeft);
  await service.startZoom(ZoomDirection.zoomIn);

  await service.stopAll();

  expect(service.currentDirection, PTZDirection.stop);
  expect(service.currentZoom, ZoomDirection.stop);
});
```

**Given**: Active PTZ movement and zoom
**When**: stopAll() called
**Then**: Both stopped

---

### TC5.1.7: Manual Camera Control Test
**Type**: Manual/Integration
**Priority**: P0

**Preconditions**:
- Connected to real Veepa camera
- Camera supports PTZ

**Steps**:
1. Connect to camera
2. Call startMovement(PTZDirection.panLeft)
3. Observe camera physically moving
4. Call stopMovement()
5. Verify camera stops
6. Test all directions
7. Test zoom in/out
8. Check console for latency logs

**Expected Results**:
- [ ] Camera responds to pan commands
- [ ] Camera responds to tilt commands
- [ ] Camera responds to zoom commands
- [ ] Stop command halts movement immediately
- [ ] Command latency < 500ms
- [ ] No crashes or errors

---

### TC5.1.8: Response Time Measurement
**Type**: Manual
**Priority**: P1

**Steps**:
1. Send 10 consecutive pan commands
2. Record latency for each
3. Calculate average
4. Verify average < 200ms

**Expected Results**:
- [ ] Average latency under 200ms
- [ ] No timeouts
- [ ] Consistent response times

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] Commands reach camera (with real hardware)
- [ ] Response time < 500ms
- [ ] Speed parameter affects movement
- [ ] Code committed with message: "feat(epic-5): PTZ command service - Story 5.1"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 3.1 (Must be connected)
- **Blocks**: Story 5.2 (PTZ Control UI)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SDK PTZ API unclear | High | Medium | Reference demo app and docs |
| High latency | Medium | Medium | Optimize command sending |
| Camera doesn't support PTZ | Medium | Low | Check camera capabilities first |

---

## References

- [Veepa SDK motor_command.dart](/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/camera_device/commands/motor_command.dart)
- ONVIF PTZ specification (if applicable)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC5.1.1 | | | |
| TC5.1.2 | | | |
| TC5.1.3 | | | |
| TC5.1.4 | | | |
| TC5.1.5 | | | |
| TC5.1.6 | | | |
| TC5.1.7 | | | |
| TC5.1.8 | | | |

---
