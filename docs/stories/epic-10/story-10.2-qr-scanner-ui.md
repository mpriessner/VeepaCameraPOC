# Story 10.2: QR Scanner UI

## Story
As a user, I need a camera viewfinder UI to scan QR codes on my Veepa camera for easy device setup.

## Acceptance Criteria
- [ ] Full-screen camera preview for QR scanning
- [ ] Visual overlay showing scan area
- [ ] Auto-detection when valid QR code found
- [ ] Haptic/audio feedback on successful scan
- [ ] Cancel button to exit scanner
- [ ] Permission handling for camera access

## Technical Details

### UI Components
1. Camera preview (full screen)
2. Scan area overlay (centered square)
3. Instructions text
4. Cancel button
5. Torch/flash toggle (optional)

### Implementation
1. Create `QRScannerScreen` widget
2. Use mobile_scanner for camera preview
3. Add overlay graphics
4. Handle scan result and navigate

### Files to Create/Modify
- `flutter_veepa_module/lib/screens/qr_scanner_screen.dart`
- `flutter_veepa_module/lib/widgets/scan_overlay.dart`
- Update navigation to include scanner

## Definition of Done
- [ ] QR scanner screen implemented
- [ ] Camera permission handling works
- [ ] Overlay displays correctly
- [ ] Successful scan triggers callback
- [ ] Widget tests passing
- [ ] Code committed
