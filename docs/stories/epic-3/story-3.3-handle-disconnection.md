# Story 3.3: Handle Disconnection

> **Epic**: 3 - Camera Connection
> **Status**: Draft
> **Priority**: P1 - Should Have
> **Estimated Effort**: Medium

---

## User Story

**As a** user,
**I want** the app to handle disconnections gracefully,
**So that** I don't lose control and can easily reconnect to my camera.

---

## Acceptance Criteria

- [ ] AC1: Disconnection detected within 2 seconds of connection loss
- [ ] AC2: User notified immediately when disconnection occurs
- [ ] AC3: Automatic reconnection attempted (up to 3 retries)
- [ ] AC4: Reconnection progress shown to user
- [ ] AC5: Option to return to camera list if reconnection fails
- [ ] AC6: No app crashes on unexpected disconnect
- [ ] AC7: Clean disconnect when user navigates away
- [ ] AC8: Network change detection triggers reconnection attempt

---

## Technical Specification

### Disconnection Detection

The connection manager monitors the P2P connection and detects:
1. **Heartbeat timeout** - No response from camera for 2+ seconds
2. **Socket close** - TCP connection terminated
3. **Network change** - WiFi switch or disconnect
4. **SDK error** - P2P layer reports disconnection

### DisconnectionHandler Service

Create `lib/services/disconnection_handler.dart`:

```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_veepa_module/services/veepa_connection_manager.dart';

/// Handles disconnection detection and user notification
class DisconnectionHandler {
  static final DisconnectionHandler _instance = DisconnectionHandler._internal();
  factory DisconnectionHandler() => _instance;
  DisconnectionHandler._internal();

  /// Connection manager reference
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Heartbeat monitoring
  Timer? _heartbeatTimer;
  static const Duration heartbeatInterval = Duration(seconds: 2);
  DateTime? _lastHeartbeat;

  /// Disconnection callback
  VoidCallback? onDisconnected;
  VoidCallback? onReconnecting;
  VoidCallback? onReconnected;
  void Function(String message)? onReconnectionFailed;

  /// Start monitoring
  void startMonitoring() {
    debugPrint('[DisconnectionHandler] Starting monitoring');

    // Monitor network connectivity
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Start heartbeat monitoring
    _startHeartbeatMonitoring();
  }

  /// Stop monitoring
  void stopMonitoring() {
    debugPrint('[DisconnectionHandler] Stopping monitoring');
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Handle connectivity change
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final hasConnection = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    if (!hasConnection && _connectionManager.state.isConnected) {
      debugPrint('[DisconnectionHandler] Network lost while connected');
      _handleDisconnection('Network connection lost');
    } else if (hasConnection && _connectionManager.state == ConnectionState.error) {
      debugPrint('[DisconnectionHandler] Network restored, attempting reconnect');
      _attemptReconnection();
    }
  }

  /// Start heartbeat monitoring
  void _startHeartbeatMonitoring() {
    _heartbeatTimer?.cancel();
    _lastHeartbeat = DateTime.now();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _checkHeartbeat();
    });
  }

  /// Record heartbeat received
  void recordHeartbeat() {
    _lastHeartbeat = DateTime.now();
  }

  /// Check heartbeat status
  void _checkHeartbeat() {
    if (!_connectionManager.state.isConnected) return;

    final now = DateTime.now();
    if (_lastHeartbeat != null) {
      final elapsed = now.difference(_lastHeartbeat!);
      if (elapsed > heartbeatInterval * 2) {
        debugPrint('[DisconnectionHandler] Heartbeat timeout: ${elapsed.inMilliseconds}ms');
        _handleDisconnection('Connection timeout - no response from camera');
      }
    }
  }

  /// Handle disconnection event
  void _handleDisconnection(String reason) {
    debugPrint('[DisconnectionHandler] Disconnection detected: $reason');

    // Notify listeners
    onDisconnected?.call();

    // Trigger reconnection
    _attemptReconnection();
  }

  /// Attempt automatic reconnection
  void _attemptReconnection() {
    debugPrint('[DisconnectionHandler] Attempting reconnection');
    onReconnecting?.call();

    // Use connection manager's built-in reconnection
    _connectionManager.onConnectionLost();

    // Listen for result
    final subscription = _connectionManager.stateStream.listen((state) {
      if (state == ConnectionState.connected) {
        debugPrint('[DisconnectionHandler] Reconnection successful');
        onReconnected?.call();
      } else if (state == ConnectionState.error) {
        debugPrint('[DisconnectionHandler] Reconnection failed');
        onReconnectionFailed?.call(_connectionManager.errorMessage ?? 'Unknown error');
      }
    });

    // Cancel subscription after timeout
    Future.delayed(const Duration(seconds: 30), () {
      subscription.cancel();
    });
  }

  /// Force disconnect and cleanup
  void forceDisconnect() {
    stopMonitoring();
    _connectionManager.disconnect();
  }
}
```

### Disconnection Overlay Widget

