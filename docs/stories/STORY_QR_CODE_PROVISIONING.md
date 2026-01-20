# Story: QR Code WiFi Provisioning

> **⚠️ SUPERSEDED - DO NOT USE**
>
> This story was based on SDK documentation that turned out to be WRONG.
> The actual working implementation uses a **5-frame QR sequence with specific mask patterns**.
>
> **See instead:**
> - Working implementation: `lib/services/wifi_qr_generator_service.dart` (uses 5 frames, mask patterns)
> - Working screen: `lib/screens/qr_provisioning_screen.dart` (Mode 2: Official Pattern)
> - Troubleshooting guide: `docs/QR_PROVISIONING_TROUBLESHOOT.md`
> - SciSymbioLens stories: `SciSymbioLens/docs/stories/phase-4/epic-15/story-15.3a-*.md`
>
> **Key discoveries that invalidate this story:**
> - Single QR does NOT work - must use 5-frame sequence
> - Frame 2 requires Mask 4, Frame 3 requires Mask 2
> - Uses "S" for SSID (not "RS")
> - P2P detection works better than Hello API polling

**Type:** Feature Implementation
**Priority:** ~~P0~~ SUPERSEDED
**Date:** January 19, 2026
**Status:** ~~Ready for Implementation~~ **SUPERSEDED** - See above for correct approach

---

## Background & Rationale

### Why We Need This

After extensive investigation (documented in `MASTER_TROUBLESHOOTING_GUIDE.md` v7.0), we discovered that:

1. **Our CGI-based approach (`set_wifi.cgi`) does not work** for initial WiFi provisioning
2. **The official Veepa SDK uses Bluetooth or QR Code** for initial camera setup
3. **QR Code is the simpler option** compared to Bluetooth (no BLE protocol complexity)

### Where This Information Was Found

**Source file:** `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/example/lib/wifi_connect/device_connect_logic.dart`

**Key code (lines 68-81):**
```dart
void generateQrCode() async {
  String psw = textController.text;
  if (psw.isEmpty) {
    EasyLoading.showToast("密码不能为空！");
    return;
  }
  state!.wifiPsw = psw;
  state!.qrContent =
      '{"BS":"${state!.wifiBssid}","P":"${state!.wifiPsw}","U":"15463733-OEM","RS":"${state!.wifiName.value}"}';
  print("-------qrContent-----------${state!.qrContent}");
  state!.isShowQR(true);
  state!.times.value = 0;
  queryRepeat();
}
```

**Cloud polling (lines 84-100):**
```dart
void queryRepeat() {
  state!.times.value++;
  Future.delayed(Duration(seconds: 2), () async {
    String? did = await queryDevice(state!.times.value);
    if (did == null && state!.times.value < 30) {
      queryRepeat();  // Poll every 2 seconds, up to 30 times (60 seconds)
    } else if (did != null) {
      // Camera found! Navigate to binding page
      Get.offAndToNamed(AppRoutes.deviceBind, arguments: DeviceInfoArgs(did));
    }
  });
}
```

---

## How QR Code Provisioning Works

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        QR CODE PROVISIONING FLOW                        │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────┐                                          ┌──────────┐
    │   App    │                                          │  Camera  │
    └────┬─────┘                                          └────┬─────┘
         │                                                     │
         │  1. User enters WiFi SSID + Password                │
         │─────────────────────────────────────────────────────│
         │                                                     │
         │  2. App generates QR code with credentials          │
         │  ┌─────────────────────────────────────────┐        │
         │  │ {"BS":"bssid","P":"pass","U":"uid",     │        │
         │  │  "RS":"ssid"}                           │        │
         │  └─────────────────────────────────────────┘        │
         │                                                     │
         │  3. User shows QR code to camera lens               │
         │─────────────────────────────────────────────────────>
         │                                                     │
         │                    4. Camera scans QR, extracts     │
         │                       WiFi credentials              │
         │                                                     │
         │                    5. Camera connects to router     │
         │                       WiFi using credentials        │
         │                                                     │
         │                    6. Camera registers with         │
         │                       Veepa cloud ("hello" API)     │
         │                                                     │
         │  7. App polls cloud API every 2 seconds             │
         │<─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
         │     "Is camera online yet?"                         │
         │                                                     │
         │  8. Cloud responds: "Yes, camera UID = OKBxxxxx"    │
         │<────────────────────────────────────────────────────│
         │                                                     │
         │  9. App navigates to camera view                    │
         │                                                     │
    ┌────┴─────┐                                          ┌────┴─────┐
    │   App    │                                          │  Camera  │
    └──────────┘                                          └──────────┘
