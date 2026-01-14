# Story 12.3: Real Video Player

## Story
As a developer, I need to integrate the real Veepa video player for live camera streaming.

## Acceptance Criteria
- [ ] AppPlayerController integrated
- [ ] Live video streaming working
- [ ] Video rendered to Flutter texture
- [ ] Frame callbacks accessible
- [ ] Audio support (optional)
- [ ] Player controls (play, pause, stop)

## Technical Details

### Real Player Usage
```dart
// Create video source
var source = LiveVideoSource(device.clientPtr);

// Create player
var player = AppPlayerController(source);

// Start playback
await player.play();

// Listen to frames
player.addListener((data) {
  // data[0] = textureId
  // data[1] = total_duration
  // ...
});
```

### Implementation
1. Update VeepaPlayerService to use real player
2. Create texture-based video widget
3. Handle player lifecycle
4. Implement frame callbacks for metrics

### Files to Modify
- `flutter_veepa_module/lib/services/veepa_player_service.dart`
- `flutter_veepa_module/lib/widgets/veepa_video_widget.dart`
- `flutter_veepa_module/lib/widgets/camera_preview.dart`

## Definition of Done
- [ ] Real video player integrated
- [ ] Live stream displays correctly
- [ ] Player controls work
- [ ] Frame metrics collected
- [ ] Code committed
