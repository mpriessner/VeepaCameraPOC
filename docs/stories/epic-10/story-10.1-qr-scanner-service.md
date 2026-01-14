# Story 10.1: QR Scanner Service

## Story
As a developer, I need a QR code scanning service that can decode Veepa camera QR codes to extract device identification information.

## Acceptance Criteria
- [ ] QR scanner service created in Flutter
- [ ] Parses Veepa QR code format (device ID, password, model)
- [ ] Handles invalid/malformed QR codes gracefully
- [ ] Returns structured CameraDevice data
- [ ] Unit tests for QR parsing logic

## Technical Details

### QR Code Format
Veepa cameras typically encode device info as:
```
VSTC:deviceId:password:model
// or JSON format
{"id":"VSTC123456","pwd":"admin","model":"VeepaCam"}
```

### Implementation
1. Create `QRScannerService` class
2. Create `QRCodeParser` for decoding Veepa format
3. Handle multiple QR formats (string-based, JSON-based)
4. Validate device ID format

### Files to Create/Modify
- `flutter_veepa_module/lib/services/qr_scanner_service.dart`
- `flutter_veepa_module/lib/utils/qr_code_parser.dart`
- `flutter_veepa_module/test/services/qr_scanner_service_test.dart`
- `flutter_veepa_module/test/utils/qr_code_parser_test.dart`

## Dependencies
- mobile_scanner package (or similar)

## Definition of Done
- [ ] QRScannerService implemented
- [ ] QRCodeParser handles all known formats
- [ ] Error handling for invalid codes
- [ ] Unit tests passing
- [ ] Code committed