```

### QR Code Format

```json
{
  "RS": "MyWiFiNetwork",     // Router SSID (network name) - REQUIRED
  "P": "MyWiFiPassword",     // WiFi password - REQUIRED
  "BS": "c8eaf8e038f1",      // Router BSSID (MAC address, no colons) - OPTIONAL but recommended
  "U": "15463733-OEM",       // User ID (for cloud registration) - OPTIONAL
  "A": "840"                 // Region code - OPTIONAL (may be required for some accounts)
}
```

**Notes from Official Documentation:**
- `RS` (SSID) and `P` (password) are **required**
- `BS` (BSSID) is **optional** but recommended for faster/more reliable connection
- `U` (User ID) is **optional** - used for cloud binding, may be vendor-specific
- `A` (Region) is **optional** - include if available, may be required for some accounts

**Source:** `docs/official_documentation/flutter_sdk_parameter_usage_instructions.md`

### Cloud API Endpoints Used

**From `app_web_api.dart` (lines 411-429) in the SDK:**

1. **Hello Confirm** - Clear previous device binding intent
   - Endpoint: `https://api.eye4.cn/hello/confirm`
   - Method: POST with `{"key": "USER_ID"}`
   - Called before showing QR code to clear stale data

2. **Hello Query** - Poll for camera registration
   - Endpoint: `https://api.eye4.cn/hello/query`
   - Method: POST with `{"key": "USER_ID"}` or `{"key": "USER_ID_binding"}`
   - Polled every 2 seconds after showing QR
   - Returns camera UID when camera registers

**Important:** The SDK alternates between two query keys:
- `"15463733-OEM"` - for older devices
- `"15463733-OEM_binding"` - for newer devices

This is done in `device_connect_logic.dart:103-110`:
```dart
if (times % 2 == 0) {
  return await queryDeviceOld("15463733-OEM");      // Old device format
} else {
  return await queryDeviceNew("15463733-OEM_binding"); // New device format
}
```

**Verification needed:** Confirm which key format your camera model uses before implementation.

---

## Implementation Plan

### Prerequisites

- [ ] Camera must be in **QR scan / provisioning mode** (typically after factory reset)
  - Note: This is NOT the same as "AP mode" - camera should be ready to scan QR codes
  - Check camera LED status or manual for "WiFi provisioning mode" indicator
- [ ] Phone must be connected to the **target router WiFi** (to get SSID/BSSID)
- [ ] App needs **location permission** (required to read WiFi SSID on iOS)
- [ ] **Post-QR binding may be required** - after camera registers with cloud, you may still need to bind/authenticate with device password (888888 or per-device)

**Source:** `docs/official_documentation/veepai_device_adding_and_usage_process.md`

### Dependencies

```yaml
# pubspec.yaml additions
dependencies:
  qr_flutter: ^4.1.0          # QR code generation
  network_info_plus: ^4.1.0   # Get current WiFi SSID/BSSID
  connectivity_plus: ^5.0.0   # Check WiFi connection (already have)
  http: ^1.1.0                # HTTP requests to cloud API (already have)
```

### Tasks

#### Task 1: Create QR Provisioning Screen (UI)
**Estimate:** 2-3 hours

```dart
// lib/screens/qr_provisioning_screen.dart

class QrProvisioningScreen extends StatefulWidget {
  @override
  _QrProvisioningScreenState createState() => _QrProvisioningScreenState();
}

class _QrProvisioningScreenState extends State<QrProvisioningScreen> {
  String _wifiSsid = '';
  String _wifiBssid = '';
  String _wifiPassword = '';
  String? _qrData;
  bool _isPolling = false;
  int _pollCount = 0;

  // UI: WiFi info display, password input, Generate QR button, QR display
}
```

**Screen Layout:**
```
┌────────────────────────────────────┐
│  QR Code WiFi Setup                │
├────────────────────────────────────┤
│                                    │
│  Current WiFi: MyNetwork           │
│  BSSID: c8:ea:f8:e0:38:f1         │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ WiFi Password: ************  │  │
│  └──────────────────────────────┘  │
│                                    │
│  [ Generate QR Code ]              │
│                                    │
│  ┌──────────────────────────────┐  │
│  │                              │  │
│  │        ▄▄▄▄▄▄▄▄▄▄▄          │  │
│  │        █ QR CODE █           │  │
│  │        ▀▀▀▀▀▀▀▀▀▀▀          │  │
│  │                              │  │
│  └──────────────────────────────┘  │
│                                    │
│  Show this QR code to your camera  │
│  Waiting for camera... (15/60s)    │
│                                    │
└────────────────────────────────────┘
```

