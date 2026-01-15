# Story 14.4: Visual Provisioning Flow

## Story
As a user, I want a guided step-by-step flow to provision my camera using QR codes, so I can easily connect my camera to my home WiFi without typing passwords.

## Acceptance Criteria
- [ ] Step-by-step wizard UI
- [ ] Integration with QR scanning (read camera QR)
- [ ] WiFi network selection
- [ ] QR code generation and display
- [ ] Camera connection detection
- [ ] Success/failure handling with clear next steps
- [ ] Fallback to CGI method if QR fails

## Technical Details

### Complete User Flow
```
┌──────────────────────────────────────────────────────────────┐
│                  VISUAL PROVISIONING FLOW                    │
└──────────────────────────────────────────────────────────────┘

Step 1: Scan Camera QR
┌─────────────────────────┐
│  Scan your camera's     │
│  QR code                │
│  ┌───────────────────┐  │
│  │   [Camera View]   │  │
│  │    Scanning...    │  │
│  └───────────────────┘  │
│         [Cancel]        │
└─────────────────────────┘
         │
         ▼
Step 2: Connect to Camera AP
┌─────────────────────────┐
│  Connect to camera WiFi │
│                         │
│  Open Settings and      │
│  connect to:            │
│  "VEEPA_ABC123"         │
│                         │
│  [Open WiFi Settings]   │
│  [I'm Connected]        │
└─────────────────────────┘
         │
         ▼
Step 3: Enter Home WiFi
┌─────────────────────────┐
│  Select your home WiFi  │
│                         │
│  Network: [HomeWiFi  ▼] │
│  Password: [••••••••••] │
│                         │
│  [Generate QR Code]     │
└─────────────────────────┘
         │
         ▼
Step 4: Show QR to Camera
┌─────────────────────────┐
│  Show this to camera    │
│                         │
│    ┌───────────────┐    │
│    │   QR CODE     │    │
│    │   ████████    │    │
│    └───────────────┘    │
│                         │
│  Network: "HomeWiFi"    │
│  [Cancel] [Use CGI ➜]   │
└─────────────────────────┘
         │
         ▼
Step 5: Waiting for Camera
┌─────────────────────────┐
│  Waiting for camera...  │
│                         │
│     ◐ Detecting...      │
│                         │
│  The camera will reboot │
│  and connect to WiFi    │
│                         │
│  Attempt 5/20           │
│  ━━━━━━━━━━━░░░░░░░░░   │
│                         │
│  [Cancel] [Try CGI ➜]   │
└─────────────────────────┘
         │
         ▼
Step 6: Success!
┌─────────────────────────┐
│      ✓ Connected!       │
│                         │
│  Your camera is now     │
│  connected to HomeWiFi  │
│                         │
│  [View Camera]          │
└─────────────────────────┘
```

### Wizard Implementation

#### VisualProvisioningWizard
```dart
class VisualProvisioningWizard extends StatefulWidget {
  final VeepaQRData? initialDevice; // If already scanned
  final VoidCallback onComplete;
  final VoidCallback onCancel;
}

class _VisualProvisioningWizardState extends State<VisualProvisioningWizard> {
  ProvisioningStep _currentStep = ProvisioningStep.scanCamera;
  VeepaQRData? _deviceData;
  String? _selectedSSID;
  String? _wifiPassword;

  final _qrGenerator = WifiQRGeneratorService();
  final _connectionDetector = CameraConnectionDetector();
}

enum ProvisioningStep {
  scanCamera,      // Step 1
  connectToAP,     // Step 2
  enterWifiCreds,  // Step 3
  showQR,          // Step 4
  detecting,       // Step 5
  success,         // Step 6
  failure,         // Error state
}
```

### CGI Fallback
If QR scanning fails (timeout), offer CGI method:
```dart
void _fallbackToCGI() async {
  final configService = CameraConfigServiceFactory.forAPMode();
  final result = await configService.setWifiConfig(
    ssid: _selectedSSID!,
    password: _wifiPassword!,
    encryption: WifiEncryption.wpa2,
  );
  // Continue with detection...
}
```

### Files to Create/Modify
- `flutter_veepa_module/lib/screens/visual_provisioning_wizard.dart`
- `flutter_veepa_module/lib/widgets/provisioning_step_indicator.dart`
- `flutter_veepa_module/lib/screens/discovery_screen.dart` (add entry point)
- `flutter_veepa_module/test/screens/visual_provisioning_wizard_test.dart`

### Navigation Integration
```dart
// From DiscoveryScreen
void _startProvisioning() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => VisualProvisioningWizard(
        onComplete: () {
          Navigator.pop(context);
          _refreshDevices();
        },
        onCancel: () => Navigator.pop(context),
      ),
    ),
  );
}
```

### Error Handling
| Error | User Action |
|-------|-------------|
| QR scan failed | Retry scan or manual entry |
| AP not found | Check camera is in setup mode |
| WiFi invalid | Re-enter credentials |
| Detection timeout | Retry or use CGI method |
| Connection failed | Check camera, retry |

## Definition of Done
- [ ] Wizard UI implemented with all steps
- [ ] Smooth transitions between steps
- [ ] CGI fallback works
- [ ] Error handling for each step
- [ ] Back navigation works correctly
- [ ] Integration tests passing
- [ ] End-to-end flow tested on simulator
- [ ] Code committed
