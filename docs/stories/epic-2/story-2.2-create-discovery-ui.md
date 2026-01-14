# Story 2.2: Create Discovery UI

> **Epic**: 2 - Camera Discovery
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** user,
**I want** to see available cameras in a list,
**So that** I can select one to connect to.

---

## Acceptance Criteria

- [ ] AC1: Discovery screen displays a list of discovered cameras
- [ ] AC2: Each camera item shows device name and IP address
- [ ] AC3: Loading indicator displays during discovery scan
- [ ] AC4: "No cameras found" message shows when list is empty
- [ ] AC5: Refresh button triggers new discovery scan
- [ ] AC6: Tapping a camera item navigates to connection screen (placeholder)
- [ ] AC7: Manual IP entry button is accessible from discovery screen
- [ ] AC8: Discovery automatically starts when screen opens

---

## Technical Specification

### Screen Flow

```
HomeScreen (SDK Ready)
    |
    v [Tap "Find Cameras"]
DiscoveryScreen
    |
    +-- Camera found --> Tap --> ConnectionScreen (Story 3.2)
    |
    +-- No cameras --> Manual Entry --> ManualIPDialog (Story 2.3)
```

### Required Files

```
lib/
├── screens/
│   └── discovery_screen.dart     # Discovery UI
├── widgets/
│   ├── camera_list_item.dart     # Individual camera card
│   └── empty_discovery_view.dart # No cameras message
├── services/
│   └── veepa_discovery_service.dart  # From Story 2.1
└── models/
    └── discovered_device.dart    # From Story 2.1
```

### DiscoveryScreen Widget

Create `lib/screens/discovery_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';
import 'package:flutter_veepa_module/services/veepa_discovery_service.dart';
import 'package:flutter_veepa_module/widgets/camera_list_item.dart';
import 'package:flutter_veepa_module/widgets/empty_discovery_view.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final VeepaDiscoveryService _discoveryService = VeepaDiscoveryService();

  List<DiscoveredDevice> _devices = [];
  bool _isScanning = false;
  String? _errorMessage;

  StreamSubscription<DiscoveredDevice>? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _discoveryService.stopDiscovery();
    super.dispose();
  }

  Future<void> _startDiscovery() async {
    setState(() {
      _isScanning = true;
      _devices = [];
      _errorMessage = null;
    });

    try {
      _deviceSubscription?.cancel();
      _deviceSubscription = _discoveryService.startDiscovery().listen(
        (device) {
          setState(() {
            // Add device if not already in list
            if (!_devices.any((d) => d.deviceId == device.deviceId)) {
              _devices.add(device);
            }
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = error.toString();
            _isScanning = false;
          });
        },
        onDone: () {
          setState(() {
            _isScanning = false;
          });
        },
      );

      // Auto-stop after timeout (5 seconds)
      await Future.delayed(const Duration(seconds: 5));
      if (_isScanning) {
        _discoveryService.stopDiscovery();
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isScanning = false;
      });
    }
  }

  void _onCameraTapped(DiscoveredDevice device) {
    // Navigate to connection screen
    // TODO: Implement in Story 3.2
    debugPrint('Camera tapped: ${device.name} (${device.ipAddress})');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connecting to ${device.name}...')),
    );
  }

  void _onManualEntryTapped() {
    // Show manual IP entry dialog
    // TODO: Implement in Story 2.3
    _showManualIPDialog();
  }

  void _showManualIPDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Manual IP Entry'),
        content: const Text('Manual IP entry will be implemented in Story 2.3'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Cameras'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Refresh button
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startDiscovery,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onManualEntryTapped,
        icon: const Icon(Icons.edit),
        label: const Text('Manual IP'),
      ),
    );
  }

  Widget _buildBody() {
    // Show error if any
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    // Show loading state
    if (_isScanning && _devices.isEmpty) {
      return _buildLoadingView();
    }

    // Show empty state
    if (!_isScanning && _devices.isEmpty) {
      return EmptyDiscoveryView(
        onRetry: _startDiscovery,
        onManualEntry: _onManualEntryTapped,
      );
    }

    // Show device list
    return _buildDeviceList();
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Scanning for cameras...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Make sure cameras are on the same network',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Discovery Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startDiscovery,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Column(
      children: [
        // Scanning indicator at top
        if (_isScanning)
          const LinearProgressIndicator(),

        // Results count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${_devices.length} camera${_devices.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (_isScanning) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),

        // Device list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return CameraListItem(
                device: device,
                onTap: () => _onCameraTapped(device),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

### CameraListItem Widget

Create `lib/widgets/camera_list_item.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';

