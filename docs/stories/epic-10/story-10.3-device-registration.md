# Story 10.3: Device Registration Flow

## Story
As a user, after scanning a QR code, I need to register/save the camera device for future connections.

## Acceptance Criteria
- [ ] Device info displayed after successful scan
- [ ] User can set custom device name
- [ ] Device saved to local storage
- [ ] Duplicate device detection
- [ ] Device list management (view, delete)

## Technical Details

### Device Storage
```dart
class StoredDevice {
  final String deviceId;
  final String name;
  final String password;
  final String model;
  final DateTime addedAt;
  final DateTime? lastConnected;
}
```

### Implementation
1. Create `DeviceStorageService` for persistence
2. Create `DeviceRegistrationScreen` UI
3. Create `DeviceListScreen` for management
4. Use shared_preferences or hive for storage

### Files to Create/Modify
- `flutter_veepa_module/lib/services/device_storage_service.dart`
- `flutter_veepa_module/lib/models/stored_device.dart`
- `flutter_veepa_module/lib/screens/device_registration_screen.dart`
- `flutter_veepa_module/lib/screens/device_list_screen.dart`
- `flutter_veepa_module/test/services/device_storage_service_test.dart`

## Definition of Done
- [ ] Device storage service implemented
- [ ] Registration screen with name input
- [ ] Device list with delete functionality
- [ ] Persistence across app restarts
- [ ] Tests passing
- [ ] Code committed