#### Task 2: Implement WiFi Info Retrieval
**Estimate:** 1 hour

```dart
Future<void> _getWifiInfo() async {
  // Check if connected to WiFi
  var connectivity = await Connectivity().checkConnectivity();
  if (connectivity != ConnectivityResult.wifi) {
    _showError('Please connect to your WiFi network first');
    return;
  }

  // Get WiFi details (requires location permission on iOS)
  final info = NetworkInfo();
  final ssid = await info.getWifiName();
  final bssid = await info.getWifiBSSID();

  setState(() {
    _wifiSsid = ssid?.replaceAll('"', '') ?? '';
    _wifiBssid = bssid?.replaceAll(':', '') ?? '';  // Remove colons
  });
}
```

#### Task 3: Generate QR Code Data
**Estimate:** 30 minutes

```dart
String _generateQrData() {
  // Build QR payload - RS and P are required, BS/U/A are optional
  final Map<String, String> payload = {
    'RS': _wifiSsid,            // REQUIRED: SSID
    'P': _wifiPassword,         // REQUIRED: WiFi password
  };

  // Add BSSID if available (recommended but optional)
  if (_wifiBssid.isNotEmpty) {
    payload['BS'] = _wifiBssid;  // BSSID without colons
  } else {
    // Warn user that BSSID is missing - connection may be slower
    _log('Warning: BSSID not available. QR provisioning may be slower.');
  }

  // Add optional user ID for cloud binding
  // Note: This may be vendor-specific - verify with your account
  payload['U'] = '15463733-OEM';

  // Add region if known (optional, may be required for some accounts)
  // payload['A'] = '840';  // Uncomment if region is needed

  return jsonEncode(payload);
}
```

**BSSID Fallback:** If BSSID cannot be retrieved (permission denied or unavailable), generate QR without BS field and warn user that provisioning may take longer.

#### Task 4: Implement Cloud Polling
**Estimate:** 2 hours

```dart
// lib/services/hello_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class HelloApiService {
  // VERIFIED: Correct endpoint from app_web_api.dart lines 411-429
  static const _baseUrl = 'https://api.eye4.cn/hello';

  final String _userId = '15463733-OEM';  // Verify this for your vendor account

  /// Clear any previous binding intent
  Future<void> confirmHello() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': _userId}),
    );
    debugPrint('Hello confirm: ${response.statusCode} ${response.body}');
  }

  /// Query for camera registration (old device format)
  Future<String?> queryHelloOld() async {
    return _queryHello(_userId);
  }

  /// Query for camera registration (new device format)
  Future<String?> queryHelloNew() async {
    return _queryHello('${_userId}_binding');
  }

  /// Internal query method
  Future<String?> _queryHello(String key) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/query'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'key': key}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['value'] != null) {
        // Camera registered! Extract UID
        // Response may be URL-encoded JSON
        String value = data['value'];
        try {
          final decoded = Uri.decodeComponent(value);
          final json = jsonDecode(decoded);
          return json['vuid'];
        } catch (e) {
          // If not JSON, might be direct UID
          return value;
        }
      }
    }
    return null;
  }
}
```

**Note:** The SDK alternates between old and new query formats. Our implementation should try both.

#### Task 5: Polling Loop & Success Handling
**Estimate:** 1 hour

```dart
final HelloApiService _helloApi = HelloApiService();

Future<void> _startPolling() async {
  setState(() {
    _isPolling = true;
    _pollCount = 0;
  });

  // Clear previous binding intent
  await _helloApi.confirmHello();

  // Poll every 2 seconds, up to 30 times (60 seconds)
  Timer.periodic(Duration(seconds: 2), (timer) async {
    if (_pollCount >= 30) {
      timer.cancel();
      setState(() => _isPolling = false);
      _showError('Timeout: Camera not detected. Please try again.');
      return;
    }

    setState(() => _pollCount++);

    // Alternate between old and new device query formats (like SDK does)
    String? cameraUid;
    if (_pollCount % 2 == 0) {
      cameraUid = await _helloApi.queryHelloOld();
    } else {
      cameraUid = await _helloApi.queryHelloNew();
    }

    if (cameraUid != null) {
      timer.cancel();
      setState(() => _isPolling = false);
      _onCameraFound(cameraUid);
    }
  });
}

void _onCameraFound(String uid) {
  _log('Camera found! UID: $uid');

  // IMPORTANT: Post-QR binding may be required
  // Per official docs, you may need to authenticate with device password
  // Show binding dialog or navigate to binding screen

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => DeviceBindingScreen(
        cameraUid: uid,
        defaultPassword: '888888',  // Factory default, may need user input
      ),
    ),
  );
}
```

