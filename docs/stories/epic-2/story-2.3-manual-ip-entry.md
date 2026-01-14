# Story 2.3: Manual IP Entry

> **Epic**: 2 - Camera Discovery
> **Status**: Draft
> **Priority**: P1 - Should Have
> **Estimated Effort**: Small

---

## User Story

**As a** user,
**I want** to manually enter a camera IP address,
**So that** I can connect to a camera if automatic discovery fails.

---

## Acceptance Criteria

- [ ] AC1: "Manual Entry" option accessible from discovery screen
- [ ] AC2: Dialog with IP address text field displays
- [ ] AC3: Basic IP format validation (x.x.x.x where x is 0-255)
- [ ] AC4: Optional port number field (default: 80)
- [ ] AC5: Optional device name field
- [ ] AC6: "Connect" button creates device and navigates to connection screen
- [ ] AC7: Last used IP saved and pre-filled on next entry
- [ ] AC8: Invalid IP shows clear error message

---

## Technical Specification

### ManualIPDialog Widget

Create `lib/widgets/manual_ip_dialog.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';

class ManualIPDialog extends StatefulWidget {
  const ManualIPDialog({super.key});

  /// Show the dialog and return the created device, or null if cancelled
  static Future<DiscoveredDevice?> show(BuildContext context) {
    return showDialog<DiscoveredDevice>(
      context: context,
      builder: (context) => const ManualIPDialog(),
    );
  }

  @override
  State<ManualIPDialog> createState() => _ManualIPDialogState();
}

class _ManualIPDialogState extends State<ManualIPDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  final _nameController = TextEditingController();

  bool _isLoading = true;
  String? _ipError;

  static const String _lastIPKey = 'last_manual_ip';
  static const String _lastPortKey = 'last_manual_port';

  @override
  void initState() {
    super.initState();
    _loadLastUsedValues();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadLastUsedValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastIP = prefs.getString(_lastIPKey);
      final lastPort = prefs.getString(_lastPortKey);

      if (lastIP != null) {
        _ipController.text = lastIP;
      }
      if (lastPort != null) {
        _portController.text = lastPort;
      }
    } catch (e) {
      debugPrint('Failed to load last used values: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveLastUsedValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastIPKey, _ipController.text.trim());
      await prefs.setString(_lastPortKey, _portController.text.trim());
    } catch (e) {
      debugPrint('Failed to save last used values: $e');
    }
  }

  /// Validate IP address format
  String? _validateIP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IP address is required';
    }

    final ip = value.trim();

    // Check basic format
    final parts = ip.split('.');
    if (parts.length != 4) {
      return 'Invalid IP format. Use x.x.x.x';
    }

    // Validate each octet
    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        return 'Each number must be 0-255';
      }
    }

    // Check for reserved addresses
    if (ip == '0.0.0.0' || ip == '255.255.255.255') {
      return 'Invalid IP address';
    }

    return null;
  }

  /// Validate port number
  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Port is optional, defaults to 80
    }

    final port = int.tryParse(value.trim());
    if (port == null || port < 1 || port > 65535) {
      return 'Port must be 1-65535';
    }

    return null;
  }

  void _onConnect() {
    setState(() {
      _ipError = _validateIP(_ipController.text);
    });

    if (!_formKey.currentState!.validate() || _ipError != null) {
      return;
    }

    _saveLastUsedValues();

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 80;
    final name = _nameController.text.trim();

    // Generate device ID from IP
    final deviceId = 'manual_${ip.replaceAll('.', '_')}_$port';

    final device = DiscoveredDevice(
      deviceId: deviceId,
      name: name.isNotEmpty ? name : 'Camera at $ip',
      ipAddress: ip,
      port: port,
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );

    Navigator.pop(context, device);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.edit, size: 24),
          const SizedBox(width: 8),
          const Text('Manual IP Entry'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // IP Address field
                    TextFormField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'IP Address *',
                        hintText: '192.168.1.100',
                        prefixIcon: const Icon(Icons.lan),
                        errorText: _ipError,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      onChanged: (_) {
                        if (_ipError != null) {
                          setState(() {
                            _ipError = null;
                          });
                        }
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),

                    // Port field
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port (optional)',
                        hintText: '80',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: _validatePort,
                    ),
                    const SizedBox(height: 16),

                    // Device name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Camera Name (optional)',
                        hintText: 'Living Room Camera',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Help text
                    Text(
                      'Enter the IP address of your Veepa camera. '
                      'You can find this in your router\'s admin page.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onConnect,
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
        ),
      ],
    );
  }
}
```

