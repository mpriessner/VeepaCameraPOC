# Story 3.1: Implement Connection Manager

> **Epic**: 3 - Camera Connection
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Large

---

## User Story

**As a** developer,
**I want** a connection manager service that handles P2P connections,
**So that** connection logic is centralized and reusable.

---

## Acceptance Criteria

- [ ] AC1: `VeepaConnectionManager` class created with singleton pattern
- [ ] AC2: Manages P2P connection lifecycle (connect, disconnect, reconnect)
- [ ] AC3: Exposes connection state as a Stream for UI binding
- [ ] AC4: Supports connect/disconnect operations with device parameter
- [ ] AC5: Handles connection timeouts (10 second limit)
- [ ] AC6: Implements automatic reconnection on unexpected disconnect (3 retries)
- [ ] AC7: Exposes current connected device information
- [ ] AC8: Proper cleanup on disconnect

---

## Technical Specification

### Connection State Machine

```
                    ┌──────────────────────────────────┐
                    │                                  │
                    ▼                                  │
             ┌─────────────┐                          │
             │ Disconnected│◄────────────┐            │
             └──────┬──────┘             │            │
                    │                    │            │
         connect()  │                    │ disconnect() / max retries
                    ▼                    │            │
             ┌─────────────┐             │            │
             │ Connecting  │─────────────┼────────────┤
             └──────┬──────┘  timeout    │            │
                    │                    │            │
         success    │                    │            │
                    ▼                    │            │
             ┌─────────────┐             │            │
             │  Connected  │─────────────┘            │
             └──────┬──────┘  error/lost              │
                    │                                  │
         error      │                                  │
                    ▼                                  │
             ┌─────────────┐                          │
             │ Reconnecting│──────────────────────────┘
             └─────────────┘
```

### ConnectionState Enum

```dart
/// Connection state for P2P camera connection
enum ConnectionState {
  /// No active connection
  disconnected,

  /// Currently establishing connection
  connecting,

  /// Successfully connected to camera
  connected,

  /// Connection lost, attempting to reconnect
  reconnecting,

  /// Connection failed with error
  error,
}

extension ConnectionStateExtension on ConnectionState {
  bool get isConnected => this == ConnectionState.connected;
  bool get isConnecting =>
      this == ConnectionState.connecting ||
      this == ConnectionState.reconnecting;
  bool get canConnect =>
      this == ConnectionState.disconnected ||
      this == ConnectionState.error;

  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.reconnecting:
        return 'Reconnecting...';
      case ConnectionState.error:
        return 'Connection Failed';
    }
  }
}
```

### VeepaConnectionManager Service

