# Story 2.1: Implement Device Discovery Service

> **Epic**: 2 - Camera Discovery
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** developer,
**I want** a service that discovers Veepa cameras on the local network,
**So that** users can see available cameras to connect to.

---

## Acceptance Criteria

- [ ] AC1: `VeepaDiscoveryService` class created with LAN scan functionality
- [ ] AC2: Service returns list of discovered `DiscoveredDevice` objects
- [ ] AC3: Discovery times out after configurable duration (default 5 seconds)
- [ ] AC4: Service exposes stream for real-time discovery updates
- [ ] AC5: Service supports manual refresh/rescan
- [ ] AC6: Error handling for network unavailable scenarios
- [ ] AC7: Unit tests cover all public methods

---

## Technical Specification

### Discovery Mechanism

Based on SDK analysis, Veepa SDK uses:
1. **UDP Broadcast** - Sends discovery packets on local network
2. **P2P Server Lookup** - Queries cloud for device registration (optional)
3. **Direct IP** - Connect directly if IP is known

### DiscoveredDevice Model

Create `lib/models/discovered_device.dart`:

```dart
/// Represents a Veepa camera discovered on the network
class DiscoveredDevice {
  /// Unique device identifier (MAC address or cloud ID)
  final String deviceId;

  /// Device display name
  final String name;

  /// Local IP address (if discovered via LAN)
  final String? ipAddress;

  /// Device model identifier
  final String? model;

  /// Whether device is online
  final bool isOnline;

  /// Discovery method used
  final DiscoveryMethod discoveryMethod;

  /// Discovery timestamp
  final DateTime discoveredAt;

  const DiscoveredDevice({
    required this.deviceId,
    required this.name,
    this.ipAddress,
    this.model,
    this.isOnline = true,
    required this.discoveryMethod,
    required this.discoveredAt,
  });

  /// Create from SDK response
  factory DiscoveredDevice.fromSDK(Map<String, dynamic> data) {
    return DiscoveredDevice(
      deviceId: data['id'] ?? data['deviceId'] ?? '',
      name: data['name'] ?? data['deviceName'] ?? 'Unknown Camera',
      ipAddress: data['ip'] ?? data['ipAddress'],
      model: data['model'],
      isOnline: data['online'] ?? true,
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );
  }

  /// Create for manual IP entry
  factory DiscoveredDevice.manual(String ip, {String? name}) {
    return DiscoveredDevice(
      deviceId: ip, // Use IP as ID for manual entries
      name: name ?? 'Camera at $ip',
      ipAddress: ip,
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );
  }

  @override
  String toString() => 'DiscoveredDevice(id: $deviceId, name: $name, ip: $ipAddress)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

/// How the device was discovered
enum DiscoveryMethod {
  lanScan,    // Found via UDP broadcast
  cloudLookup, // Found via cloud server
  manual,     // User entered IP manually
}
```

### VeepaDiscoveryService