### Update DiscoveredDevice Model

Update `lib/models/discovered_device.dart` to include port:

```dart
class DiscoveredDevice {
  final String deviceId;
  final String name;
  final String? ipAddress;
  final int port;  // Add this field
  final DiscoveryMethod discoveryMethod;
  final DateTime discoveredAt;
  final Map<String, dynamic>? metadata;

  const DiscoveredDevice({
    required this.deviceId,
    required this.name,
    this.ipAddress,
    this.port = 80,  // Add default
    required this.discoveryMethod,
    required this.discoveredAt,
    this.metadata,
  });

  /// Full address with port (e.g., "192.168.1.100:80")
  String get fullAddress {
    if (ipAddress == null) return '';
    return port == 80 ? ipAddress! : '$ipAddress:$port';
  }

  // ... rest of existing code
}
```

### IP Validation Utility

Create `lib/utils/ip_validator.dart`:

```dart
/// IP address validation utilities
class IPValidator {
  /// Validates an IPv4 address string
  /// Returns null if valid, error message if invalid
  static String? validate(String? ip) {
    if (ip == null || ip.trim().isEmpty) {
      return 'IP address is required';
    }

    final trimmed = ip.trim();
    final parts = trimmed.split('.');

    if (parts.length != 4) {
      return 'Invalid format. Use x.x.x.x';
    }

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      // Check for empty parts
      if (part.isEmpty) {
        return 'Invalid format';
      }

      // Check for leading zeros (except "0" itself)
      if (part.length > 1 && part.startsWith('0')) {
        return 'No leading zeros allowed';
      }

      final num = int.tryParse(part);
      if (num == null) {
        return 'Only numbers allowed';
      }

      if (num < 0 || num > 255) {
        return 'Each octet must be 0-255';
      }
    }

    // Check for reserved addresses
    if (trimmed == '0.0.0.0') {
      return 'Invalid: 0.0.0.0 not allowed';
    }

    if (trimmed == '255.255.255.255') {
      return 'Invalid: broadcast address';
    }

    // Check for loopback (127.x.x.x)
    if (trimmed.startsWith('127.')) {
      return 'Invalid: loopback address';
    }

    return null;
  }

  /// Check if IP is in private range
  static bool isPrivateIP(String ip) {
    final parts = ip.split('.').map(int.parse).toList();
    if (parts.length != 4) return false;

    // 10.0.0.0 - 10.255.255.255
    if (parts[0] == 10) return true;

    // 172.16.0.0 - 172.31.255.255
    if (parts[0] == 172 && parts[1] >= 16 && parts[1] <= 31) return true;

    // 192.168.0.0 - 192.168.255.255
    if (parts[0] == 192 && parts[1] == 168) return true;

    return false;
  }

  /// Format IP with optional port
  static String formatWithPort(String ip, int port) {
    if (port == 80 || port == 0) {
      return ip;
    }
    return '$ip:$port';
  }
}
```

### Update DiscoveryScreen

Add handler for manual IP result in `lib/screens/discovery_screen.dart`:

```dart
void _onManualEntryTapped() async {
  final device = await ManualIPDialog.show(context);

  if (device != null) {
    // Add to device list
    setState(() {
      _devices.add(device);
    });

    // Optionally auto-connect
    _onCameraTapped(device);
  }
}
```

---

## Implementation Tasks

### Task 1: Create Utils Directory
```bash
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/utils
```

**Verification**: Directory exists

### Task 2: Create IP Validator Utility
Create `lib/utils/ip_validator.dart`.

**Verification**: No lint errors

### Task 3: Update DiscoveredDevice Model
Add `port` field and `fullAddress` getter.

**Verification**: Model compiles

### Task 4: Create ManualIPDialog Widget
Create `lib/widgets/manual_ip_dialog.dart`.

**Verification**: No lint errors

### Task 5: Update DiscoveryScreen
Import and use ManualIPDialog in `_onManualEntryTapped()`.

**Verification**: Dialog opens from FAB

### Task 6: Run Flutter Analyze
```bash
flutter analyze
```

**Verification**: No errors

### Task 7: Test on Simulator
Test manual IP entry flow.

**Verification**: Device created and added to list

---

## Test Cases

