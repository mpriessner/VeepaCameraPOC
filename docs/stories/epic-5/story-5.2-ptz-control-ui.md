# Story 5.2: PTZ Control UI

> **Epic**: 5 - PTZ Controls
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** user,
**I want** on-screen controls for PTZ,
**So that** I can move and zoom the camera easily.

---

## Acceptance Criteria

- [ ] AC1: Directional pad overlay for pan/tilt (up/down/left/right)
- [ ] AC2: Zoom buttons (+ / -) clearly visible
- [ ] AC3: Controls semi-transparent over video
- [ ] AC4: Press-and-hold for continuous movement
- [ ] AC5: Release stops movement immediately
- [ ] AC6: Controls can be hidden/shown
- [ ] AC7: Diagonal movement supported (corner buttons)
- [ ] AC8: Visual feedback when buttons pressed

---

## Technical Specification

### PTZControlsOverlay Widget

Create `lib/widgets/ptz_controls_overlay.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/services/veepa_ptz_service.dart';

class PTZControlsOverlay extends StatefulWidget {
  final bool visible;
  final VoidCallback? onToggleVisibility;

  const PTZControlsOverlay({
    super.key,
    this.visible = true,
    this.onToggleVisibility,
  });

  @override
  State<PTZControlsOverlay> createState() => _PTZControlsOverlayState();
}

class _PTZControlsOverlayState extends State<PTZControlsOverlay> {
  final VeepaPTZService _ptzService = VeepaPTZService();

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // D-Pad (left side)
              _buildDirectionalPad(),

              // Zoom controls (right side)
              _buildZoomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionalPad() {
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(80),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Up
          Positioned(
            top: 8,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_up,
              direction: PTZDirection.tiltUp,
            ),
          ),

          // Down
          Positioned(
            bottom: 8,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_down,
              direction: PTZDirection.tiltDown,
            ),
          ),

          // Left
          Positioned(
            left: 8,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_left,
              direction: PTZDirection.panLeft,
            ),
          ),

          // Right
          Positioned(
            right: 8,
            child: _buildDPadButton(
              icon: Icons.keyboard_arrow_right,
              direction: PTZDirection.panRight,
            ),
          ),

          // Diagonals
          // Up-Left
          Positioned(
            top: 24,
            left: 24,
            child: _buildDPadButton(
              icon: Icons.north_west,
              direction: PTZDirection.panLeftTiltUp,
              size: 32,
            ),
          ),

          // Up-Right
          Positioned(
            top: 24,
            right: 24,
            child: _buildDPadButton(
              icon: Icons.north_east,
              direction: PTZDirection.panRightTiltUp,
              size: 32,
            ),
          ),

          // Down-Left
          Positioned(
            bottom: 24,
            left: 24,
            child: _buildDPadButton(
              icon: Icons.south_west,
              direction: PTZDirection.panLeftTiltDown,
              size: 32,
            ),
          ),

          // Down-Right
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildDPadButton(
              icon: Icons.south_east,
              direction: PTZDirection.panRightTiltDown,
              size: 32,
            ),
          ),

          // Center dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDPadButton({
    required IconData icon,
    required PTZDirection direction,
    double size = 40,
  }) {
    return _PTZButton(
      icon: icon,
      size: size,
      onPressStart: () => _ptzService.startMovement(direction),
      onPressEnd: () => _ptzService.stopMovement(),
    );
  }

  Widget _buildZoomControls() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Zoom In
        _PTZButton(
          icon: Icons.add,
          size: 48,
          onPressStart: () => _ptzService.startZoom(ZoomDirection.zoomIn),
          onPressEnd: () => _ptzService.stopZoom(),
          label: 'ZOOM',
        ),
        const SizedBox(height: 24),
        // Zoom Out
        _PTZButton(
          icon: Icons.remove,
          size: 48,
          onPressStart: () => _ptzService.startZoom(ZoomDirection.zoomOut),
          onPressEnd: () => _ptzService.stopZoom(),
        ),
      ],
    );
  }
}

/// Individual PTZ button with press-and-hold support
class _PTZButton extends StatefulWidget {
  final IconData icon;
  final double size;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final String? label;

  const _PTZButton({
    required this.icon,
    required this.size,
    required this.onPressStart,
    required this.onPressEnd,
    this.label,
  });

  @override
  State<_PTZButton> createState() => _PTZButtonState();
}

class _PTZButtonState extends State<_PTZButton> {
  bool _isPressed = false;

  void _handlePressStart() {
    setState(() => _isPressed = true);
    widget.onPressStart();
  }

  void _handlePressEnd() {
    setState(() => _isPressed = false);
    widget.onPressEnd();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
        ],
        GestureDetector(
          onTapDown: (_) => _handlePressStart(),
          onTapUp: (_) => _handlePressEnd(),
          onTapCancel: _handlePressEnd,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: _isPressed
                  ? Colors.white.withOpacity(0.5)
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isPressed ? Colors.white : Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
```

