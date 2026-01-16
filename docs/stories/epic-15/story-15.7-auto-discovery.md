# Story 15.7: Auto-Discovery Integration

> **Epic**: 15 - SDK Integration Completion
> **Phase**: C (After Video Validated)
> **Status**: Ready
> **Priority**: P2 - Nice to Have
> **Estimated Effort**: Medium (1-2 hours)
> **Depends On**: None (Independent)

---

## User Story

**As a** user,
**I want** the app to automatically find Veepa cameras on my network,
**So that** I don't have to manually enter device IDs.

---

## Background

The Veepa SDK includes LAN discovery capabilities. Currently, `VeepaDiscoveryService._performLANDiscovery()` is a stub. We need to wire it to the real SDK discovery.

Note: SDK initialization issue was partially fixed - discovery should now initialize SDK on demand.

---

## Acceptance Criteria

- [ ] AC1: LAN scan finds cameras on local network
- [ ] AC2: Discovered devices show name, IP, and device ID
- [ ] AC3: Discovery completes within 5 seconds
- [ ] AC4: Manual IP entry still works as fallback
- [ ] AC5: Discovered devices can be selected for connection

---

## Technical Specification

### 1. Study SDK Discovery API

From `lib/sdk/device_wakeup_server.dart` or similar:
```dart
// SDK may have broadcast discovery
class DeviceWakeupServer {
  // Listen for device announcements on LAN
  Stream<DiscoveredDevice> startDiscovery();
  void stopDiscovery();
}

// Or it may use AppP2PApi
class AppP2PApi {
  Future<List<DeviceInfo>> scanLAN();
}
```

### 2. Update VeepaDiscoveryService

```dart
// lib/services/veepa_discovery_service.dart

Future<void> _performLANDiscovery() async {
  try {
    final p2pApi = _sdkManager.p2pApi;
    if (p2pApi == null) {
      throw Exception('P2P API not available');
    }

    debugPrint('[Discovery] Starting LAN scan via SDK...');

    // Option 1: If SDK has scanLAN method
    final devices = await p2pApi.scanLAN();
    for (final deviceInfo in devices) {
      final device = DiscoveredDevice(
        deviceId: deviceInfo.uid,
        name: deviceInfo.name ?? 'Veepa Camera',
        ipAddress: deviceInfo.ip,
        port: deviceInfo.port ?? 80,
        discoveryMethod: 'lan_scan',
      );
      addDiscoveredDevice(device);
    }

    // Option 2: If SDK uses broadcast listener
    // _sdkManager.deviceWakeupServer.startDiscovery().listen((device) {
    //   addDiscoveredDevice(device);
    // });

  } catch (e) {
    debugPrint('[Discovery] LAN discovery error: $e');
    rethrow;
  }
}
```

### 3. Support UID-Based Connection

The Veepa app uses UIDs like `OKB0379853SNLJ`. Update manual entry to accept UIDs:

```dart
// lib/widgets/manual_ip_dialog.dart

// Add toggle for IP vs UID entry
class ManualEntryDialog extends StatefulWidget {
  // ...
}

class _ManualEntryDialogState extends State<ManualEntryDialog> {
  bool _isUIDMode = false;  // Toggle between IP and UID

  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Camera'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle
          SwitchListTile(
            title: Text(_isUIDMode ? 'Device UID' : 'IP Address'),
            value: _isUIDMode,
            onChanged: (v) => setState(() => _isUIDMode = v),
          ),
          // Input field
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: _isUIDMode ? 'Device UID (e.g., OKB0379853SNLJ)' : 'IP Address',
              hintText: _isUIDMode ? 'OKB0379853SNLJ' : '192.168.1.100',
            ),
          ),
        ],
      ),
      // ...
    );
  }
}
```

### 4. Handle Both IP and UID Connections

```dart
// In VeepaConnectionManager._connectWithSDK():

final deviceId = device.deviceId;

// Check if it's a UID or IP
final isUID = !deviceId.contains('.');  // UIDs don't have dots

if (isUID) {
  // P2P connection by UID
  result = await p2pApi.connect(deviceId, _password);
} else {
  // Direct connection by IP (if SDK supports)
  result = await p2pApi.connectByIP(deviceId, _password);
}
```

---

## Files to Modify

1. `lib/services/veepa_discovery_service.dart` - Real SDK discovery
2. `lib/widgets/manual_ip_dialog.dart` - Support UID entry
3. `lib/services/veepa_connection_manager.dart` - Handle UID vs IP
4. `test/services/veepa_discovery_service_test.dart` - Update tests

---

## Testing Strategy

### Manual Testing
1. Ensure camera is on same WiFi as phone
2. Open app, go to "Find Cameras"
3. Wait for scan (should take < 5 seconds)
4. Camera should appear in list
5. If not, use manual entry with UID

### Fallback Testing
1. If LAN scan fails, manual UID entry should work
2. Test with known UID: `OKB0379853SNLJ`

---

## Definition of Done

- [ ] LAN discovery uses real SDK
- [ ] Cameras found within 5 seconds
- [ ] Manual UID entry works
- [ ] Discovered devices connect successfully
- [ ] Tests pass

---

## Notes

- LAN discovery may not work on all networks (firewall, VLAN isolation)
- UID-based P2P is more reliable than IP-based
- Original Veepa app shows UID in settings - user can always fall back to manual