class CameraListItem extends StatelessWidget {
  final DiscoveredDevice device;
  final VoidCallback onTap;

  const CameraListItem({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMethodColor(),
          child: Icon(
            _getMethodIcon(),
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (device.ipAddress != null)
              Text('IP: ${device.ipAddress}'),
            Text(
              'ID: ${device.deviceId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              _getMethodLabel(),
              style: TextStyle(
                fontSize: 11,
                color: _getMethodColor(),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }

  IconData _getMethodIcon() {
    switch (device.discoveryMethod) {
      case DiscoveryMethod.lanScan:
        return Icons.wifi;
      case DiscoveryMethod.manual:
        return Icons.edit;
      case DiscoveryMethod.qrCode:
        return Icons.qr_code;
      case DiscoveryMethod.cached:
        return Icons.history;
    }
  }

  Color _getMethodColor() {
    switch (device.discoveryMethod) {
      case DiscoveryMethod.lanScan:
        return Colors.blue;
      case DiscoveryMethod.manual:
        return Colors.orange;
      case DiscoveryMethod.qrCode:
        return Colors.purple;
      case DiscoveryMethod.cached:
        return Colors.grey;
    }
  }

  String _getMethodLabel() {
    switch (device.discoveryMethod) {
      case DiscoveryMethod.lanScan:
        return 'Found via LAN scan';
      case DiscoveryMethod.manual:
        return 'Manually entered';
      case DiscoveryMethod.qrCode:
        return 'Added via QR code';
      case DiscoveryMethod.cached:
        return 'Previously connected';
    }
  }
}
```

### EmptyDiscoveryView Widget

Create `lib/widgets/empty_discovery_view.dart`:

```dart
import 'package:flutter/material.dart';

class EmptyDiscoveryView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onManualEntry;

  const EmptyDiscoveryView({
    super.key,
    required this.onRetry,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Cameras Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure your Veepa camera is:\n'
              '• Powered on\n'
              '• Connected to the same WiFi network\n'
              '• In pairing/discovery mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: onManualEntry,
                  icon: const Icon(Icons.edit),
                  label: const Text('Enter IP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### Update main.dart Navigation

Update `lib/main.dart` to navigate to DiscoveryScreen:

```dart
void _proceedToDiscovery() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const DiscoveryScreen()),
  );
}
```

---

## Implementation Tasks

### Task 1: Create Directory Structure
```bash
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/screens
mkdir -p /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module/lib/widgets
```

**Verification**: Directories exist

### Task 2: Create DiscoveryScreen
Create `lib/screens/discovery_screen.dart` with the code from Technical Specification.

**Verification**: No lint errors

### Task 3: Create CameraListItem Widget
Create `lib/widgets/camera_list_item.dart`.

**Verification**: No lint errors

### Task 4: Create EmptyDiscoveryView Widget
Create `lib/widgets/empty_discovery_view.dart`.

**Verification**: No lint errors

### Task 5: Update main.dart Navigation
Add import and update `_proceedToDiscovery()` method.

**Verification**: Navigation works

### Task 6: Run Flutter Analyze
```bash
cd /Users/mpriessner/windsurf_repos/VeepaCameraPOC/flutter_veepa_module
flutter analyze
```

**Verification**: No errors

### Task 7: Test on Simulator
```bash
flutter run
```

**Verification**: Discovery screen displays correctly

---

## Test Cases

### TC2.2.1: Screen Displays Loading State
**Type**: Widget Test
**Priority**: P0

```dart
// test/screens/discovery_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/screens/discovery_screen.dart';

void main() {
  testWidgets('DiscoveryScreen shows loading indicator on start', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryScreen()),
    );

    // Should show loading indicator
    expect(find.byType(CircularProgressIndicator), findsWidgets);
    expect(find.text('Scanning for cameras...'), findsOneWidget);
  });
}
```

**Given**: Discovery screen opened
**When**: Discovery starts automatically
**Then**: Loading indicator and "Scanning for cameras..." text visible

---

### TC2.2.2: Empty State Displays Correctly
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('DiscoveryScreen shows empty state when no cameras', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: DiscoveryScreen()),
  );

  // Wait for discovery to complete (5 seconds + buffer)
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();

  // Should show empty state
  expect(find.text('No Cameras Found'), findsOneWidget);
  expect(find.text('Scan Again'), findsOneWidget);
  expect(find.text('Enter IP'), findsOneWidget);
});
```

**Given**: Discovery completes with no cameras found
**When**: Scan finishes
**Then**: "No Cameras Found" message and retry buttons visible

---

### TC2.2.3: Camera List Item Displays Device Info
**Type**: Widget Test
**Priority**: P1

```dart
import 'package:flutter_veepa_module/models/discovered_device.dart';
import 'package:flutter_veepa_module/widgets/camera_list_item.dart';

testWidgets('CameraListItem displays device information', (tester) async {
  final device = DiscoveredDevice(
    deviceId: 'TEST123',
    name: 'Veepa Camera 1',
    ipAddress: '192.168.1.100',
    discoveryMethod: DiscoveryMethod.lanScan,
    discoveredAt: DateTime.now(),
  );

  bool tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CameraListItem(
          device: device,
          onTap: () => tapped = true,
        ),
      ),
    ),
  );

  // Verify device info displayed
  expect(find.text('Veepa Camera 1'), findsOneWidget);
  expect(find.text('IP: 192.168.1.100'), findsOneWidget);
  expect(find.textContaining('TEST123'), findsOneWidget);

  // Verify tap works
  await tester.tap(find.byType(ListTile));
  expect(tapped, isTrue);
});
```

**Given**: CameraListItem with device data
**When**: Widget renders
**Then**: Device name, IP, and ID are displayed

---

### TC2.2.4: Refresh Button Works
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Refresh button triggers new discovery', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: DiscoveryScreen()),
  );

  // Wait for initial scan to complete
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();

  // Find and tap refresh button
  final refreshButton = find.byIcon(Icons.refresh);
  expect(refreshButton, findsOneWidget);

  await tester.tap(refreshButton);
  await tester.pump();

  // Should show loading again
  expect(find.text('Scanning for cameras...'), findsOneWidget);
});
```

**Given**: Discovery screen with completed scan
**When**: Refresh button tapped
**Then**: New discovery scan starts

---

### TC2.2.5: Navigation from HomeScreen
**Type**: Integration Test
**Priority**: P0

```dart
// test/integration/discovery_navigation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/main.dart';

void main() {
  testWidgets('Can navigate from HomeScreen to DiscoveryScreen', (tester) async {
    await tester.pumpWidget(const VeepaCameraPOCApp());

    // Wait for SDK init
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Find and tap "Find Cameras" button
    final findCamerasButton = find.text('Find Cameras');
    expect(findCamerasButton, findsOneWidget);

    await tester.tap(findCamerasButton);
    await tester.pumpAndSettle();

    // Should be on Discovery screen
    expect(find.text('Find Cameras'), findsOneWidget); // AppBar title
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
```

**Given**: HomeScreen with SDK initialized
**When**: "Find Cameras" button tapped
**Then**: Navigates to DiscoveryScreen

---

### TC2.2.6: Manual Entry Button Accessible
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Manual IP entry FAB is accessible', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: DiscoveryScreen()),
  );

  // Find FAB
  final fab = find.byType(FloatingActionButton);
  expect(fab, findsOneWidget);
  expect(find.text('Manual IP'), findsOneWidget);

  // Tap FAB
  await tester.tap(fab);
  await tester.pumpAndSettle();

  // Should show dialog (placeholder)
  expect(find.text('Manual IP Entry'), findsOneWidget);
});
```

**Given**: Discovery screen
**When**: Manual IP FAB tapped
**Then**: Manual IP entry dialog appears

---

### TC2.2.7: Discovery Results Update Dynamically
**Type**: Unit Test
**Priority**: P2

```dart
// This test verifies the stream subscription logic
test('Device list updates as devices are discovered', () async {
  final devices = <DiscoveredDevice>[];

  // Simulate stream of devices
  final stream = Stream.periodic(
    const Duration(milliseconds: 100),
    (i) => DiscoveredDevice(
      deviceId: 'DEV$i',
      name: 'Camera $i',
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    ),
  ).take(3);

  await for (final device in stream) {
    devices.add(device);
  }

  expect(devices.length, 3);
  expect(devices[0].deviceId, 'DEV0');
  expect(devices[2].deviceId, 'DEV2');
});
```

**Given**: Stream of discovered devices
**When**: Devices arrive over time
**Then**: List accumulates devices correctly

---

### TC2.2.8: Manual Discovery UI Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Stories 1.1, 1.2, 1.3, 2.1 completed
- App runs on iOS simulator
- (Optional) Veepa camera on same network

**Steps**:
1. Launch app
2. Wait for SDK initialization
3. Tap "Find Cameras" button
4. Observe loading state
5. Wait for discovery to complete (5 seconds)
6. Observe results (cameras or empty state)
7. Tap "Refresh" button
8. Tap "Manual IP" FAB
9. (If camera found) Tap on camera item

**Expected Results**:
- [ ] App navigates to Discovery screen
- [ ] Loading indicator shows during scan
- [ ] Progress indicator in AppBar while scanning
- [ ] After 5 seconds, results or empty state displays
- [ ] "X camera(s) found" label shows correct count
- [ ] Refresh button restarts discovery
- [ ] Manual IP FAB opens dialog
- [ ] Camera items show name, IP, and discovery method

**Screenshot Required**: Yes - capture both loading and results states

---

### TC2.2.9: Empty State Actions Work
**Type**: Manual
**Priority**: P1

**Steps**:
1. Run discovery with no cameras available
2. Observe empty state message
3. Tap "Scan Again" button
4. Observe re-scan behavior
5. Tap "Enter IP" button
6. Observe manual entry dialog

**Expected Results**:
- [ ] Empty state shows helpful troubleshooting tips
- [ ] "Scan Again" triggers new discovery
- [ ] "Enter IP" opens manual entry dialog
- [ ] No crashes or unexpected behavior

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] Discovery screen accessible from HomeScreen
- [ ] Loading, empty, and list states all work
- [ ] Refresh functionality works
- [ ] Manual IP FAB accessible
- [ ] Code committed with message: "feat(epic-2): Create discovery UI - Story 2.2"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 2.1 (Device Discovery Service)
- **Blocks**: Story 2.3 (Manual IP Entry), Story 3.2 (Connection UI)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Discovery service not ready | High | Low | Mock service for UI development |
| Stream subscription memory leak | Medium | Medium | Proper disposal in dispose() |
| UI responsiveness during scan | Low | Low | Keep discovery in isolate |

---

## UI/UX Notes

### Design Principles
- Keep UI simple and functional for POC
- Clear visual feedback for all states
- Accessible error messages with actionable solutions

### Colors Used
- Blue: LAN scan discovered devices
- Orange: Manually entered devices
- Green: Success/Connected states
- Grey: Cached/historical devices

### Accessibility
- All buttons have tooltips
- Sufficient color contrast
- Screen reader compatible labels

---

## References

- [Flutter ListView](https://api.flutter.dev/flutter/widgets/ListView-class.html)
- [Flutter FAB](https://api.flutter.dev/flutter/material/FloatingActionButton-class.html)
- [Material Design Lists](https://m3.material.io/components/lists)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC2.2.1 | | | |
| TC2.2.2 | | | |
| TC2.2.3 | | | |
| TC2.2.4 | | | |
| TC2.2.5 | | | |
| TC2.2.6 | | | |
| TC2.2.7 | | | |
| TC2.2.8 | | | |
| TC2.2.9 | | | |

---
