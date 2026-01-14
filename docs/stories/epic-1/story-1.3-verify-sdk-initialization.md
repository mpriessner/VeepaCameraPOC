# Story 1.3: Verify SDK Initialization

> **Epic**: 1 - Project Setup
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Small

---

## User Story

**As a** developer,
**I want** to verify the Veepa SDK initializes correctly,
**So that** I can confirm the SDK is properly integrated before proceeding.

---

## Acceptance Criteria

- [ ] AC1: SDK initialization code added to app startup
- [ ] AC2: Initialization success/failure is logged to console
- [ ] AC3: App displays SDK status on home screen (Initialized/Failed)
- [ ] AC4: Initialization errors are caught and displayed gracefully
- [ ] AC5: App can proceed to discovery screen after successful init
- [ ] AC6: Unit tests verify initialization state machine

---

## Technical Specification

### SDK Initialization Flow

Based on analysis of the Veepa SDK, initialization involves:

1. **Create AppP2PApi instance** - Core P2P communication handler
2. **Initialize native layer** - Loads libVSTC.a functions
3. **Verify connection capability** - Basic health check

### VeepaSDKManager Service

Create `lib/services/veepa_sdk_manager.dart`:

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_veepa_module/sdk/veepa_sdk.dart';

/// Manages Veepa SDK lifecycle
class VeepaSDKManager extends ChangeNotifier {
  static final VeepaSDKManager _instance = VeepaSDKManager._internal();
  factory VeepaSDKManager() => _instance;
  VeepaSDKManager._internal();

  /// SDK initialization state
  SDKInitState _initState = SDKInitState.uninitialized;
  SDKInitState get initState => _initState;

  /// Error message if initialization failed
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// The P2P API instance
  AppP2PApi? _p2pApi;
  AppP2PApi? get p2pApi => _p2pApi;

  /// Whether SDK is ready for use
  bool get isReady => _initState == SDKInitState.initialized;

