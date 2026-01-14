# Story 3.2: Connection UI and Status

> **Epic**: 3 - Camera Connection
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** user,
**I want** to see the connection status clearly,
**So that** I know when the camera is ready to use.

---

## Acceptance Criteria

- [ ] AC1: Connection screen displays after tapping camera in discovery list
- [ ] AC2: Connection status indicator clearly visible (Disconnected, Connecting, Connected, Error)
- [ ] AC3: Visual feedback during connection attempt (spinner/animation)
- [ ] AC4: Error message displayed on connection failure
- [ ] AC5: Retry button available when connection fails
- [ ] AC6: Automatic navigation to video screen on successful connection
- [ ] AC7: Cancel button available during connection attempt
- [ ] AC8: Device information displayed (name, IP)

---

## Technical Specification

### ConnectionScreen Widget

Create `lib/screens/connection_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';
import 'package:flutter_veepa_module/models/connection_state.dart';
import 'package:flutter_veepa_module/services/veepa_connection_manager.dart';
import 'package:flutter_veepa_module/screens/video_screen.dart';

class ConnectionScreen extends StatefulWidget {
  final DiscoveredDevice device;

  const ConnectionScreen({
    super.key,
    required this.device,
  });

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with SingleTickerProviderStateMixin {
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  late AnimationController _pulseController;
  StreamSubscription<ConnectionState>? _stateSubscription;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for connecting state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Listen to connection state changes
    _stateSubscription = _connectionManager.stateStream.listen(_onStateChanged);

    // Start connection
    _connect();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stateSubscription?.cancel();
    super.dispose();
  }

  void _onStateChanged(ConnectionState state) {
    if (!mounted) return;

    setState(() {});

    // Navigate to video screen on successful connection
    if (state == ConnectionState.connected) {
      _navigateToVideo();
    }
  }

  Future<void> _connect() async {
    await _connectionManager.connect(widget.device);
  }

  void _retry() {
    _connectionManager.retry();
  }

  void _cancel() {
    _connectionManager.disconnect();
    Navigator.pop(context);
  }

  void _navigateToVideo() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(device: widget.device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connecting'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device info
              _buildDeviceInfo(),
              const SizedBox(height: 48),

              // Connection status
              _buildConnectionStatus(),
              const SizedBox(height: 32),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      children: [
        // Device icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.videocam,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Device name
        Text(
          widget.device.name,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Device IP
        if (widget.device.ipAddress != null)
          Text(
            widget.device.fullAddress,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final state = _connectionManager.state;

    return Column(
      children: [
        // Status indicator
        _buildStatusIndicator(state),
        const SizedBox(height: 16),

        // Status text
        Text(
          state.displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _getStatusColor(state),
          ),
        ),

        // Error message
        if (state == ConnectionState.error &&
            _connectionManager.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionManager.errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Reconnect attempt counter
        if (state == ConnectionState.reconnecting) ...[
          const SizedBox(height: 8),
          Text(
            'Attempt ${_connectionManager.reconnectAttempts}/${VeepaConnectionManager.maxReconnectAttempts}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 60 + (_pulseController.value * 20),
              height: 60 + (_pulseController.value * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.2 - (_pulseController.value * 0.1)),
              ),
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          },
        );

      case ConnectionState.connected:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green[100],
          ),
          child: Icon(
            Icons.check_circle,
            size: 40,
            color: Colors.green[700],
          ),
        );

      case ConnectionState.error:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red[100],
          ),
          child: Icon(
            Icons.error,
            size: 40,
            color: Colors.red[700],
          ),
        );

      case ConnectionState.disconnected:
      default:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: Icon(
            Icons.link_off,
            size: 40,
            color: Colors.grey[600],
          ),
        );
    }
  }

  Color _getStatusColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return Colors.blue;
      case ConnectionState.connected:
        return Colors.green;
      case ConnectionState.error:
        return Colors.red;
      case ConnectionState.disconnected:
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons() {
    final state = _connectionManager.state;

    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return OutlinedButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
        );

      case ConnectionState.error:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        );

      case ConnectionState.connected:
        // Brief display before navigation
        return const Text(
          'Opening video stream...',
          style: TextStyle(color: Colors.green),
        );

      case ConnectionState.disconnected:
      default:
        return ElevatedButton.icon(
          onPressed: _connect,
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
        );
    }
  }
}
```