Create `lib/widgets/disconnection_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/services/veepa_connection_manager.dart';

/// Overlay shown when connection is lost
class DisconnectionOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onGoBack;
  final String? errorMessage;
  final int reconnectAttempt;
  final int maxAttempts;
  final bool isReconnecting;

  const DisconnectionOverlay({
    super.key,
    required this.onRetry,
    required this.onGoBack,
    this.errorMessage,
    this.reconnectAttempt = 0,
    this.maxAttempts = 3,
    this.isReconnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Icon(
                isReconnecting ? Icons.sync : Icons.signal_wifi_off,
                size: 64,
                color: isReconnecting ? Colors.orange : Colors.red,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isReconnecting ? 'Reconnecting...' : 'Connection Lost',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              Text(
                isReconnecting
                    ? 'Attempt $reconnectAttempt of $maxAttempts'
                    : errorMessage ?? 'The connection to the camera was lost.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Progress indicator (if reconnecting)
              if (isReconnecting) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 24),
              ],

              // Buttons
              if (!isReconnecting)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onGoBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Camera List'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Integration in VideoScreen

Update video screen to use disconnection handling:

```dart
class _VideoScreenState extends State<VideoScreen> {
  final DisconnectionHandler _disconnectionHandler = DisconnectionHandler();
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  bool _showDisconnectionOverlay = false;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();

    // Setup disconnection handlers
    _disconnectionHandler.onDisconnected = _onDisconnected;
    _disconnectionHandler.onReconnecting = _onReconnecting;
    _disconnectionHandler.onReconnected = _onReconnected;
    _disconnectionHandler.onReconnectionFailed = _onReconnectionFailed;

    // Start monitoring
    _disconnectionHandler.startMonitoring();
  }

  @override
  void dispose() {
    _disconnectionHandler.stopMonitoring();
    super.dispose();
  }

  void _onDisconnected() {
    setState(() {
      _showDisconnectionOverlay = true;
      _isReconnecting = true;
    });
  }

  void _onReconnecting() {
    setState(() {
      _isReconnecting = true;
    });
  }

  void _onReconnected() {
    setState(() {
      _showDisconnectionOverlay = false;
      _isReconnecting = false;
    });
  }

  void _onReconnectionFailed(String message) {
    setState(() {
      _isReconnecting = false;
    });
  }

  void _retryConnection() {
    _connectionManager.retry();
    setState(() {
      _isReconnecting = true;
    });
  }

  void _goBackToCameraList() {
    _disconnectionHandler.forceDisconnect();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main video content
          _buildVideoContent(),

          // Disconnection overlay
          if (_showDisconnectionOverlay)
            DisconnectionOverlay(
              onRetry: _retryConnection,
              onGoBack: _goBackToCameraList,
              errorMessage: _connectionManager.errorMessage,
              reconnectAttempt: _connectionManager.reconnectAttempts,
              maxAttempts: VeepaConnectionManager.maxReconnectAttempts,
              isReconnecting: _isReconnecting,
            ),
        ],
      ),
    );
  }
}
```

---

## Implementation Tasks

### Task 1: Add connectivity_plus Dependency
Update `pubspec.yaml`:

```yaml
dependencies:
  connectivity_plus: ^5.0.0
```

**Verification**: `flutter pub get` succeeds

### Task 2: Create DisconnectionHandler Service
Create `lib/services/disconnection_handler.dart`.

**Verification**: No lint errors

### Task 3: Create DisconnectionOverlay Widget
Create `lib/widgets/disconnection_overlay.dart`.

**Verification**: No lint errors

### Task 4: Integrate in VideoScreen
Update VideoScreen with disconnection handling.

**Verification**: Overlay appears on disconnect

### Task 5: Test Disconnection Scenarios
Test various disconnection scenarios.

**Verification**: All scenarios handled

---

## Test Cases

### TC3.3.1: Network Loss Detection
**Type**: Integration Test
**Priority**: P0

```dart
test('detects network connectivity loss', () async {
  // This test requires platform channel mocking for connectivity_plus
  // Verify: When WiFi disconnects, handler triggers onDisconnected
});
```

**Given**: Connected to camera
**When**: Network connectivity lost
**Then**: Disconnection detected and handler called

---

### TC3.3.2: Heartbeat Timeout Detection
**Type**: Unit Test
**Priority**: P0

```dart
test('detects heartbeat timeout', () async {
  final handler = DisconnectionHandler();
  bool disconnectedCalled = false;
  handler.onDisconnected = () => disconnectedCalled = true;

  handler.startMonitoring();

  // Simulate no heartbeat for 5 seconds
  await Future.delayed(const Duration(seconds: 5));

  expect(disconnectedCalled, isTrue);

  handler.stopMonitoring();
});
```

**Given**: Heartbeat monitoring active
**When**: No heartbeat for 4+ seconds
**Then**: Disconnection detected

---

### TC3.3.3: Automatic Reconnection Triggered
**Type**: Unit Test
**Priority**: P0

```dart
test('triggers automatic reconnection on disconnect', () async {
  final handler = DisconnectionHandler();
  bool reconnectingCalled = false;
  handler.onReconnecting = () => reconnectingCalled = true;

  // Trigger disconnection
  handler._handleDisconnection('Test disconnect');

  expect(reconnectingCalled, isTrue);
});
```

**Given**: Connection lost
**When**: Disconnection handler triggers
**Then**: Automatic reconnection attempt started

---

### TC3.3.4: Overlay Displays Correctly
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('DisconnectionOverlay shows correct state', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DisconnectionOverlay(
          onRetry: () {},
          onGoBack: () {},
          errorMessage: 'Test error',
          isReconnecting: false,
        ),
      ),
    ),
  );

  expect(find.text('Connection Lost'), findsOneWidget);
  expect(find.text('Test error'), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
  expect(find.text('Camera List'), findsOneWidget);
});
```

