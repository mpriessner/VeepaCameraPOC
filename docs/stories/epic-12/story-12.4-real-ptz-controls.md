# Story 12.4: Real PTZ Controls

## Story
As a developer, I need to integrate real PTZ motor commands for camera movement control.

## Acceptance Criteria
- [ ] Real motor commands integrated
- [ ] Pan left/right working
- [ ] Tilt up/down working
- [ ] Zoom in/out working
- [ ] Stop command working
- [ ] Preset positions (optional)

## Technical Details

### Real Motor Commands
```dart
// PTZ control via CameraDevice
await device.motorCommand?.moveUp();
await device.motorCommand?.moveDown();
await device.motorCommand?.moveLeft();
await device.motorCommand?.moveRight();
await device.motorCommand?.zoomIn();
await device.motorCommand?.zoomOut();
await device.motorCommand?.stop();

// Preset positions
await device.motorCommand?.setPresetPosition(id);
await device.motorCommand?.gotoPresetPosition(id);
```

### Implementation
1. Update VeepaPTZService to use real commands
2. Map UI controls to motor commands
3. Implement continuous movement (hold to move)
4. Add speed control

### Files to Modify
- `flutter_veepa_module/lib/services/veepa_ptz_service.dart`
- `flutter_veepa_module/lib/widgets/ptz_controls.dart`

## Definition of Done
- [ ] Real PTZ commands working
- [ ] All directions functional
- [ ] Zoom working
- [ ] UI responsive
- [ ] Code committed
