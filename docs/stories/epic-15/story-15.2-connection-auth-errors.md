# Story 15.2: Connection Authentication & Error Handling

> **Epic**: 15 - SDK Integration Completion
> **Phase**: A (Tonight - Critical Path)
> **Status**: Ready
> **Priority**: P0 - Must Have
> **Estimated Effort**: Small (30-60 min)
> **Depends On**: Story 15.1

---

## User Story

**As a** user,
**I want** proper authentication handling and clear error messages,
**So that** I understand why connection fails and can fix it.

---

## Background

After implementing real P2P connection (Story 15.1), we need proper handling for:
- Device password input
- Authentication failures
- Network errors
- Timeout handling
- User-friendly error messages

---

## Acceptance Criteria

- [ ] AC1: Password input dialog when connecting to new device
- [ ] AC2: Password stored securely for reconnection
- [ ] AC3: Clear error messages for common failures (wrong password, device offline, timeout)
- [ ] AC4: SDK error codes mapped to user-friendly messages
- [ ] AC5: Retry option with password re-entry for auth failures

---

## Technical Specification

### 1. Add Password Dialog

Create a simple password input dialog:

```dart
// lib/widgets/password_dialog.dart

class PasswordDialog extends StatefulWidget {
  final String deviceName;

  const PasswordDialog({super.key, required this.deviceName});

  static Future<String?> show(BuildContext context, String deviceName) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(deviceName: deviceName),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _controller = TextEditingController(text: 'admin');  // Default
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Connect to ${widget.deviceName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter camera password:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
```

### 2. Update ConnectionScreen to Request Password

```dart
// lib/screens/connection_screen.dart

Future<void> _connect() async {
  // Request password for new connections
  final password = await PasswordDialog.show(context, widget.device.name);

  if (password == null) {
    // User cancelled
    Navigator.pop(context);
    return;
  }

  await _connectionManager.connect(widget.device, password: password);
}
```

### 3. Update VeepaConnectionManager

```dart
// lib/services/veepa_connection_manager.dart

// MODIFY: connect method to accept password
Future<bool> connect(DiscoveredDevice device, {String? password}) async {
  // ... existing checks ...

  _connectedDevice = device;
  _password = password ?? 'admin';  // Store for reconnect
  _reconnectAttempts = 0;
  return _performConnection();
}

// Store password for reconnection
String _password = 'admin';
```

### 4. SDK Error Code Mapping

```dart
// lib/services/connection_error_mapper.dart

class ConnectionErrorMapper {
  static String mapErrorCode(int code) {
    switch (code) {
      case -1:
        return 'Device not found. Check the device ID.';
      case -2:
        return 'Connection timeout. Device may be offline.';
      case -3:
        return 'Authentication failed. Check password.';
      case -4:
        return 'Device is busy. Try again later.';
      case -5:
        return 'Network error. Check your WiFi connection.';
      default:
        if (code < 0) {
          return 'Connection failed (error $code)';
        }
        return 'Unknown error';
    }
  }

  static bool isAuthError(int code) => code == -3;
  static bool isNetworkError(int code) => code == -5 || code == -2;
  static bool isDeviceError(int code) => code == -1 || code == -4;
}
```

### 5. Use Error Mapper in Connection Manager

```dart
// In _connectWithSDK():
final result = await p2pApi.connect(deviceId, _password);

if (result > 0) {
  _clientHandle = result;
  return true;
} else {
  final message = ConnectionErrorMapper.mapErrorCode(result);
  throw Exception(message);
}
```

---

## Files to Create/Modify

1. **CREATE**: `lib/widgets/password_dialog.dart`
2. **CREATE**: `lib/services/connection_error_mapper.dart`
3. **MODIFY**: `lib/screens/connection_screen.dart` - Add password request
4. **MODIFY**: `lib/services/veepa_connection_manager.dart` - Accept password param

---

## Testing Strategy

### Unit Tests
```dart
test('maps auth error code correctly', () {
  expect(ConnectionErrorMapper.mapErrorCode(-3), contains('password'));
  expect(ConnectionErrorMapper.isAuthError(-3), isTrue);
});
```

### Manual Testing
1. Connect with wrong password - should show auth error
2. Connect with correct password - should succeed
3. Reconnect should use stored password

---

## Definition of Done

- [ ] Password dialog shows when connecting
- [ ] Error messages are user-friendly
- [ ] Auth failures prompt for password re-entry
- [ ] Password stored for auto-reconnect
- [ ] Tests pass

---

## Notes

- Default password for most Veepa cameras is 'admin'
- In production, passwords should be stored in iOS Keychain
- For POC, simple in-memory storage is acceptable