#### Task 5b: Post-QR Device Binding (NEW)
**Estimate:** 1 hour

After QR provisioning, the camera is on WiFi and registered with cloud, but you may still need to bind/authenticate:

```dart
// lib/screens/device_binding_screen.dart

class DeviceBindingScreen extends StatefulWidget {
  final String cameraUid;
  final String defaultPassword;

  const DeviceBindingScreen({
    required this.cameraUid,
    this.defaultPassword = '888888',
  });

  @override
  _DeviceBindingScreenState createState() => _DeviceBindingScreenState();
}

class _DeviceBindingScreenState extends State<DeviceBindingScreen> {
  final _passwordController = TextEditingController();

  Future<void> _bindDevice() async {
    final password = _passwordController.text.isEmpty
        ? widget.defaultPassword
        : _passwordController.text;

    // Fetch P2P credentials for this camera
    final fetcher = P2PCredentialFetcher();
    final credentials = await fetcher.fetchCredentials(widget.cameraUid);

    if (credentials != null) {
      // Cache credentials
      await P2PCredentialCache().saveCredentials(widget.cameraUid, credentials);

      // Navigate to camera view
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => P2PTestScreen()),
      );
    } else {
      _showError('Failed to bind device. Check password and try again.');
    }
  }
}
```

**Source:** `docs/official_documentation/veepai_device_adding_and_usage_process.md`

#### Task 6: Add Navigation from Home Screen
**Estimate:** 30 minutes

Add a new button to the home screen:
```dart
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => QrProvisioningScreen()),
  ),
  child: Text('Setup Camera via QR Code'),
)
```

---

## Acceptance Criteria

- [ ] User can see current WiFi network name and BSSID
- [ ] User can enter WiFi password
- [ ] QR code is generated with correct JSON format
- [ ] QR code displays clearly on screen
- [ ] App polls cloud API after QR is shown
- [ ] App detects when camera registers (within 60 seconds)
- [ ] App navigates to camera view on success
- [ ] Error handling for timeout, network errors
- [ ] Works on iOS (location permission for WiFi info)

---

## Testing Plan

### Manual Testing Steps

1. **Preparation**
   - Factory reset camera (hold reset >10 seconds)
   - Ensure camera is in QR scanning mode (check LED status)
   - Connect phone to target router WiFi

2. **Test QR Generation**
   - Open app → QR Provisioning screen
   - Verify WiFi SSID and BSSID are displayed
   - Enter WiFi password
   - Press "Generate QR Code"
   - Verify QR code appears

3. **Test Camera Scanning**
   - Point camera at QR code on phone screen
   - Camera should beep/flash when QR is read
   - Camera LED should change (connecting to WiFi)

4. **Test Cloud Detection**
   - Watch polling counter increment
   - App should detect camera within 30-60 seconds
   - App should navigate to camera view

### Edge Cases

- [ ] Wrong WiFi password → Camera fails to connect → Timeout
- [ ] Camera not in QR mode → Nothing happens → Timeout
- [ ] Phone loses WiFi during polling → Error handling
- [ ] Cloud API unavailable → Error handling

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Camera doesn't support QR scanning | Low | High | Check camera model/firmware supports this |
| Cloud API format differs | Medium | High | Test with real API, compare with SDK |
| iOS location permission denied | Medium | Medium | Clear explanation to user, graceful fallback |
| QR code too small/blurry | Low | Low | Use high error correction, large size |

---

## References

- **SDK Source**: `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/example/lib/wifi_connect/device_connect_logic.dart`
- **Bluetooth Alternative**: `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/example/lib/bluetooth_connect/bluetooth_connect_logic.dart`
- **Cloud API**: `/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/example/lib/utils/app_web_api.dart`
- **Investigation Doc**: `/docs/MASTER_TROUBLESHOOTING_GUIDE.md` v7.0

---

## Estimated Total Effort

| Task | Estimate |
|------|----------|
| Task 1: QR Screen UI | 2-3 hours |
| Task 2: WiFi Info Retrieval | 1 hour |
| Task 3: QR Data Generation | 30 min |
| Task 4: Cloud Polling Service | 2 hours |
| Task 5: Polling Loop | 1 hour |
| Task 6: Navigation | 30 min |
| Testing & Debugging | 2 hours |
| **Total** | **~9-10 hours** |

---

*Story created: January 19, 2026*
*Author: Claude (AI Assistant)*
*Based on official Veepa SDK analysis*