Create `lib/services/veepa_connection_manager.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';
import 'package:flutter_veepa_module/services/veepa_sdk_manager.dart';

/// Manages P2P camera connections
class VeepaConnectionManager extends ChangeNotifier {
  static final VeepaConnectionManager _instance =
      VeepaConnectionManager._internal();
  factory VeepaConnectionManager() => _instance;
  VeepaConnectionManager._internal();

  /// Configuration
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 2);

  /// Current state
  ConnectionState _state = ConnectionState.disconnected;
  ConnectionState get state => _state;

  /// Connected device
  DiscoveredDevice? _connectedDevice;
  DiscoveredDevice? get connectedDevice => _connectedDevice;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Reconnect attempt counter
  int _reconnectAttempts = 0;
  int get reconnectAttempts => _reconnectAttempts;

  /// Connection stream for state updates
  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// SDK Manager reference
  final VeepaSDKManager _sdkManager = VeepaSDKManager();

  /// Active connection timer
  Timer? _timeoutTimer;

  /// Connect to a camera device
  Future<bool> connect(DiscoveredDevice device) async {
    if (_state == ConnectionState.connecting ||
        _state == ConnectionState.reconnecting) {
      debugPrint('[Connection] Already connecting, ignoring request');
      return false;
    }

    if (_state == ConnectionState.connected &&
        _connectedDevice?.deviceId == device.deviceId) {
      debugPrint('[Connection] Already connected to this device');
      return true;
    }

    // Disconnect from current device if connected to different one
    if (_state == ConnectionState.connected) {
      await disconnect();
    }

    _connectedDevice = device;
    _reconnectAttempts = 0;
    return _performConnection();
  }

  /// Internal connection logic
  Future<bool> _performConnection() async {
    _updateState(ConnectionState.connecting);
    _errorMessage = null;

    debugPrint('[Connection] Connecting to ${_connectedDevice?.name}...');
    debugPrint('[Connection] IP: ${_connectedDevice?.ipAddress}');

    // Start timeout timer
    _startTimeoutTimer();

    try {
      // Verify SDK is ready
      if (!_sdkManager.isReady) {
        throw Exception('SDK not initialized');
      }

      // Get P2P API
      final p2pApi = _sdkManager.p2pApi;
      if (p2pApi == null) {
        throw Exception('P2P API not available');
      }

      // Perform P2P connection
      // Note: Actual implementation depends on SDK API
      final success = await _connectWithSDK();

      _cancelTimeoutTimer();

      if (success) {
        _updateState(ConnectionState.connected);
        debugPrint('[Connection] Successfully connected!');
        return true;
      } else {
        throw Exception('Connection refused by device');
      }
    } catch (e) {
      _cancelTimeoutTimer();
      debugPrint('[Connection] Connection failed: $e');
      _errorMessage = e.toString();

      // Check if we should retry
      if (_shouldRetry()) {
        return _attemptReconnect();
      }

      _updateState(ConnectionState.error);
      return false;
    }
  }

  /// Connect using SDK (actual implementation)
  Future<bool> _connectWithSDK() async {
    // TODO: Implement actual SDK connection
    // This is a placeholder - replace with actual Veepa SDK calls

    final device = _connectedDevice;
    if (device == null) return false;

    try {
      // Simulated connection delay
      await Future.delayed(const Duration(seconds: 1));

      // In real implementation:
      // 1. Create P2P session
      // 2. Connect to device IP
      // 3. Authenticate if required
      // 4. Verify connection established

      // For POC, we'll simulate success if device has IP
      if (device.ipAddress != null) {
        debugPrint('[Connection] P2P session established');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[Connection] SDK connection error: $e');
      rethrow;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    debugPrint('[Connection] Disconnecting...');

    _cancelTimeoutTimer();
    _reconnectAttempts = 0;

    try {
      // TODO: Implement actual SDK disconnect
      await _disconnectWithSDK();
    } catch (e) {
      debugPrint('[Connection] Disconnect error: $e');
    }

    _connectedDevice = null;
    _errorMessage = null;
    _updateState(ConnectionState.disconnected);
  }

  /// Disconnect using SDK
  Future<void> _disconnectWithSDK() async {
    // TODO: Implement actual SDK disconnect
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Handle connection lost
  void onConnectionLost() {
    if (_state != ConnectionState.connected) return;

    debugPrint('[Connection] Connection lost detected');
    _attemptReconnect();
  }

  /// Attempt reconnection
  Future<bool> _attemptReconnect() async {
    if (_connectedDevice == null) {
      _updateState(ConnectionState.disconnected);
      return false;
    }

    _reconnectAttempts++;
    debugPrint('[Connection] Reconnect attempt $_reconnectAttempts/$maxReconnectAttempts');

    _updateState(ConnectionState.reconnecting);

    // Wait before retry
    await Future.delayed(reconnectDelay);

    return _performConnection();
  }

  /// Check if should retry connection
  bool _shouldRetry() {
    return _reconnectAttempts < maxReconnectAttempts &&
        _connectedDevice != null;
  }

  /// Start connection timeout timer
  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(connectionTimeout, () {
      if (_state == ConnectionState.connecting ||
          _state == ConnectionState.reconnecting) {
        debugPrint('[Connection] Connection timeout');
        _errorMessage = 'Connection timed out';

        if (_shouldRetry()) {
          _attemptReconnect();
        } else {
          _updateState(ConnectionState.error);
        }
      }
    });
  }

  /// Cancel timeout timer
  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Update connection state
  void _updateState(ConnectionState newState) {
    if (_state == newState) return;

    debugPrint('[Connection] State: ${_state.name} -> ${newState.name}');
    _state = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  /// Retry connection after error
  Future<bool> retry() async {
    if (_connectedDevice == null) {
      debugPrint('[Connection] No device to retry');
      return false;
    }

    _reconnectAttempts = 0;
    return _performConnection();
  }

  /// Clean up resources
  @override
  void dispose() {
    _cancelTimeoutTimer();
    _stateController.close();
    super.dispose();
  }
}
```

### Integration with SDK

Based on Veepa SDK analysis, the connection flow involves:

```dart
// Actual SDK integration (to be implemented based on SDK API)
class VeepaP2PConnection {
  /// Connect to camera via P2P
  static Future<bool> connect({
    required String deviceId,
    required String ipAddress,
    int port = 80,
    String? password,
  }) async {
    // 1. Initialize P2P channel
    // AppP2PApi.createChannel(ClientChannelType.P2P_CMD_CHANNEL)

    // 2. Connect to device
    // await api.connect(deviceId, ipAddress, port)

    // 3. Wait for connection state
    // Listen for ClientConnectState.CONNECT_STATUS_ONLINE

    // 4. Return success/failure
    return true;
  }
}
```

