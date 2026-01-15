# Story 14.1: QR Code Generation Service

## Story
As a developer, I need a service that generates QR codes containing WiFi credentials so the camera can scan and connect to the home network.

## Acceptance Criteria
- [ ] Generate QR code from WiFi SSID and password
- [ ] Support multiple QR formats (standard WiFi, Veepa-specific)
- [ ] Configurable QR code size and error correction level
- [ ] Return QR code as image data for display
- [ ] Validate input credentials before generation

## Technical Details

### QR Code Formats

#### Standard WiFi QR Format
```
WIFI:T:WPA;S:MyNetwork;P:MyPassword;;
```

Where:
- `T:` = Authentication type (WPA, WEP, nopass)
- `S:` = SSID (network name)
- `P:` = Password
- `H:true` = Hidden network (optional)

#### Veepa-Specific Format (if required)
```json
{"ssid":"MyNetwork","pwd":"MyPassword","enc":"WPA2"}
```

### Dependencies
- `qr_flutter` package for QR generation
- Or custom implementation using `qr` package

### Implementation
1. Create `WifiQRGeneratorService` class
2. Implement standard WiFi QR format
3. Implement Veepa-specific format (if camera requires it)
4. Add validation for SSID/password
5. Unit tests for all formats

### Files to Create
- `flutter_veepa_module/lib/services/wifi_qr_generator_service.dart`
- `flutter_veepa_module/test/services/wifi_qr_generator_service_test.dart`

### API Design
```dart
class WifiQRGeneratorService {
  /// Generate standard WiFi QR code data
  String generateWifiQRData({
    required String ssid,
    required String password,
    WifiEncryption encryption = WifiEncryption.wpa2,
    bool isHidden = false,
  });

  /// Generate Veepa-specific QR code data (if needed)
  String generateVeepaQRData({
    required String ssid,
    required String password,
    WifiEncryption encryption = WifiEncryption.wpa2,
  });

  /// Validate WiFi credentials
  ValidationResult validateCredentials(String ssid, String password);
}
```

## Definition of Done
- [ ] QR generation service implemented
- [ ] Standard WiFi format supported
- [ ] Veepa format supported (if required)
- [ ] Input validation implemented
- [ ] Unit tests passing (>90% coverage)
- [ ] Code committed