### TC2.3.1: IP Validation - Valid IPs
**Type**: Unit Test
**Priority**: P0

```dart
// test/utils/ip_validator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/utils/ip_validator.dart';

void main() {
  group('IPValidator', () {
    test('accepts valid private IPs', () {
      expect(IPValidator.validate('192.168.1.1'), isNull);
      expect(IPValidator.validate('192.168.0.100'), isNull);
      expect(IPValidator.validate('10.0.0.1'), isNull);
      expect(IPValidator.validate('172.16.0.1'), isNull);
    });

    test('accepts valid public IPs', () {
      expect(IPValidator.validate('8.8.8.8'), isNull);
      expect(IPValidator.validate('1.1.1.1'), isNull);
      expect(IPValidator.validate('74.125.224.72'), isNull);
    });

    test('accepts edge case valid IPs', () {
      expect(IPValidator.validate('0.0.0.1'), isNull);
      expect(IPValidator.validate('255.255.255.254'), isNull);
      expect(IPValidator.validate('192.168.1.0'), isNull);
    });
  });
}
```

**Given**: Valid IP address strings
**When**: validate() is called
**Then**: Returns null (no error)

---

### TC2.3.2: IP Validation - Invalid IPs
**Type**: Unit Test
**Priority**: P0

```dart
test('rejects empty input', () {
  expect(IPValidator.validate(''), isNotNull);
  expect(IPValidator.validate('   '), isNotNull);
  expect(IPValidator.validate(null), isNotNull);
});

test('rejects invalid format', () {
  expect(IPValidator.validate('192.168.1'), isNotNull);
  expect(IPValidator.validate('192.168.1.1.1'), isNotNull);
  expect(IPValidator.validate('192.168.1.'), isNotNull);
  expect(IPValidator.validate('.192.168.1.1'), isNotNull);
});

test('rejects out of range octets', () {
  expect(IPValidator.validate('256.1.1.1'), isNotNull);
  expect(IPValidator.validate('192.168.1.256'), isNotNull);
  expect(IPValidator.validate('-1.1.1.1'), isNotNull);
});

test('rejects reserved addresses', () {
  expect(IPValidator.validate('0.0.0.0'), isNotNull);
  expect(IPValidator.validate('255.255.255.255'), isNotNull);
  expect(IPValidator.validate('127.0.0.1'), isNotNull);
});

test('rejects non-numeric input', () {
  expect(IPValidator.validate('abc.def.ghi.jkl'), isNotNull);
  expect(IPValidator.validate('192.168.one.1'), isNotNull);
});
```

**Given**: Invalid IP address strings
**When**: validate() is called
**Then**: Returns error message (not null)

---

### TC2.3.3: Dialog Opens Correctly
**Type**: Widget Test
**Priority**: P0

```dart
// test/widgets/manual_ip_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/widgets/manual_ip_dialog.dart';

void main() {
  testWidgets('ManualIPDialog shows all fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => ManualIPDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Manual IP Entry'), findsOneWidget);
    expect(find.text('IP Address *'), findsOneWidget);
    expect(find.text('Port (optional)'), findsOneWidget);
    expect(find.text('Camera Name (optional)'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });
}
```

**Given**: ManualIPDialog
**When**: Dialog opens
**Then**: All form fields and buttons visible

---

