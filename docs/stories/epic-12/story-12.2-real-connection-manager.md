# Story 12.2: Real Connection Manager

## Story
As a developer, I need to replace the mock connection manager with real SDK-based camera connections.

## Acceptance Criteria
- [ ] VeepaConnectionManager uses real CameraDevice
- [ ] LAN discovery working
- [ ] P2P connection establishment
- [ ] Connection state monitoring
- [ ] Reconnection logic
- [ ] Multiple connection modes supported

## Technical Details

### Real CameraDevice Usage
```dart
CameraDevice device = CameraDevice(
  deviceId,
  name,
  username,
  password,
  model,
  connectType: 126  // P2P mode
);

CameraConnectState state = await device.connect(
  lanScan: true,
  connectCount: 3
);
```

### Connection States
- `connecting` - Connection in progress
- `connected` - Successfully connected
- `disconnect` - Connection lost
- `connectFailed` - Connection failed
- `connectTimeout` - Connection timed out

### Implementation
1. Update VeepaConnectionManager to use real SDK
2. Add LAN scan logic
3. Implement connection retry
4. Add connection state listeners
5. Handle all failure cases

### Files to Modify
- `flutter_veepa_module/lib/services/veepa_connection_manager.dart`
- `flutter_veepa_module/test/services/veepa_connection_manager_test.dart`

## Definition of Done
- [ ] Real SDK connection working
- [ ] LAN discovery functional
- [ ] Connection states properly tracked
- [ ] Reconnection logic implemented
- [ ] Integration tests passing
- [ ] Code committed
