# Story 15.4: Create Texture-Based Video Widget

> **Epic**: 15 - SDK Integration Completion
> **Phase**: A (Tonight - Critical Path)
> **Status**: Ready
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium (1-2 hours)
> **Depends On**: Story 15.3 (needs texture ID)

---

## User Story

**As a** user,
**I want** to see actual video from the camera on screen,
**So that** I can view what the camera sees in real-time.

---

## Background

Flutter's `Texture` widget displays native textures by ID. The `AppPlayerController` provides a texture ID after creation. We need to:
1. Create a widget that uses this texture ID
2. Replace the placeholder in VideoScreen
3. Handle texture lifecycle properly

---

## Acceptance Criteria

- [ ] AC1: TextureVideoWidget displays video using texture ID
- [ ] AC2: Shows loading indicator while buffering
- [ ] AC3: Shows error state when video fails
- [ ] AC4: Maintains proper aspect ratio (16:9 default)
- [ ] AC5: VideoScreen uses real texture instead of placeholder
- [ ] AC6: Handles texture ID changes (reconnection)

---

## Technical Specification

### 1. Create TextureVideoWidget

```dart
// lib/widgets/texture_video_widget.dart

import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/player_state.dart';

/// Widget that displays video from a native texture
class TextureVideoWidget extends StatelessWidget {
  /// The texture ID from AppPlayerController (-1 if not ready)
  final int textureId;

  /// Current player state
  final PlayerState playerState;

  /// Aspect ratio (default 16:9)
  final double aspectRatio;

  /// Error message if in error state
  final String? errorMessage;

  /// Callback when user taps retry
  final VoidCallback? onRetry;

  const TextureVideoWidget({
    super.key,
    required this.textureId,
    required this.playerState,
    this.aspectRatio = 16 / 9,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        color: Colors.black,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (playerState) {
      case PlayerState.stopped:
        return _buildStoppedState();

      case PlayerState.buffering:
        return _buildBufferingState();

      case PlayerState.playing:
      case PlayerState.paused:
        return _buildVideoTexture();

      case PlayerState.error:
        return _buildErrorState();
    }
  }

  Widget _buildStoppedState() {
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
  }

  Widget _buildBufferingState() {
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
  }

  Widget _buildVideoTexture() {
    // Check if texture is ready
    if (textureId < 0) {
      return _buildBufferingState();
    }

    // Display the native texture
    return Stack(
      children: [
        // The actual video texture
        Positioned.fill(
          child: Texture(textureId: textureId),
        ),

        // Pause overlay
        if (playerState == PlayerState.paused)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Icon(
                Icons.pause_circle_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            errorMessage ?? 'Video error',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
```

### 2. Update VideoScreen to Use TextureVideoWidget

```dart
// lib/screens/video_screen.dart

// REPLACE _buildVideoContent method:

Widget _buildVideoContent(PlayerState state) {
  // Use the new TextureVideoWidget instead of placeholder
  return TextureVideoWidget(
    textureId: _playerService.textureId,
    playerState: state,
    errorMessage: _playerService.errorMessage,
    onRetry: _startVideo,
  );
}

// REMOVE the old switch statement with placeholder "Video Playing" text
```

### 3. Handle Texture Lifecycle

The texture ID may change on:
- Reconnection (new player created)
- Screen rotation
- App backgrounding

```dart
// In VideoScreen, listen to textureId changes:
@override
void initState() {
  super.initState();
  _playerService.addListener(_onPlayerStateChanged);
  // ... existing code ...
}

void _onPlayerStateChanged() {
  if (mounted) {
    setState(() {});  // Rebuild when textureId or state changes
  }
}
```

### 4. Handle Edge Cases

```dart
// In TextureVideoWidget._buildVideoTexture():

Widget _buildVideoTexture() {
  // Guard against invalid texture
  if (textureId < 0) {
    debugPrint('[TextureVideo] Invalid texture ID: $textureId');
    return _buildBufferingState();
  }

  try {
    return Texture(textureId: textureId);
  } catch (e) {
    debugPrint('[TextureVideo] Texture error: $e');
    return _buildErrorState();
  }
}
```

---

## Files to Create/Modify

1. **CREATE**: `lib/widgets/texture_video_widget.dart`
2. **MODIFY**: `lib/screens/video_screen.dart` - Use new widget
3. **CREATE**: `test/widgets/texture_video_widget_test.dart`

---

## Testing Strategy

### Widget Tests
```dart
testWidgets('shows texture when playing', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TextureVideoWidget(
        textureId: 123,
        playerState: PlayerState.playing,
      ),
    ),
  );

  expect(find.byType(Texture), findsOneWidget);
});

testWidgets('shows loading when buffering', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TextureVideoWidget(
        textureId: -1,
        playerState: PlayerState.buffering,
      ),
    ),
  );

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
});
```

### Manual Testing
1. Connect to camera
2. Verify video displays (not placeholder)
3. Test pause/resume (overlay appears)
4. Test error recovery

---

## Definition of Done

- [ ] TextureVideoWidget created and tested
- [ ] VideoScreen uses real texture display
- [ ] Placeholder "Video Playing" text removed
- [ ] States handled (stopped, buffering, playing, paused, error)
- [ ] Tests pass
- [ ] Video visible on physical device

---

## Notes

- Flutter's `Texture` widget requires valid texture ID (> 0)
- Texture rendering happens on GPU - should be performant
- Test on real device only (simulator won't work with Veepa SDK)