  /// Initialize the Veepa SDK
  /// Returns true if initialization successful
  Future<bool> initialize() async {
    if (_initState == SDKInitState.initializing) {
      debugPrint('[VeepaSDK] Already initializing, skipping...');
      return false;
    }

    if (_initState == SDKInitState.initialized) {
      debugPrint('[VeepaSDK] Already initialized');
      return true;
    }

    _initState = SDKInitState.initializing;
    _errorMessage = null;
    notifyListeners();

    debugPrint('[VeepaSDK] Starting initialization...');

    try {
      // Step 1: Create P2P API instance
      _p2pApi = AppP2PApi();
      debugPrint('[VeepaSDK] P2P API instance created');

      // Step 2: Perform any required SDK setup
      // Note: The actual initialization may vary based on SDK requirements
      await _performSDKSetup();

      // Step 3: Verify SDK is responsive
      final isHealthy = await _healthCheck();
      if (!isHealthy) {
        throw Exception('SDK health check failed');
      }

      _initState = SDKInitState.initialized;
      debugPrint('[VeepaSDK] Initialization complete!');
      notifyListeners();
      return true;

    } catch (e, stackTrace) {
      _initState = SDKInitState.failed;
      _errorMessage = e.toString();
      debugPrint('[VeepaSDK] Initialization failed: $e');
      debugPrint('[VeepaSDK] Stack trace: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  /// Perform SDK-specific setup
  Future<void> _performSDKSetup() async {
    // Add any SDK-specific initialization here
    // This might include setting up event listeners, configuring defaults, etc.
    await Future.delayed(const Duration(milliseconds: 100)); // Simulated setup time
  }

  /// Basic health check to verify SDK is responsive
  Future<bool> _healthCheck() async {
    try {
      // Verify P2P API is created
      if (_p2pApi == null) {
        return false;
      }

      // Additional health checks can be added here
      // For example, verifying native library is loaded

      return true;
    } catch (e) {
      debugPrint('[VeepaSDK] Health check failed: $e');
      return false;
    }
  }

  /// Reset SDK state (for retry)
  void reset() {
    _initState = SDKInitState.uninitialized;
    _errorMessage = null;
    _p2pApi = null;
    notifyListeners();
  }

  /// Clean up resources
  void dispose() {
    _p2pApi = null;
    super.dispose();
  }
}

/// SDK initialization states
enum SDKInitState {
  uninitialized,
  initializing,
  initialized,
  failed,
}

/// Extension for human-readable state names
extension SDKInitStateExtension on SDKInitState {
  String get displayName {
    switch (this) {
      case SDKInitState.uninitialized:
        return 'Not Started';
      case SDKInitState.initializing:
        return 'Initializing...';
      case SDKInitState.initialized:
        return 'Ready';
      case SDKInitState.failed:
        return 'Failed';
    }
  }

  bool get isLoading => this == SDKInitState.initializing;
  bool get isReady => this == SDKInitState.initialized;
  bool get isFailed => this == SDKInitState.failed;
}
```

### Updated HomeScreen with SDK Status

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/services/veepa_sdk_manager.dart';

void main() {
  runApp(const VeepaCameraPOCApp());
}

class VeepaCameraPOCApp extends StatelessWidget {
  const VeepaCameraPOCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VeepaCameraPOC',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VeepaSDKManager _sdkManager = VeepaSDKManager();

  @override
  void initState() {
    super.initState();
    _sdkManager.addListener(_onSDKStateChanged);
    _initializeSDK();
  }

  @override
  void dispose() {
    _sdkManager.removeListener(_onSDKStateChanged);
    super.dispose();
  }

  void _onSDKStateChanged() {
    setState(() {});
  }

  Future<void> _initializeSDK() async {
    await _sdkManager.initialize();
  }

  void _retryInitialization() {
    _sdkManager.reset();
    _initializeSDK();
  }

  void _proceedToDiscovery() {
    // TODO: Navigate to discovery screen in Story 2.2
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Discovery screen coming in Epic 2!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VeepaCameraPOC'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Camera Icon
              Icon(
                Icons.camera_alt,
                size: 64,
                color: _getStatusColor(),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Veepa Camera POC',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // SDK Status
              _buildStatusIndicator(),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_sdkManager.initState) {
      case SDKInitState.uninitialized:
        return Colors.grey;
      case SDKInitState.initializing:
        return Colors.orange;
      case SDKInitState.initialized:
        return Colors.green;
      case SDKInitState.failed:
        return Colors.red;
    }
  }

  Widget _buildStatusIndicator() {
    final state = _sdkManager.initState;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (state.isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            if (state.isLoading) const SizedBox(width: 8),
            Text(
              'SDK Status: ${state.displayName}',
              style: TextStyle(
                fontSize: 16,
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (state.isFailed && _sdkManager.errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _sdkManager.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons() {
    final state = _sdkManager.initState;

    if (state.isLoading) {
      return const SizedBox.shrink();
    }

    if (state.isFailed) {
      return ElevatedButton.icon(
        onPressed: _retryInitialization,
        icon: const Icon(Icons.refresh),
        label: const Text('Retry'),
      );
    }

    if (state.isReady) {
      return ElevatedButton.icon(
        onPressed: _proceedToDiscovery,
        icon: const Icon(Icons.search),
        label: const Text('Find Cameras'),
      );
    }

    return const SizedBox.shrink();
  }
}
```

---

## Implementation Tasks

### Task 1: Create Services Directory
```bash
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/services
```

**Verification**: Directory exists

### Task 2: Create VeepaSDKManager Service
Create `lib/services/veepa_sdk_manager.dart` with the code from Technical Specification.

**Verification**: File compiles without errors

### Task 3: Update main.dart with SDK Initialization
Update `lib/main.dart` with the new HomeScreen that shows SDK status.

**Verification**: App compiles and runs

### Task 4: Test SDK Initialization on Simulator
```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter run
```

**Verification**: App shows "SDK Status: Ready" after initialization

### Task 5: Create Unit Tests for VeepaSDKManager
Create `test/services/veepa_sdk_manager_test.dart`.

**Verification**: All unit tests pass

### Task 6: Verify Error Handling
Temporarily break SDK initialization to verify error handling works.

**Verification**: App shows error state gracefully

---

## Test Cases

### TC1.3.1: SDK Initialization Success
**Type**: Integration Test
**Priority**: P0

```dart
// test/integration/sdk_init_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/veepa_sdk_manager.dart';

void main() {
  late VeepaSDKManager manager;

  setUp(() {
    manager = VeepaSDKManager();
    manager.reset(); // Ensure clean state
  });

  test('SDK initializes successfully', () async {
    expect(manager.initState, SDKInitState.uninitialized);

    final result = await manager.initialize();

    expect(result, isTrue);
    expect(manager.initState, SDKInitState.initialized);
    expect(manager.isReady, isTrue);
    expect(manager.errorMessage, isNull);
  });
}
```

**Given**: Clean VeepaSDKManager instance
**When**: initialize() is called
**Then**: initState becomes initialized, isReady is true

---

### TC1.3.2: SDK State Machine Transitions
**Type**: Unit Test
**Priority**: P0

```dart
// test/services/veepa_sdk_manager_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/veepa_sdk_manager.dart';

void main() {
  group('SDKInitState', () {
    test('displayName returns correct strings', () {
      expect(SDKInitState.uninitialized.displayName, 'Not Started');
      expect(SDKInitState.initializing.displayName, 'Initializing...');
      expect(SDKInitState.initialized.displayName, 'Ready');
      expect(SDKInitState.failed.displayName, 'Failed');
    });

    test('isLoading is true only for initializing state', () {
      expect(SDKInitState.uninitialized.isLoading, isFalse);
      expect(SDKInitState.initializing.isLoading, isTrue);
      expect(SDKInitState.initialized.isLoading, isFalse);
      expect(SDKInitState.failed.isLoading, isFalse);
    });

    test('isReady is true only for initialized state', () {
      expect(SDKInitState.uninitialized.isReady, isFalse);
      expect(SDKInitState.initializing.isReady, isFalse);
      expect(SDKInitState.initialized.isReady, isTrue);
      expect(SDKInitState.failed.isReady, isFalse);
    });

    test('isFailed is true only for failed state', () {
      expect(SDKInitState.uninitialized.isFailed, isFalse);
      expect(SDKInitState.initializing.isFailed, isFalse);
      expect(SDKInitState.initialized.isFailed, isFalse);
      expect(SDKInitState.failed.isFailed, isTrue);
    });
  });
}
```

**Given**: SDKInitState enum values
**When**: Extension methods are called
**Then**: Correct boolean values returned

---

### TC1.3.3: SDK Manager Notifies Listeners
**Type**: Unit Test
**Priority**: P1

```dart
test('SDK manager notifies listeners on state change', () async {
  final manager = VeepaSDKManager();
  manager.reset();

  int notificationCount = 0;
  manager.addListener(() {
    notificationCount++;
  });

  await manager.initialize();

  // Should notify at least twice: initializing -> initialized
  expect(notificationCount, greaterThanOrEqualTo(2));
});
```

**Given**: VeepaSDKManager with listener attached
**When**: initialize() is called
**Then**: Listener is notified of state changes

---

### TC1.3.4: SDK Reset Works Correctly
**Type**: Unit Test
**Priority**: P1

```dart
test('reset clears SDK state', () async {
  final manager = VeepaSDKManager();
  await manager.initialize();

  expect(manager.initState, SDKInitState.initialized);

  manager.reset();

  expect(manager.initState, SDKInitState.uninitialized);
  expect(manager.errorMessage, isNull);
  expect(manager.p2pApi, isNull);
});
```

**Given**: Initialized VeepaSDKManager
**When**: reset() is called
**Then**: State returns to uninitialized

---

### TC1.3.5: Widget Shows Loading State
**Type**: Widget Test
**Priority**: P1

```dart
// test/widget/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/main.dart';

void main() {
  testWidgets('HomeScreen shows loading indicator during init', (tester) async {
    await tester.pumpWidget(const VeepaCameraPOCApp());

    // Initially should show loading or initializing state
    await tester.pump(const Duration(milliseconds: 50));

    // Look for progress indicator or "Initializing" text
    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
      find.text('Initializing...').evaluate().isNotEmpty,
      isTrue,
    );
  });
}
```

**Given**: App just launched
**When**: SDK is initializing
**Then**: Loading indicator is visible

---

### TC1.3.6: Widget Shows Ready State
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('HomeScreen shows Ready state after successful init', (tester) async {
  await tester.pumpWidget(const VeepaCameraPOCApp());

  // Wait for initialization to complete
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // Should show "Ready" status
  expect(find.textContaining('Ready'), findsOneWidget);

  // Should show "Find Cameras" button
  expect(find.text('Find Cameras'), findsOneWidget);
});
```

**Given**: App launched and SDK initialized
**When**: Initialization completes successfully
**Then**: "Ready" status and "Find Cameras" button visible

---

### TC1.3.7: Manual Initialization Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Stories 1.1 and 1.2 completed
- App builds successfully

**Steps**:
1. Run app on iOS simulator: `flutter run`
2. Observe home screen loading
3. Wait for SDK initialization (< 3 seconds)
4. Verify status indicator shows "Ready"
5. Tap "Find Cameras" button

**Expected Results**:
- [ ] App launches without crash
- [ ] Loading indicator shows briefly
- [ ] Status changes to "Ready" (green)
- [ ] "Find Cameras" button appears
- [ ] Console logs show "[VeepaSDK] Initialization complete!"
- [ ] Tapping button shows snackbar message

**Console Output Expected**:
```
[VeepaSDK] Starting initialization...
[VeepaSDK] P2P API instance created
[VeepaSDK] Initialization complete!
```

---

### TC1.3.8: Error Handling Test
**Type**: Manual
**Priority**: P1

**Steps**:
1. Temporarily modify `_healthCheck()` to return false
2. Run app
3. Observe error state
4. Tap "Retry" button
5. Restore `_healthCheck()` to normal

**Expected Results**:
- [ ] Status shows "Failed" (red)
- [ ] Error message is displayed
- [ ] "Retry" button appears
- [ ] Retry triggers new initialization attempt

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC6) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] SDK initializes successfully on iOS simulator
- [ ] Error states handled gracefully
- [ ] Console logging provides useful debug info
- [ ] Code committed with message: "feat(epic-1): Verify SDK initialization - Story 1.3"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 1.2 (Add Veepa SDK)
- **Blocks**: Epic 2 (Camera Discovery)

---

## References

- [Veepa SDK app_p2p_api.dart](/Users/mpriessner/windsurf_repos/Veepaisdk/flutter-sdk-demo/lib/app_p2p_api.dart)
- [Flutter ChangeNotifier](https://api.flutter.dev/flutter/foundation/ChangeNotifier-class.html)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC1.3.1 | | | |
| TC1.3.2 | | | |
| TC1.3.3 | | | |
| TC1.3.4 | | | |
| TC1.3.5 | | | |
| TC1.3.6 | | | |
| TC1.3.7 | | | |
| TC1.3.8 | | | |

---
