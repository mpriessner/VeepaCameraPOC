# Story 15.5: Video Integration & Testing

> **Epic**: 15 - SDK Integration Completion
> **Phase**: A (Tonight - Critical Path)
> **Status**: Ready
> **Priority**: P0 - Must Have
> **Estimated Effort**: Small (30-60 min)
> **Depends On**: Stories 15.1-15.4

---

## User Story

**As a** developer,
**I want** to verify the complete video pipeline works end-to-end,
**So that** I'm confident the integration is correct before hardware testing.

---

## Background

After implementing Stories 15.1-15.4, we need to:
1. Verify the integration compiles and links
2. Fix any runtime issues
3. Add logging for debugging
4. Prepare for hardware testing

---

## Acceptance Criteria

- [ ] AC1: App compiles without errors
- [ ] AC2: No missing imports or dependencies
- [ ] AC3: Debug logging shows connection → player → texture flow
- [ ] AC4: FPS counter shows actual frame rate (not 0)
- [ ] AC5: Error states properly propagate through system
- [ ] AC6: Console output is clean (no unhandled exceptions)

---

## Technical Specification

### 1. Add Comprehensive Debug Logging

```dart
// In VeepaConnectionManager
debugPrint('[Connection] ===== CONNECTION FLOW START =====');
debugPrint('[Connection] Device: ${device.name}');
debugPrint('[Connection] Device ID: ${device.deviceId}');
debugPrint('[Connection] IP: ${device.ipAddress}');
// After connect:
debugPrint('[Connection] ===== CLIENT HANDLE: $_clientHandle =====');

// In VeepaPlayerService
debugPrint('[VeepaPlayer] ===== VIDEO FLOW START =====');
debugPrint('[VeepaPlayer] Client handle from connection: $clientHandle');
debugPrint('[VeepaPlayer] Creating LiveVideoSource...');
// After create:
debugPrint('[VeepaPlayer] ===== TEXTURE ID: $_textureId =====');

// In TextureVideoWidget
debugPrint('[TextureVideo] Rendering texture ID: $textureId');
```

### 2. Verify Frame Rate Counting

Update VeepaPlayerService to count frames from real callbacks:

```dart
// In state callback:
case VideoStatus.PLAY:
  _frameCount++;  // Count each frame
  if (_frameCount % 30 == 0) {
    debugPrint('[VeepaPlayer] Frame count: $_frameCount, FPS: ${currentFPS.toStringAsFixed(1)}');
  }
  break;
```

### 3. Add Connection Flow Diagram to Logs

```dart
// At start of video screen:
debugPrint('''
[Integration] Complete flow:
  1. Connection handle: ${_connectionManager.clientHandle}
  2. Player state: ${_playerService.state}
  3. Texture ID: ${_playerService.textureId}
  4. Current FPS: ${_playerService.currentFPS}
''');
```

### 4. Verify All Imports

Ensure these imports work:
```dart
import 'package:veepa_camera_poc/sdk/app_player.dart';
import 'package:veepa_camera_poc/sdk/app_p2p_api.dart';
```

### 5. Run Flutter Analyze

```bash
cd flutter_veepa_module
flutter analyze
flutter test
```

---

## Testing Checklist

### Compile-Time Checks
- [ ] `flutter analyze` passes
- [ ] `flutter build ios --debug` succeeds
- [ ] No import errors

### Runtime Checks (Xcode Console)
- [ ] See "CONNECTION FLOW START" log
- [ ] See "CLIENT HANDLE: <number>" log
- [ ] See "VIDEO FLOW START" log
- [ ] See "TEXTURE ID: <number>" log
- [ ] See frame count incrementing
- [ ] No red error messages

### Visual Checks
- [ ] Video appears on screen (not placeholder text)
- [ ] FPS counter in debug overlay shows > 0
- [ ] Pause/resume works

---

## Files to Modify

1. `lib/services/veepa_connection_manager.dart` - Add logging
2. `lib/services/veepa_player_service.dart` - Add logging
3. `lib/widgets/texture_video_widget.dart` - Add logging
4. `lib/screens/video_screen.dart` - Add integration logging

---

## Definition of Done

- [ ] `flutter analyze` clean
- [ ] `flutter build ios --debug` succeeds
- [ ] Debug logging shows complete flow
- [ ] Ready for hardware testing

---

## Notes

- This is a verification story, not heavy implementation
- Focus on making debugging easy for hardware testing tomorrow
- Console output should tell the story of what's happening