Create `lib/services/veepa_discovery_service.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_veepa_module/sdk/veepa_sdk.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';
import 'package:flutter_veepa_module/services/veepa_sdk_manager.dart';

/// Service for discovering Veepa cameras on the network
class VeepaDiscoveryService extends ChangeNotifier {
  final VeepaSDKManager _sdkManager;

  /// Discovery state
  DiscoveryState _state = DiscoveryState.idle;
  DiscoveryState get state => _state;

  /// List of discovered devices
  final List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  /// Error message if discovery failed
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Stream controller for real-time device discovery
  final _deviceStreamController = StreamController<DiscoveredDevice>.broadcast();
  Stream<DiscoveredDevice> get deviceStream => _deviceStreamController.stream;

  /// Discovery timeout duration
  Duration discoveryTimeout;

  /// Timer for timeout
  Timer? _timeoutTimer;

  VeepaDiscoveryService({
    VeepaSDKManager? sdkManager,
    this.discoveryTimeout = const Duration(seconds: 5),
  }) : _sdkManager = sdkManager ?? VeepaSDKManager();

  /// Start device discovery
  /// Returns list of discovered devices after timeout
  Future<List<DiscoveredDevice>> startDiscovery() async {
    if (_state == DiscoveryState.scanning) {
      debugPrint('[Discovery] Already scanning, skipping...');
      return _devices;
    }

    // Verify SDK is ready
    if (!_sdkManager.isReady) {
      _state = DiscoveryState.error;
      _errorMessage = 'SDK not initialized';
      notifyListeners();
      return [];
    }

    _state = DiscoveryState.scanning;
    _errorMessage = null;
    _devices.clear();
    notifyListeners();

    debugPrint('[Discovery] Starting LAN scan...');

    try {
      // Start timeout timer
      _startTimeoutTimer();

      // Perform LAN discovery using SDK
      await _performLANDiscovery();

      // Wait for timeout or completion
      await Future.delayed(discoveryTimeout);

      _state = _devices.isEmpty ? DiscoveryState.noDevicesFound : DiscoveryState.completed;
      debugPrint('[Discovery] Scan complete. Found ${_devices.length} device(s)');

    } catch (e, stackTrace) {
      _state = DiscoveryState.error;
      _errorMessage = e.toString();
      debugPrint('[Discovery] Error during scan: $e');
      debugPrint('[Discovery] Stack trace: $stackTrace');
    } finally {
      _cancelTimeoutTimer();
      notifyListeners();
    }

    return _devices;
  }

  /// Perform LAN discovery using SDK
  Future<void> _performLANDiscovery() async {
    try {
      final p2pApi = _sdkManager.p2pApi;
      if (p2pApi == null) {
        throw Exception('P2P API not available');
      }

      // TODO: Implement actual SDK discovery call
      // This is a placeholder - actual implementation depends on SDK API
      // Example: final results = await p2pApi.searchDevices();

      // For now, simulate discovery delay
      // In real implementation, SDK callback will add devices
      debugPrint('[Discovery] Scanning local network...');

      // Simulated discovery for testing (remove in production)
      // Uncomment below to test UI with fake data
      /*
      await Future.delayed(const Duration(seconds: 1));
      _addDiscoveredDevice(DiscoveredDevice(
        deviceId: 'TEST-001',
        name: 'Test Camera 1',
        ipAddress: '192.168.1.100',
        model: 'IPC-C123',
        discoveryMethod: DiscoveryMethod.lanScan,
        discoveredAt: DateTime.now(),
      ));
      */

    } catch (e) {
      debugPrint('[Discovery] LAN discovery error: $e');
      rethrow;
    }
  }

  /// Add a discovered device (called by SDK callback or manually)
  void _addDiscoveredDevice(DiscoveredDevice device) {
    // Avoid duplicates
    if (!_devices.contains(device)) {
      _devices.add(device);
      _deviceStreamController.add(device);
      debugPrint('[Discovery] Found device: ${device.name} (${device.ipAddress})');
      notifyListeners();
    }
  }

  /// Add device via manual IP entry
  Future<DiscoveredDevice?> addManualDevice(String ipAddress, {String? name}) async {
    // Validate IP format
    if (!_isValidIP(ipAddress)) {
      _errorMessage = 'Invalid IP address format';
      notifyListeners();
      return null;
    }

    final device = DiscoveredDevice.manual(ipAddress, name: name);
    _addDiscoveredDevice(device);
    return device;
  }

  /// Validate IP address format
  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }

    return true;
  }

  /// Stop ongoing discovery
  void stopDiscovery() {
    if (_state == DiscoveryState.scanning) {
      _cancelTimeoutTimer();
      _state = _devices.isEmpty ? DiscoveryState.noDevicesFound : DiscoveryState.completed;
      debugPrint('[Discovery] Scan stopped manually');
      notifyListeners();
    }
  }

  /// Clear discovered devices and reset state
  void clearDevices() {
    _devices.clear();
    _state = DiscoveryState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(discoveryTimeout, () {
      if (_state == DiscoveryState.scanning) {
        stopDiscovery();
      }
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  void dispose() {
    _cancelTimeoutTimer();
    _deviceStreamController.close();
    super.dispose();
  }
}

/// Discovery state
enum DiscoveryState {
  idle,
  scanning,
  completed,
  noDevicesFound,
  error,
}

/// Extension for human-readable state names
extension DiscoveryStateExtension on DiscoveryState {
  String get displayName {
    switch (this) {
      case DiscoveryState.idle:
        return 'Ready to scan';
      case DiscoveryState.scanning:
        return 'Scanning...';
      case DiscoveryState.completed:
        return 'Scan complete';
      case DiscoveryState.noDevicesFound:
        return 'No cameras found';
      case DiscoveryState.error:
        return 'Scan failed';
    }
  }

  bool get isScanning => this == DiscoveryState.scanning;
  bool get hasDevices => this == DiscoveryState.completed;
  bool get isEmpty => this == DiscoveryState.noDevicesFound;
  bool get isError => this == DiscoveryState.error;
}
```