### Speed Control Slider

Create `lib/widgets/ptz_speed_slider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/services/veepa_ptz_service.dart';

class PTZSpeedSlider extends StatefulWidget {
  const PTZSpeedSlider({super.key});

  @override
  State<PTZSpeedSlider> createState() => _PTZSpeedSliderState();
}

class _PTZSpeedSliderState extends State<PTZSpeedSlider> {
  final VeepaPTZService _ptzService = VeepaPTZService();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.speed, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Slider(
              value: _ptzService.speed.toDouble(),
              min: 0,
              max: 100,
              divisions: 10,
              activeColor: Colors.blue,
              inactiveColor: Colors.white30,
              onChanged: (value) {
                setState(() {
                  _ptzService.speed = value.toInt();
                });
              },
            ),
          ),
          Text(
            '${_ptzService.speed}%',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

### Integration in VideoScreen

Update VideoScreen to include PTZ controls:

```dart
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

          // PTZ Controls (always visible when connected)
          if (_connectionManager.state.isConnected)
            PTZControlsOverlay(visible: _showControls),

          // Speed slider (bottom center)
          if (_showControls && _connectionManager.state.isConnected)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(child: PTZSpeedSlider()),
            ),

          // Other overlays...
        ],
      ),
    ),
  );
}
```

---

## Implementation Tasks

### Task 1: Create PTZControlsOverlay
Create the main PTZ controls widget.

**Verification**: Widget renders correctly

### Task 2: Create _PTZButton Widget
Create the press-and-hold button component.

**Verification**: Press/release events work

### Task 3: Create PTZSpeedSlider
Create speed control slider.

**Verification**: Speed updates service

### Task 4: Integrate in VideoScreen
Add PTZ controls to video screen.

**Verification**: Controls visible over video

### Task 5: Test Touch Interaction
Verify press-and-hold works correctly.

**Verification**: Camera moves while pressed

---

## Test Cases

### TC5.2.1: Controls Render Correctly
**Type**: Widget Test
**Priority**: P0

```dart
// test/widgets/ptz_controls_overlay_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/widgets/ptz_controls_overlay.dart';

void main() {
  testWidgets('PTZControlsOverlay shows all direction buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PTZControlsOverlay(visible: true),
            ],
          ),
        ),
      ),
    );

    // Verify direction buttons exist
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_left), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);

    // Verify zoom buttons
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
  });
}
```

**Given**: PTZControlsOverlay visible
**When**: Widget renders
**Then**: All buttons present

---

### TC5.2.2: Hidden When Not Visible
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Controls hidden when visible=false', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            PTZControlsOverlay(visible: false),
          ],
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
});
```

**Given**: PTZControlsOverlay with visible=false
**When**: Widget renders
**Then**: No buttons visible

---

