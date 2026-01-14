# Story 4.2: Video Display UI

> **Epic**: 4 - Video Streaming
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** user,
**I want** to see live video from my camera,
**So that** I can monitor what the camera sees in real-time.

---

## Acceptance Criteria

- [ ] AC1: Full-screen video display on VideoScreen
- [ ] AC2: Video fills available space with correct aspect ratio
- [ ] AC3: Loading indicator shown while buffering
- [ ] AC4: Frame rate indicator available (debug mode toggle)
- [ ] AC5: Video starts automatically when screen opens
- [ ] AC6: Supports both portrait and landscape orientations
- [ ] AC7: Controls overlay can be shown/hidden
- [ ] AC8: Connection status visible in header

---

## Technical Specification

### VideoScreen Implementation

Update `lib/screens/video_screen.dart`:

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';
import 'package:flutter_veepa_module/models/player_state.dart';
import 'package:flutter_veepa_module/models/connection_state.dart';
import 'package:flutter_veepa_module/services/veepa_player_service.dart';
import 'package:flutter_veepa_module/services/veepa_connection_manager.dart';
import 'package:flutter_veepa_module/services/disconnection_handler.dart';
import 'package:flutter_veepa_module/widgets/disconnection_overlay.dart';
import 'package:flutter_veepa_module/widgets/video_controls_overlay.dart';

class VideoScreen extends StatefulWidget {
  final DiscoveredDevice device;