---

## Implementation Tasks

### Task 1: Create Models Directory
```bash
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/models
```

### Task 2: Create DiscoveredDevice Model
Create `lib/models/discovered_device.dart` with the code above.

**Verification**: No compile errors

### Task 3: Create VeepaDiscoveryService
Create `lib/services/veepa_discovery_service.dart`.

**Verification**: No compile errors

### Task 4: Add Export to Main SDK File
Update `lib/sdk/veepa_sdk.dart` or create services barrel file.

### Task 5: Create Unit Tests
Create comprehensive tests for the discovery service.

### Task 6: Verify with SDK Integration
Test with actual SDK discovery methods (may require real camera).

---

## Test Cases

### TC2.1.1: Discovery Service Initial State
**Type**: Unit Test
**Priority**: P0

```dart
// test/services/veepa_discovery_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/veepa_discovery_service.dart';

void main() {
  group('VeepaDiscoveryService', () {
    test('initial state is idle with empty device list', () {
      final service = VeepaDiscoveryService();

      expect(service.state, DiscoveryState.idle);
      expect(service.devices, isEmpty);
      expect(service.errorMessage, isNull);
    });
  });
}
```

---

### TC2.1.2: IP Validation
**Type**: Unit Test
**Priority**: P1

```dart
test('validates IP address format correctly', () async {
  final service = VeepaDiscoveryService();

  // Valid IPs
  final valid1 = await service.addManualDevice('192.168.1.1');
  expect(valid1, isNotNull);

  final valid2 = await service.addManualDevice('10.0.0.1');
  expect(valid2, isNotNull);

  // Invalid IPs
  final invalid1 = await service.addManualDevice('256.1.1.1');
  expect(invalid1, isNull);

  final invalid2 = await service.addManualDevice('192.168.1');
  expect(invalid2, isNull);

  final invalid3 = await service.addManualDevice('not.an.ip.address');
  expect(invalid3, isNull);
});
```

---

### TC2.1.3: Discovery State Transitions
**Type**: Unit Test
**Priority**: P0

```dart
test('state transitions correctly during discovery', () async {
  final service = VeepaDiscoveryService(
    discoveryTimeout: const Duration(milliseconds: 100),
  );

  // Mock SDK manager as ready
  // In real test, use a mock

  expect(service.state, DiscoveryState.idle);

  // Start discovery would transition to scanning
  // Then to completed or noDevicesFound after timeout
});
```

---

### TC2.1.4: Device Stream Emits New Devices
**Type**: Unit Test
**Priority**: P1

```dart
test('device stream emits when device added', () async {
  final service = VeepaDiscoveryService();

  final devices = <DiscoveredDevice>[];
  service.deviceStream.listen((device) {
    devices.add(device);
  });

  await service.addManualDevice('192.168.1.100', name: 'Test Camera');

  await Future.delayed(const Duration(milliseconds: 50));

  expect(devices.length, 1);
  expect(devices.first.ipAddress, '192.168.1.100');
});
```