### TC2.3.4: Form Validation Works
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('Dialog validates IP before submission', (tester) async {
  DiscoveredDevice? result;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await ManualIPDialog.show(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  // Open dialog
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // Try to submit with empty IP
  await tester.tap(find.text('Connect'));
  await tester.pumpAndSettle();

  // Should show error
  expect(find.textContaining('required'), findsOneWidget);
  expect(result, isNull); // Dialog not closed

  // Enter invalid IP
  await tester.enterText(find.byType(TextFormField).first, '999.999.999.999');
  await tester.tap(find.text('Connect'));
  await tester.pumpAndSettle();

  // Should show validation error
  expect(find.textContaining('255'), findsOneWidget);
});
```

**Given**: ManualIPDialog with empty or invalid IP
**When**: Connect button tapped
**Then**: Error message shown, dialog stays open

---

### TC2.3.5: Successful Device Creation
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('Dialog returns device on valid submission', (tester) async {
  DiscoveredDevice? result;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await ManualIPDialog.show(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  // Open dialog
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // Enter valid data
  final textFields = find.byType(TextFormField);
  await tester.enterText(textFields.at(0), '192.168.1.100');
  await tester.enterText(textFields.at(1), '8080');
  await tester.enterText(textFields.at(2), 'Test Camera');

  await tester.tap(find.text('Connect'));
  await tester.pumpAndSettle();

  // Verify result
  expect(result, isNotNull);
  expect(result!.ipAddress, '192.168.1.100');
  expect(result!.port, 8080);
  expect(result!.name, 'Test Camera');
  expect(result!.discoveryMethod, DiscoveryMethod.manual);
});
```

**Given**: ManualIPDialog with valid IP
**When**: Connect button tapped
**Then**: Returns DiscoveredDevice with correct data

---

### TC2.3.6: Last IP Persistence
**Type**: Integration Test
**Priority**: P1

```dart
testWidgets('Dialog pre-fills last used IP', (tester) async {
  // Note: This test requires SharedPreferences mock setup
  // For manual testing, verify:
  // 1. Enter IP "192.168.1.50" and submit
  // 2. Close app
  // 3. Reopen dialog
  // 4. IP field should show "192.168.1.50"
});
```

**Given**: Previously entered IP saved
**When**: Dialog opens again
**Then**: Last IP is pre-filled

---

### TC2.3.7: Cancel Button Works
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Cancel button closes dialog without result', (tester) async {
  DiscoveredDevice? result;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              result = await ManualIPDialog.show(context);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  // Open dialog
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // Enter some data
  await tester.enterText(find.byType(TextFormField).first, '192.168.1.100');

  // Cancel
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  // Result should be null
  expect(result, isNull);
  expect(find.text('Manual IP Entry'), findsNothing);
});
```

**Given**: ManualIPDialog with data entered
**When**: Cancel button tapped
**Then**: Dialog closes, returns null

---

### TC2.3.8: Manual Entry Flow Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Story 2.2 completed
- Discovery screen accessible

**Steps**:
1. Navigate to Discovery screen
2. Tap "Manual IP" FAB
3. Verify dialog opens with all fields
4. Leave IP empty, tap Connect
5. Verify error message appears
6. Enter invalid IP (e.g., "999.1.1.1"), tap Connect
7. Verify validation error
8. Enter valid IP (e.g., "192.168.1.100")
9. Enter port (e.g., "8080")
10. Enter name (e.g., "Test Camera")
11. Tap Connect
12. Verify device added to list
13. Verify device shows "Manually entered" label

**Expected Results**:
- [ ] Dialog opens from FAB
- [ ] Empty IP shows error
- [ ] Invalid IP shows specific error
- [ ] Valid submission closes dialog
- [ ] Device appears in camera list
- [ ] Device shows orange icon (manual)
- [ ] Device shows entered name
- [ ] Device shows entered IP:port

**Screenshot Required**: Yes - capture dialog and resulting list item

---

### TC2.3.9: Port Validation Test
**Type**: Manual
**Priority**: P2

**Steps**:
1. Open manual IP dialog
2. Enter valid IP
3. Enter port "0", tap Connect
4. Enter port "65536", tap Connect
5. Enter port "80", tap Connect
6. Leave port empty, tap Connect

**Expected Results**:
- [ ] Port "0" shows error (or is accepted, depending on spec)
- [ ] Port "65536" shows error
- [ ] Port "80" works correctly
- [ ] Empty port defaults to 80

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] IP validation covers edge cases
- [ ] Last IP persistence works
- [ ] Device created with correct method type
- [ ] Code committed with message: "feat(epic-2): Manual IP entry - Story 2.3"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 2.2 (Discovery UI for navigation)
- **Blocks**: Story 3.1 (Connection with manual device)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SharedPreferences not available | Low | Low | Graceful fallback if load fails |
| IP validation too strict | Medium | Low | Test with real camera IPs |
| Keyboard covers input fields | Low | Medium | Use SingleChildScrollView |

---

## References

- [Flutter Form Validation](https://flutter.dev/docs/cookbook/forms/validation)
- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- [IP Address Format](https://en.wikipedia.org/wiki/IP_address)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC2.3.1 | | | |
| TC2.3.2 | | | |
| TC2.3.3 | | | |
| TC2.3.4 | | | |
| TC2.3.5 | | | |
| TC2.3.6 | | | |
| TC2.3.7 | | | |
| TC2.3.8 | | | |
| TC2.3.9 | | | |

---