  const VideoScreen({
    super.key,
    required this.device,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final VeepaPlayerService _playerService = VeepaPlayerService();
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();
  final DisconnectionHandler _disconnectionHandler = DisconnectionHandler();

  bool _showControls = true;
  bool _showDebugInfo = false;
  bool _showDisconnectionOverlay = false;
  bool _isReconnecting = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();

    // Listen to player state
    _playerService.addListener(_onPlayerStateChanged);

    // Setup disconnection handling
    _setupDisconnectionHandler();

    // Start video playback
    _startVideo();

    // Auto-hide controls after delay
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _playerService.removeListener(_onPlayerStateChanged);
    _playerService.stop();
    _disconnectionHandler.stopMonitoring();
    super.dispose();
  }

  void _setupDisconnectionHandler() {
    _disconnectionHandler.onDisconnected = () {
      setState(() {
        _showDisconnectionOverlay = true;
        _isReconnecting = true;
      });
    };

    _disconnectionHandler.onReconnected = () {
      setState(() {
        _showDisconnectionOverlay = false;
        _isReconnecting = false;
      });
      // Restart video after reconnection
      _startVideo();
    };

    _disconnectionHandler.onReconnectionFailed = (message) {
      setState(() {
        _isReconnecting = false;
      });
    };

    _disconnectionHandler.startMonitoring();
  }

  void _onPlayerStateChanged() {
    setState(() {});
  }

  Future<void> _startVideo() async {
    await _playerService.start(widget.device);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _scheduleHideControls();
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
    });
  }

  void _goBack() {
    _playerService.stop();
    _connectionManager.disconnect();
    Navigator.pop(context);
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
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video display
            _buildVideoDisplay(),

            // Controls overlay
            if (_showControls) _buildControlsOverlay(),

            // Debug info
            if (_showDebugInfo) _buildDebugOverlay(),

            // Disconnection overlay
            if (_showDisconnectionOverlay)
              DisconnectionOverlay(
                onRetry: _retryConnection,
                onGoBack: _goBackToCameraList,
                errorMessage: _connectionManager.errorMessage,
                reconnectAttempt: _connectionManager.reconnectAttempts,
                isReconnecting: _isReconnecting,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDisplay() {
    final playerState = _playerService.state;

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9, // Default aspect ratio
        child: Container(
          color: Colors.black,
          child: _buildVideoContent(playerState),
        ),
      ),
    );
  }

  Widget _buildVideoContent(PlayerState state) {
    switch (state) {
      case PlayerState.stopped:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Video stopped', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );

      case PlayerState.buffering:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Loading video...', style: TextStyle(color: Colors.white)),
            ],
          ),
        );

      case PlayerState.playing:
        // TODO: Replace with actual video texture
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Video Playing',
                  style: TextStyle(color: Colors.green, fontSize: 18),
                ),
                Text(
                  '(Actual video texture coming with SDK integration)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        );

      case PlayerState.paused:
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.pause_circle, size: 64, color: Colors.white),
          ),
        );

      case PlayerState.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _playerService.errorMessage ?? 'Video error',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _startVideo,
                child: const Text('Retry'),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(),

              const Spacer(),

              // Bottom controls
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goBack,
          ),

          // Device name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _connectionManager.state.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _connectionManager.state.displayName,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Debug toggle
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: _showDebugInfo ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleDebugInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause button
          IconButton(
            iconSize: 48,
            icon: Icon(
              _playerService.state == PlayerState.playing
                  ? Icons.pause_circle
                  : Icons.play_circle,
              color: Colors.white,
            ),
            onPressed: () {
              if (_playerService.state == PlayerState.playing) {
                _playerService.pause();
              } else if (_playerService.state == PlayerState.paused) {
                _playerService.resume();
              } else {
                _startVideo();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebugOverlay() {
    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Debug Info',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _debugRow('Player', _playerService.state.displayName),
            _debugRow('Connection', _connectionManager.state.displayName),
            _debugRow('FPS', '${_playerService.currentFPS.toStringAsFixed(1)}'),
            _debugRow('Device ID', widget.device.deviceId),
            _debugRow('IP', widget.device.ipAddress ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

---

## Implementation Tasks

### Task 1: Update VideoScreen
Replace placeholder with full implementation.

**Verification**: Screen renders all states

### Task 2: Implement Controls Overlay
Add show/hide animation and controls.

**Verification**: Controls appear/disappear correctly

### Task 3: Add Debug Info Panel
Create debug overlay with FPS and status.

**Verification**: Debug info displays accurately

### Task 4: Test Orientation Support
Verify landscape and portrait work.

**Verification**: Both orientations display correctly

### Task 5: Integration Test
Test with actual camera stream.

**Verification**: Video displays on screen

---

## Test Cases

### TC4.2.1: Video Screen Renders All States
**Type**: Widget Test
**Priority**: P0

```dart
// test/screens/video_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/screens/video_screen.dart';
import 'package:flutter_veepa_module/models/discovered_device.dart';

void main() {
  testWidgets('VideoScreen shows buffering state', (tester) async {
    final device = DiscoveredDevice(
      deviceId: 'TEST',
      name: 'Test Camera',
      ipAddress: '192.168.1.100',
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: VideoScreen(device: device)),
    );

    // Should show loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Loading video...'), findsOneWidget);
  });
}
```

**Given**: VideoScreen opened
**When**: Player is buffering
**Then**: Loading indicator shown

---

### TC4.2.2: Controls Show/Hide
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Controls toggle on tap', (tester) async {
  // Tap screen to toggle controls
  // Verify controls visibility changes
});
```

**Given**: VideoScreen with controls visible
**When**: Screen tapped
**Then**: Controls toggle visibility

---

### TC4.2.3: Debug Panel Toggle
**Type**: Widget Test
**Priority**: P2

```dart
testWidgets('Debug panel shows FPS info', (tester) async {
  // Find and tap debug button
  // Verify debug panel appears with FPS
});
```

**Given**: VideoScreen with controls visible
**When**: Debug button tapped
**Then**: Debug panel with FPS info visible

---

### TC4.2.4: Back Button Works
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Back button returns to previous screen', (tester) async {
  // Tap back button
  // Verify navigation
});
```

**Given**: VideoScreen displayed
**When**: Back button tapped
**Then**: Navigates to previous screen

---

### TC4.2.5: Manual Video Display Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Camera connected
- Connection established

**Steps**:
1. Navigate to video screen
2. Observe buffering indicator
3. Wait for video to load
4. Tap screen to show controls
5. Wait 3 seconds for auto-hide
6. Tap debug button
7. Observe FPS counter
8. Rotate device to landscape
9. Verify video adapts
10. Tap back button

**Expected Results**:
- [ ] Buffering indicator displays
- [ ] Video plays (or placeholder)
- [ ] Controls auto-hide after 3s
- [ ] Debug panel shows FPS
- [ ] Landscape orientation works
- [ ] Back button returns to previous screen
- [ ] No crashes during transitions

**Screenshot Required**: Yes - capture playing state with controls

---

### TC4.2.6: Connection Status Display
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Connection status indicator shows correct state', (tester) async {
  // Verify green dot for connected
  // Verify state text matches connection state
});
```

**Given**: VideoScreen displayed
**When**: Connection state changes
**Then**: Status indicator updates

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] All P1 test cases pass
- [ ] Video displays in correct aspect ratio
- [ ] Controls show/hide smoothly
- [ ] Debug info accessible
- [ ] Both orientations supported
- [ ] Code committed with message: "feat(epic-4): Video display UI - Story 4.2"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 4.1 (Video Player Service)
- **Blocks**: Story 5.2 (PTZ Controls overlay on video)

---

## UI/UX Notes

### Design Decisions
- Black background for video display
- Semi-transparent gradient for controls overlay
- Auto-hide controls after 3 seconds
- Debug info positioned to not block video center

### Accessibility
- Sufficient contrast on overlay controls
- Touch targets sized appropriately (48x48 minimum)

---

## References

- [Flutter AspectRatio](https://api.flutter.dev/flutter/widgets/AspectRatio-class.html)
- [Material Design Video Player](https://m3.material.io/components/video-players)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC4.2.1 | | | |
| TC4.2.2 | | | |
| TC4.2.3 | | | |
| TC4.2.4 | | | |
| TC4.2.5 | | | |
| TC4.2.6 | | | |

---