---

### TC2.1.5: No Duplicate Devices
**Type**: Unit Test
**Priority**: P1

```dart
test('does not add duplicate devices', () async {
  final service = VeepaDiscoveryService();

  await service.addManualDevice('192.168.1.100');
  await service.addManualDevice('192.168.1.100');
  await service.addManualDevice('192.168.1.100');

  expect(service.devices.length, 1);
});
```

---

### TC2.1.6: Clear Devices Resets State
**Type**: Unit Test
**Priority**: P1

```dart
test('clearDevices resets state and list', () async {
  final service = VeepaDiscoveryService();

  await service.addManualDevice('192.168.1.100');
  expect(service.devices.length, 1);

  service.clearDevices();

  expect(service.devices, isEmpty);
  expect(service.state, DiscoveryState.idle);
});
```

---

### TC2.1.7: DiscoveredDevice Model
**Type**: Unit Test
**Priority**: P0

```dart
// test/models/discovered_device_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';

void main() {
  group('DiscoveredDevice', () {
    test('creates from SDK data', () {
      final device = DiscoveredDevice.fromSDK({
        'id': 'ABC123',
        'name': 'Living Room Camera',
        'ip': '192.168.1.50',
        'model': 'IPC-200',
        'online': true,
      });

      expect(device.deviceId, 'ABC123');
      expect(device.name, 'Living Room Camera');
      expect(device.ipAddress, '192.168.1.50');
      expect(device.model, 'IPC-200');
      expect(device.isOnline, true);
      expect(device.discoveryMethod, DiscoveryMethod.lanScan);
    });

    test('creates manual device', () {
      final device = DiscoveredDevice.manual('10.0.0.5', name: 'Office Cam');

      expect(device.deviceId, '10.0.0.5');
      expect(device.name, 'Office Cam');
      expect(device.ipAddress, '10.0.0.5');
      expect(device.discoveryMethod, DiscoveryMethod.manual);
    });

    test('equality based on deviceId', () {
      final device1 = DiscoveredDevice.manual('192.168.1.1');
      final device2 = DiscoveredDevice.manual('192.168.1.1');
      final device3 = DiscoveredDevice.manual('192.168.1.2');

      expect(device1, equals(device2));
      expect(device1, isNot(equals(device3)));
    });
  });
}
```

---

### TC2.1.8: Discovery Timeout
**Type**: Unit Test
**Priority**: P1

```dart
test('discovery times out after specified duration', () async {
  final service = VeepaDiscoveryService(
    discoveryTimeout: const Duration(milliseconds: 200),
  );

  final stopwatch = Stopwatch()..start();

  // Mock SDK manager - would need proper mocking
  // await service.startDiscovery();

  // expect(stopwatch.elapsedMilliseconds, lessThan(300));
  // expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(200));
});
```

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC7) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] `DiscoveredDevice` model created with all fields
- [ ] `VeepaDiscoveryService` created with full functionality
- [ ] Discovery timeout works correctly
- [ ] Stream emits devices as discovered
- [ ] Code committed with message: "feat(epic-2): Implement device discovery service - Story 2.1"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 1.3 (Verify SDK Initialization)
- **Blocks**: Story 2.2 (Create Discovery UI)

---

## References

- [Veepa SDK Device Search](/Users/mpriessner/windsurf_repos/Veepaisdk/SDK_ANALYSIS.md)
- [Dart Streams](https://dart.dev/tutorials/language/streams)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC2.1.1 | | | |
| TC2.1.2 | | | |
| TC2.1.3 | | | |
| TC2.1.4 | | | |
| TC2.1.5 | | | |
| TC2.1.6 | | | |
| TC2.1.7 | | | |
| TC2.1.8 | | | |

---
