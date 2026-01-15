# Story 14.2: QR Code Display UI

## Story
As a user, I need to see a QR code on my phone screen that I can show to my camera, so the camera can scan it and connect to my home WiFi.

## Acceptance Criteria
- [ ] Full-screen QR code display for easy scanning
- [ ] High contrast QR code (black on white)
- [ ] Screen brightness automatically increased
- [ ] Instructions for user on how to position phone
- [ ] Cancel/back option to abort provisioning
- [ ] QR code sized appropriately for camera scanning distance

## Technical Details

### UI Components

#### QRDisplayScreen
```dart
class QRDisplayScreen extends StatefulWidget {
  final String ssid;
  final String password;
  final WifiEncryption encryption;
  final VoidCallback? onCancel;
  final VoidCallback? onTimeout;
}
```

### Layout
```
┌─────────────────────────────────────────┐
│  ← Back          WiFi Setup             │
├─────────────────────────────────────────┤
│                                         │
│    Hold your phone up to the camera     │
│                                         │
│         ┌─────────────────────┐         │
│         │                     │         │
│         │    ██  ██  ████     │         │
│         │    ██  ██    ██     │         │
│         │    ██████  ████     │         │
│         │        ██  ██       │         │
│         │    ████████████     │         │
│         │                     │         │
│         └─────────────────────┘         │
│                                         │
│      Network: "HomeNetwork"             │
│                                         │
│   Keep steady until camera confirms     │
│                                         │
│         [ Cancel Setup ]                │
│                                         │
└─────────────────────────────────────────┘
```

### Screen Brightness
```dart
// Increase brightness for better scanning
import 'package:screen_brightness/screen_brightness.dart';

Future<void> _setBrightness() async {
  await ScreenBrightness().setScreenBrightness(1.0);
}

Future<void> _restoreBrightness() async {
  await ScreenBrightness().resetScreenBrightness();
}
```

### QR Code Widget
```dart
QrImageView(
  data: qrData,
  version: QrVersions.auto,
  size: 280,
  backgroundColor: Colors.white,
  errorCorrectionLevel: QrErrorCorrectLevel.H, // High error correction
)
```

### Implementation
1. Create `QRDisplayScreen` widget
2. Integrate `qr_flutter` package for rendering
3. Add brightness control
4. Add user instructions
5. Handle timeout/cancellation
6. Widget tests

### Files to Create/Modify
- `flutter_veepa_module/lib/screens/qr_display_screen.dart`
- `flutter_veepa_module/lib/widgets/qr_code_display.dart`
- `flutter_veepa_module/test/screens/qr_display_screen_test.dart`
- `flutter_veepa_module/test/widgets/qr_code_display_test.dart`
- `flutter_veepa_module/pubspec.yaml` (add qr_flutter, screen_brightness)

### Dependencies to Add
```yaml
dependencies:
  qr_flutter: ^4.1.0
  screen_brightness: ^0.2.2+1
```

## Definition of Done
- [ ] QR display screen implemented
- [ ] QR code renders correctly
- [ ] Brightness auto-adjustment works
- [ ] User instructions clear
- [ ] Cancel flow works
- [ ] Widget tests passing
- [ ] Code committed