---

## Implementation Tasks

### Task 1: Create ConnectionState Enum
Create `lib/models/connection_state.dart` with state enum and extensions.

**Verification**: No lint errors

### Task 2: Create VeepaConnectionManager
Create `lib/services/veepa_connection_manager.dart` with full implementation.

**Verification**: No lint errors

### Task 3: Add SDK Integration Points
Implement `_connectWithSDK()` and `_disconnectWithSDK()` methods with actual SDK calls.

**Verification**: Methods call SDK correctly

### Task 4: Create Unit Tests
Create `test/services/veepa_connection_manager_test.dart`.

**Verification**: All tests pass

### Task 5: Integration Test
Test connection with real camera (if available).

**Verification**: Connection established

---

## Test Cases

### TC3.1.1: State Machine Transitions
**Type**: Unit Test
**Priority**: P0

```dart
// test/services/veepa_connection_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/veepa_connection_manager.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';

void main() {
  group('VeepaConnectionManager', () {
    late VeepaConnectionManager manager;

    setUp(() {
      manager = VeepaConnectionManager();
      // Reset to disconnected state
    });

    test('initial state is disconnected', () {
      expect(manager.state, ConnectionState.disconnected);
      expect(manager.connectedDevice, isNull);
      expect(manager.errorMessage, isNull);
    });

    test('state transitions to connecting on connect()', () async {
      final device = DiscoveredDevice(
        deviceId: 'TEST',
        name: 'Test Camera',
        ipAddress: '192.168.1.100',
        discoveryMethod: DiscoveryMethod.manual,
        discoveredAt: DateTime.now(),
      );

      final states = <ConnectionState>[];
      manager.stateStream.listen(states.add);

      // Start connection (don't await)
      manager.connect(device);

      // Should immediately be connecting
      expect(manager.state, ConnectionState.connecting);
    });
  });
}
```

**Given**: VeepaConnectionManager instance
**When**: Various operations performed
**Then**: State transitions correctly

---

### TC3.1.2: Connection Timeout
**Type**: Unit Test
**Priority**: P0

```dart
test('connection times out after 10 seconds', () async {
  final device = DiscoveredDevice(
    deviceId: 'TIMEOUT_TEST',
    name: 'Timeout Camera',
    ipAddress: null, // Will fail to connect
    discoveryMethod: DiscoveryMethod.manual,
    discoveredAt: DateTime.now(),
  );

  final result = await manager.connect(device);

  expect(result, isFalse);
  expect(manager.state, ConnectionState.error);
  expect(manager.errorMessage, contains('timeout'));
}, timeout: const Timeout(Duration(seconds: 45))); // Allow for retries
```

**Given**: Device that won't connect
**When**: Connection attempt made
**Then**: Times out after configured duration

---

### TC3.1.3: Reconnection Logic
**Type**: Unit Test
**Priority**: P0

```dart
test('attempts reconnection on connection loss', () async {
  final device = DiscoveredDevice(
    deviceId: 'RECONNECT_TEST',
    name: 'Reconnect Camera',
    ipAddress: '192.168.1.100',
    discoveryMethod: DiscoveryMethod.lanScan,
    discoveredAt: DateTime.now(),
  );

  // Connect successfully
  await manager.connect(device);
  expect(manager.state, ConnectionState.connected);

  // Simulate connection loss
  manager.onConnectionLost();

  // Should attempt reconnection
  expect(manager.state, ConnectionState.reconnecting);
  expect(manager.reconnectAttempts, greaterThan(0));
});
```

**Given**: Connected manager
**When**: Connection lost
**Then**: Automatic reconnection attempted

---

### TC3.1.4: Max Reconnect Attempts
**Type**: Unit Test
**Priority**: P1

```dart
test('stops reconnecting after max attempts', () async {
  // This test verifies that after maxReconnectAttempts,
  // the manager stops trying and enters error state

  // Setup device that will always fail
  final device = DiscoveredDevice(
    deviceId: 'FAIL_TEST',
    name: 'Failing Camera',
    ipAddress: null,
    discoveryMethod: DiscoveryMethod.manual,
    discoveredAt: DateTime.now(),
  );

  final result = await manager.connect(device);

  expect(result, isFalse);
  expect(manager.state, ConnectionState.error);
  expect(manager.reconnectAttempts, VeepaConnectionManager.maxReconnectAttempts);
});
```

**Given**: Device that always fails to connect
**When**: Connection attempts exhausted
**Then**: State becomes error, no more retries

---

### TC3.1.5: Disconnect Clears State
**Type**: Unit Test
**Priority**: P0

