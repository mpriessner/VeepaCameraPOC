# Story 15.1: Implement Real P2P Connection

> **Epic**: 15 - SDK Integration Completion
> **Phase**: A (Tonight - Critical Path)
> **Status**: Ready
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium (1-2 hours)
> **Depends On**: None (Foundation story)

---

## User Story

**As a** developer,
**I want** the VeepaConnectionManager to use real SDK P2P connections,
**So that** the app actually connects to the physical Veepa camera.

---

## Background

Currently, `VeepaConnectionManager._connectWithSDK()` is simulated - it just delays and returns true. We need to wire it to the actual Veepa SDK's `AppP2PApi` for real P2P connections.

### Current Code Location
- File: `lib/services/veepa_connection_manager.dart`
- Method: `_connectWithSDK()` (lines ~131-150)
- SDK: `lib/sdk/app_p2p_api.dart`

---

## Acceptance Criteria

- [ ] AC1: `VeepaConnectionManager` uses real `AppP2PApi` for connection
- [ ] AC2: Connection returns actual client handle (int pointer) from SDK
- [ ] AC3: Client handle is stored for use by video player and PTZ
- [ ] AC4: Real disconnect calls SDK disconnect method
- [ ] AC5: Connection timeout uses SDK's actual connection attempt
- [ ] AC6: Unit tests updated to mock real SDK calls

---

## Technical Specification

### 1. Update VeepaConnectionManager

```dart
// lib/services/veepa_connection_manager.dart

class VeepaConnectionManager extends ChangeNotifier {
  // ADD: Store the P2P client handle
  int? _clientHandle;
  int? get clientHandle => _clientHandle;

  // MODIFY: _connectWithSDK to use real SDK
  Future<bool> _connectWithSDK() async {
    final device = _connectedDevice;
    if (device == null) return false;

    try {
      final p2pApi = _sdkManager.p2pApi;
      if (p2pApi == null) {
        throw Exception('P2P API not available');
      }

      // Use device ID for P2P connection
      // The Veepa SDK uses UID-based P2P, not direct IP
      final deviceId = device.deviceId;

      // Default password - in production this should come from user input or secure storage
      const password = 'admin';  // TODO: Get from secure storage

      debugPrint('[Connection] Calling P2P connect for device: $deviceId');

      // Call actual SDK connect
      // AppP2PApi.connect returns client handle or error code
      final result = await p2pApi.connect(deviceId, password);

      if (result > 0) {
        _clientHandle = result;
        debugPrint('[Connection] P2P connected with handle: $_clientHandle');
        return true;
      } else {
        throw Exception('P2P connection failed with code: $result');
      }
    } catch (e) {
      debugPrint('[Connection] SDK connection error: $e');
      rethrow;
    }
  }

  // MODIFY: _disconnectWithSDK to use real SDK
  Future<void> _disconnectWithSDK() async {
    if (_clientHandle != null) {
      try {
        final p2pApi = _sdkManager.p2pApi;
        await p2pApi?.disconnect(_clientHandle!);
        debugPrint('[Connection] P2P disconnected handle: $_clientHandle');
      } catch (e) {
        debugPrint('[Connection] Disconnect error: $e');
      }
      _clientHandle = null;
    }
  }
}
```

### 2. Check AppP2PApi Interface

Review `lib/sdk/app_p2p_api.dart` for:
- `connect(String deviceId, String password)` method signature
- `disconnect(int handle)` method signature
- Return value meanings (positive = success handle, negative = error)

### 3. Device ID vs IP Address

The Veepa SDK uses **UID-based P2P connection**, not direct IP:
- Original app shows UID: `OKB0379853SNLJ`
- Manual IP entry should still store device ID
- Update `DiscoveredDevice.manual()` to accept device ID

```dart
// Update manual device creation to use IP as deviceId fallback
static DiscoveredDevice manual(String ipAddress, {String? name, String? deviceId}) {
  return DiscoveredDevice(
    deviceId: deviceId ?? ipAddress,  // Use IP as fallback deviceId
    name: name ?? 'Camera at $ipAddress',
    ipAddress: ipAddress,
    port: 80,
    discoveryMethod: 'manual',
  );
}
```

---

## Files to Modify

1. `lib/services/veepa_connection_manager.dart` - Main changes
2. `lib/models/discovered_device.dart` - Device ID handling
3. `test/services/veepa_connection_manager_test.dart` - Update tests

---

## Testing Strategy

### Unit Tests
```dart
test('connects using real P2P API', () async {
  // Mock the P2P API
  final mockP2pApi = MockAppP2PApi();
  when(mockP2pApi.connect(any, any)).thenAnswer((_) async => 12345);

  // Verify connect is called with device ID
  await connectionManager.connect(testDevice);

  verify(mockP2pApi.connect(testDevice.deviceId, any)).called(1);
  expect(connectionManager.clientHandle, equals(12345));
});
```

### Manual Verification
1. Run app on physical device
2. Enter camera UID manually (e.g., `OKB0379853SNLJ`)
3. Verify connection succeeds
4. Check Xcode console for P2P handle

---

## Definition of Done

- [ ] Real P2P connect called instead of simulation
- [ ] Client handle stored and accessible
- [ ] Disconnect properly closes P2P session
- [ ] Tests pass with mocked SDK
- [ ] Manual test with real camera shows connection

---

## Notes

- The camera UID `OKB0379853SNLJ` was found in the original Veepa app
- Default password is typically 'admin' - may need user input
- P2P connection may take 5-10 seconds - existing timeout should handle this