### TC5.2.3: Press-and-Hold Triggers Commands
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('Button press starts movement, release stops', (tester) async {
  // This requires mocking PTZService
  // Verify: onPressStart called on tap down
  // Verify: onPressEnd called on tap up
});
```

**Given**: PTZ button
**When**: User presses and releases
**Then**: Start/stop commands sent

---

### TC5.2.4: Visual Feedback on Press
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Button shows visual feedback when pressed', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: _PTZButton(
          icon: Icons.arrow_upward,
          size: 48,
          onPressStart: () {},
          onPressEnd: () {},
        ),
      ),
    ),
  );

  // Get initial opacity
  // Tap and hold
  // Verify opacity/color changed
  // Release
  // Verify returned to original
});
```

**Given**: PTZ button
**When**: Pressed
**Then**: Visual appearance changes

---

### TC5.2.5: Speed Slider Works
**Type**: Widget Test
**Priority**: P1

```dart
testWidgets('Speed slider updates service speed', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: PTZSpeedSlider()),
    ),
  );

  // Find slider
  final slider = find.byType(Slider);
  expect(slider, findsOneWidget);

  // Drag slider
  await tester.drag(slider, const Offset(50, 0));
  await tester.pump();

  // Verify speed updated (need service access)
});
```

**Given**: Speed slider
**When**: Slider dragged
**Then**: PTZ service speed updated

---

### TC5.2.6: Manual PTZ Control Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Connected to real Veepa camera
- Video screen displayed
- PTZ supported by camera

**Steps**:
1. Open video screen
2. Observe PTZ controls overlay
3. Press and hold UP button
4. Verify camera tilts up
5. Release button
6. Verify movement stops
7. Repeat for all directions
8. Test zoom in/out
9. Adjust speed slider
10. Verify speed affects movement

**Expected Results**:
- [ ] All direction buttons work
- [ ] Movement starts immediately on press
- [ ] Movement stops immediately on release
- [ ] Zoom buttons work
- [ ] Speed slider affects movement speed
- [ ] Diagonal buttons work
- [ ] No delay or lag

**Screenshot Required**: Yes - capture PTZ controls visible

---

### TC5.2.7: Diagonal Movement
**Type**: Manual
**Priority**: P1

**Steps**:
1. Press diagonal button (e.g., up-left)
2. Observe camera moves diagonally
3. Release
4. Verify stops

**Expected Results**:
- [ ] Camera moves in diagonal direction
- [ ] Movement is smooth
- [ ] Stops correctly

---

### TC5.2.8: Controls Over Video
**Type**: Visual Test
**Priority**: P1

**Steps**:
1. Play video from camera
2. Show PTZ controls
3. Verify controls are visible over video
4. Verify video is still visible behind controls

**Expected Results**:
- [ ] Controls semi-transparent
- [ ] Video visible underneath
- [ ] No visual obstruction of key video areas
- [ ] Controls don't cover center of video

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC8) verified
- [ ] All P0 test cases pass
- [ ] Press-and-hold works correctly
- [ ] All directions functional
- [ ] Zoom controls work
- [ ] Speed slider functional
- [ ] Code committed with message: "feat(epic-5): PTZ control UI - Story 5.2"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 5.1 (PTZ Service), Story 4.2 (Video Screen)
- **Blocks**: None (Final Phase 1 feature)

---

## UI/UX Notes

### Layout
- D-pad on left for right-handed users
- Zoom on right side
- Speed slider at bottom
- Semi-transparent to not block video

### Touch Targets
- Minimum 44x44 for accessibility
- Diagonal buttons smaller but still usable

### Feedback
- Visual feedback on press (opacity change)
- Could add haptic feedback (nice to have)

---

## References

- [Flutter GestureDetector](https://api.flutter.dev/flutter/widgets/GestureDetector-class.html)
- Material Design touch targets guidelines

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC5.2.1 | | | |
| TC5.2.2 | | | |
| TC5.2.3 | | | |
| TC5.2.4 | | | |
| TC5.2.5 | | | |
| TC5.2.6 | | | |
| TC5.2.7 | | | |
| TC5.2.8 | | | |

---