```dart
test('disconnect clears all connection state', () async {
  final device = DiscoveredDevice(
    deviceId: 'DISCONNECT_TEST',
    name: 'Test Camera',
    ipAddress: '192.168.1.100',
    discoveryMethod: DiscoveryMethod.lanScan,
    discoveredAt: DateTime.now(),
  );

  await manager.connect(device);
  await manager.disconnect();

  expect(manager.state, ConnectionState.disconnected);
  expect(manager.connectedDevice, isNull);
  expect(manager.errorMessage, isNull);
  expect(manager.reconnectAttempts, 0);
});
```

**Given**: Connected manager
**When**: disconnect() called
**Then**: All state cleared

---

### TC3.1.6: Stream Emits State Changes
**Type**: Unit Test
**Priority**: P1

```dart
test('stateStream emits all state changes', () async {
  final device = DiscoveredDevice(
    deviceId: 'STREAM_TEST',
    name: 'Stream Camera',
    ipAddress: '192.168.1.100',
    discoveryMethod: DiscoveryMethod.lanScan,
    discoveredAt: DateTime.now(),
  );

  final states = <ConnectionState>[];
  final subscription = manager.stateStream.listen(states.add);

  await manager.connect(device);
  await manager.disconnect();

  await subscription.cancel();

  // Should have: connecting -> connected -> disconnected
  expect(states, contains(ConnectionState.connecting));
  expect(states, contains(ConnectionState.connected));
  expect(states, contains(ConnectionState.disconnected));
});
```

**Given**: Stream subscription active
**When**: Connection lifecycle executed
**Then**: All states emitted to stream

---

### TC3.1.7: Prevents Duplicate Connection
**Type**: Unit Test
**Priority**: P1

```dart
test('ignores connect() while already connecting', () async {
  final device = DiscoveredDevice(
    deviceId: 'DUPLICATE_TEST',
    name: 'Test Camera',
    ipAddress: '192.168.1.100',
    discoveryMethod: DiscoveryMethod.lanScan,
    discoveredAt: DateTime.now(),
  );

  // Start first connection (don't await)
  final future1 = manager.connect(device);

  // Try to connect again immediately
  final result2 = await manager.connect(device);

  expect(result2, isFalse); // Should be rejected

  // Wait for first to complete
  await future1;
});
```

**Given**: Connection in progress
**When**: Another connect() called
**Then**: Second request rejected

---

### TC3.1.8: Integration Test with Real Camera
**Type**: Manual/Integration
**Priority**: P0

**Preconditions**:
- Veepa camera available on network
- Camera IP known
- SDK properly integrated

**Steps**:
1. Create DiscoveredDevice with real camera IP
2. Call `manager.connect(device)`
3. Observe console logs
4. Verify state becomes "connected"
5. Call `manager.disconnect()`
6. Verify clean disconnection

**Expected Results**:
- [ ] Console shows connection progress
- [ ] State transitions: disconnected -> connecting -> connected
- [ ] `connectedDevice` contains device info
- [ ] Disconnect cleanly transitions to disconnected
- [ ] No memory leaks or hanging timers

---

### TC3.1.9: Error Message Clarity
**Type**: Manual
**Priority**: P2

**Steps**:
1. Try connecting to non-existent IP
2. Observe error message
3. Try connecting with SDK not initialized
4. Observe error message

**Expected Results**:
- [ ] Error messages are human-readable
- [ ] Error messages indicate actual problem
- [ ] No stack traces in user-facing messages

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] Connection state machine works correctly
- [ ] Timeout handling prevents hangs
- [ ] Reconnection logic functional
- [ ] Stream provides real-time state updates
- [ ] Code committed with message: "feat(epic-3): Implement connection manager - Story 3.1"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 1.3 (SDK must be initialized), Story 2.1-2.3 (Device discovery)
- **Blocks**: Story 3.2 (Connection UI), Story 4.1 (Video Player)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SDK connection API unclear | High | Medium | Study demo app implementation |
| P2P connection unstable | Medium | Medium | Implement robust retry logic |
| Timeout too short | Medium | Low | Make timeout configurable |
| Memory leak in stream | High | Low | Proper disposal in dispose() |

---

## References

- [Veepa SDK app_p2p_api.dart](/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/app_p2p_api.dart)
- [Flutter StreamController](https://api.dart.dev/stable/dart-async/StreamController-class.html)
- [State Machine Pattern](https://refactoring.guru/design-patterns/state)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC3.1.1 | | | |
| TC3.1.2 | | | |
| TC3.1.3 | | | |
| TC3.1.4 | | | |
| TC3.1.5 | | | |
| TC3.1.6 | | | |
| TC3.1.7 | | | |
| TC3.1.8 | | | |
| TC3.1.9 | | | |

---