**Given**: Disconnection overlay shown
**When**: Not reconnecting
**Then**: Shows error message and action buttons

---

### TC3.3.5: Reconnecting State Display
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Overlay shows reconnecting state', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DisconnectionOverlay(
          onRetry: () {},
          onGoBack: () {},
          reconnectAttempt: 2,
          maxAttempts: 3,
          isReconnecting: true,
        ),
      ),
    ),
  );

  expect(find.text('Reconnecting...'), findsOneWidget);
  expect(find.text('Attempt 2 of 3'), findsOneWidget);
  expect(find.byType(LinearProgressIndicator), findsOneWidget);
});
```

**Given**: Reconnection in progress
**When**: Overlay shown
**Then**: Shows progress and attempt count

---

### TC3.3.6: Retry Button Triggers Reconnection
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Retry button triggers reconnection', (tester) async {
  bool retryCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DisconnectionOverlay(
          onRetry: () => retryCalled = true,
          onGoBack: () {},
        ),
      ),
    ),
  );

  await tester.tap(find.text('Retry'));
  expect(retryCalled, isTrue);
});
```

**Given**: Disconnection overlay shown
**When**: Retry button tapped
**Then**: Retry callback invoked

---

### TC3.3.7: Go Back Returns to Camera List
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Go back button returns to camera list', (tester) async {
  bool goBackCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DisconnectionOverlay(
          onRetry: () {},
          onGoBack: () => goBackCalled = true,
        ),
      ),
    ),
  );

  await tester.tap(find.text('Camera List'));
  expect(goBackCalled, isTrue);
});
```

**Given**: Disconnection overlay shown
**When**: "Camera List" button tapped
**Then**: Navigation callback invoked

---

### TC3.3.8: Manual Disconnection Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Connected to camera
- Viewing video stream

**Steps**:
1. Connect to camera and view video
2. Disable WiFi on device
3. Observe disconnection overlay
4. Note reconnection attempts
5. Re-enable WiFi
6. Observe automatic reconnection (if within timeout)
7. If failed, tap Retry
8. Tap "Camera List" to go back

**Expected Results**:
- [ ] Overlay appears within 2-4 seconds of WiFi off
- [ ] Shows "Reconnecting..." with progress
- [ ] Shows attempt counter
- [ ] If WiFi re-enabled quickly, auto-reconnects
- [ ] Retry button restarts connection attempt
- [ ] "Camera List" returns to discovery screen
- [ ] No crash at any point

---

### TC3.3.9: Clean Disconnect on Navigation
**Type**: Manual
**Priority**: P1

**Steps**:
1. Connect to camera
2. View video screen
3. Use back button to navigate away
4. Verify no lingering connections
5. Return to video screen
6. Verify can reconnect successfully

**Expected Results**:
- [ ] Back navigation disconnects cleanly
- [ ] No error messages on disconnect
- [ ] Can reconnect after disconnecting
- [ ] No resource leaks

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] Disconnection detected quickly (<2 seconds)
- [ ] Reconnection works automatically
- [ ] User can manually retry or go back
- [ ] No crashes on disconnection
- [ ] Code committed with message: "feat(epic-3): Handle disconnection - Story 3.3"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 3.1 (Connection Manager), Story 3.2 (Connection UI)
- **Blocks**: None (Nice to have for robustness)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| False positive disconnections | Medium | Medium | Tune heartbeat timeout carefully |
| Connectivity plugin issues | Low | Low | Fallback to heartbeat-only detection |
| Reconnection loops | Medium | Low | Max attempts limit enforced |

---

## References

- [connectivity_plus](https://pub.dev/packages/connectivity_plus)
- [Flutter Overlay](https://api.flutter.dev/flutter/widgets/Overlay-class.html)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC3.3.1 | | | |
| TC3.3.2 | | | |
| TC3.3.3 | | | |
| TC3.3.4 | | | |
| TC3.3.5 | | | |
| TC3.3.6 | | | |
| TC3.3.7 | | | |
| TC3.3.8 | | | |
| TC3.3.9 | | | |

---