### Update DiscoveryScreen Navigation

Update `lib/screens/discovery_screen.dart`:

```dart
import 'package:flutter_veepa_module/screens/connection_screen.dart';

void _onCameraTapped(DiscoveredDevice device) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ConnectionScreen(device: device),
    ),
  );
}
```

### Placeholder VideoScreen

Create `lib/screens/video_screen.dart` (placeholder for Epic 4):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';

class VideoScreen extends StatelessWidget {
  final DiscoveredDevice device;

  const VideoScreen({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Video Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming in Epic 4',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'Connected to: ${device.name}',
              style: const TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Implementation Tasks

### Task 1: Create ConnectionScreen
Create `lib/screens/connection_screen.dart` with full implementation.

**Verification**: No lint errors

### Task 2: Create VideoScreen Placeholder
Create `lib/screens/video_screen.dart` placeholder.

**Verification**: No lint errors

### Task 3: Update DiscoveryScreen Navigation
Add navigation to ConnectionScreen when camera tapped.

**Verification**: Navigation works

### Task 4: Test UI States
Verify all connection states display correctly.

**Verification**: All states render properly

### Task 5: Test Navigation Flow
Discovery -> Connection -> Video flow works.

**Verification**: Navigation transitions smoothly

---

## Test Cases

### TC3.2.1: Screen Displays Device Info
**Type**: Widget Test
**Priority**: P0

```dart
// test/screens/connection_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/screens/connection_screen.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';

void main() {
  testWidgets('ConnectionScreen shows device info', (tester) async {
    final device = DiscoveredDevice(
      deviceId: 'TEST123',
      name: 'Test Camera',
      ipAddress: '192.168.1.100',
      port: 8080,
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: ConnectionScreen(device: device)),
    );

    // Verify device info displayed
    expect(find.text('Test Camera'), findsOneWidget);
    expect(find.text('192.168.1.100:8080'), findsOneWidget);
  });
}
```

**Given**: ConnectionScreen with device
**When**: Screen renders
**Then**: Device name and IP visible

---

### TC3.2.2: Connecting State Shows Spinner
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('ConnectionScreen shows spinner while connecting', (tester) async {
  final device = DiscoveredDevice(
    deviceId: 'TEST',
    name: 'Test Camera',
    ipAddress: '192.168.1.100',
    discoveryMethod: DiscoveryMethod.lanScan,
    discoveredAt: DateTime.now(),
  );

  await tester.pumpWidget(
    MaterialApp(home: ConnectionScreen(device: device)),
  );

  // Should show progress indicator
  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.text('Connecting...'), findsOneWidget);
});
```

**Given**: ConnectionScreen opened
**When**: Connection in progress
**Then**: Spinner and "Connecting..." visible

---

### TC3.2.3: Error State Shows Message
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('ConnectionScreen shows error state', (tester) async {
  // Setup device that will fail to connect
  final device = DiscoveredDevice(
    deviceId: 'FAIL',
    name: 'Failing Camera',
    ipAddress: null, // Will cause connection failure
    discoveryMethod: DiscoveryMethod.manual,
    discoveredAt: DateTime.now(),
  );

  await tester.pumpWidget(
    MaterialApp(home: ConnectionScreen(device: device)),
  );

  // Wait for connection timeout and retries
  await tester.pumpAndSettle(const Duration(seconds: 35));

  // Should show error state
  expect(find.text('Connection Failed'), findsOneWidget);
  expect(find.byIcon(Icons.error), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
});
```

**Given**: Device that fails to connect
**When**: Connection fails
**Then**: Error message and retry button visible

---

### TC3.2.4: Cancel Button Works
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Cancel button disconnects and goes back', (tester) async {
  final device = DiscoveredDevice(
    deviceId: 'CANCEL_TEST',
    name: 'Test Camera',
    ipAddress: '192.168.1.100',
    discoveryMethod: DiscoveryMethod.lanScan,
    discoveredAt: DateTime.now(),
  );

  bool popped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ConnectionScreen(device: device),
              ),
            ).then((_) => popped = true);
          },
          child: const Text('Open'),
        ),
      ),
    ),
  );

  // Navigate to connection screen
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // Find and tap cancel
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  expect(popped, isTrue);
});
```

**Given**: ConnectionScreen while connecting
**When**: Cancel button tapped
**Then**: Disconnects and navigates back

---

### TC3.2.5: Retry Button Works
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Retry button attempts new connection', (tester) async {
  // This test requires mocking the connection manager
  // For manual testing, verify retry triggers new connection attempt
});
```

**Given**: ConnectionScreen in error state
**When**: Retry button tapped
**Then**: New connection attempt started

---

### TC3.2.6: Reconnect Counter Displays
**Type**: Widget Test
**Priority**: P2

```dart
testWidgets('Shows reconnect attempt counter', (tester) async {
  // Verify "Attempt X/3" text appears during reconnection
});
```

**Given**: Connection lost and reconnecting
**When**: Reconnection in progress
**Then**: Attempt counter visible

---

### TC3.2.7: Manual UI Flow Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Stories 2.1-2.3 and 3.1 completed
- Discovery screen functional

**Steps**:
1. Navigate to discovery screen
2. Find or add a camera
3. Tap on camera item
4. Observe connection screen
5. Watch connection progress
6. If fails, tap Retry
7. If succeeds, verify navigation to video

**Expected Results**:
- [ ] Connection screen opens with device info
- [ ] Spinner shows during connection
- [ ] Status text updates ("Connecting...", "Connected", etc.)
- [ ] Pulse animation visible during connection
- [ ] Error state shows clear message
- [ ] Retry button restarts connection
- [ ] Connected state shows green checkmark
- [ ] Auto-navigates to video screen on success

**Screenshot Required**: Yes - capture connecting, error, and connected states

---

### TC3.2.8: Navigation Flow Test
**Type**: Manual
**Priority**: P0

**Steps**:
1. From Home, tap "Find Cameras"
2. From Discovery, tap camera
3. Wait for connection
4. Verify video screen opens
5. Go back
6. Verify return to discovery

**Expected Results**:
- [ ] Full navigation flow works
- [ ] Back button behavior correct
- [ ] No crashes during navigation
- [ ] State preserved correctly

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] All connection states display correctly
- [ ] Navigation to video screen works
- [ ] Error handling provides clear feedback
- [ ] Code committed with message: "feat(epic-3): Connection UI and status - Story 3.2"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 3.1 (Connection Manager)
- **Blocks**: Story 4.2 (Video Display UI)

---

## UI/UX Notes

### Visual Design
- Pulse animation provides feedback during connection
- Color coding: Blue=connecting, Green=success, Red=error
- Clear visual hierarchy with device info at top

### Accessibility
- Status colors paired with icons for color-blind users
- All interactive elements have sufficient touch targets
- Screen reader labels on status indicators

---

## References

- [Flutter AnimationController](https://api.flutter.dev/flutter/animation/AnimationController-class.html)
- [Material Design Progress Indicators](https://m3.material.io/components/progress-indicators)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC3.2.1 | | | |
| TC3.2.2 | | | |
| TC3.2.3 | | | |
| TC3.2.4 | | | |
| TC3.2.5 | | | |
| TC3.2.6 | | | |
| TC3.2.7 | | | |
| TC3.2.8 | | | |

---
