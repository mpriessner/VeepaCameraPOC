# Epic 15: SDK Integration Completion

> **Goal**: Complete the Veepa SDK integration to show real video from the camera
> **Total Stories**: 8
> **Estimated Effort**: 7-12 hours

---

## Executive Summary

This epic completes the VeepaCameraPOC by replacing simulated/placeholder code with real Veepa SDK integration. After completion, the app will:
- Connect to a physical Veepa camera via P2P
- Display live video stream
- Control PTZ (pan/tilt/zoom)
- Auto-discover cameras on LAN

---

## Phases

### Phase A: Critical Path (Tonight - Ralph Automation)
**Stories 15.1-15.5** - Must be done together, in order

| Story | Title | Effort | Status |
|-------|-------|--------|--------|
| 15.1 | Real P2P Connection | Medium | Ready |
| 15.2 | Connection Auth & Errors | Small | Ready |
| 15.3 | Wire AppPlayerController | Large | Ready |
| 15.4 | Texture Video Widget | Medium | Ready |
| 15.5 | Video Integration Testing | Small | Ready |

**Outcome**: Video from camera displays on screen

---

### Phase C: Additional Features (After Video Validated)
**Stories 15.6-15.7** - Can be done independently

| Story | Title | Effort | Status |
|-------|-------|--------|--------|
| 15.6 | PTZ Controls Integration | Medium | Ready |
| 15.7 | Auto-Discovery Integration | Medium | Ready |

**Outcome**: Full camera control and discovery

---

### Phase D: Final Polish (After All Features)
**Story 15.8** - Comprehensive testing

| Story | Title | Effort | Status |
|-------|-------|--------|--------|
| 15.8 | Full Integration Testing | Medium | Ready |

**Outcome**: Validated, documented POC ready for SciSymbioLens

---

## Dependency Graph

```
Phase A (Critical Path):
  15.1 ──▶ 15.2 ──▶ 15.3 ──▶ 15.4 ──▶ 15.5

Phase C (Independent):
  15.1 ──▶ 15.6 (PTZ - needs connection only)
  (none) ─▶ 15.7 (Discovery - fully independent)

Phase D (Final):
  All ────▶ 15.8 (Testing - after everything)
```

---

## For Ralph Automation

### Tonight's Run: Phase A Only
```
--stories epic-15 --story-range 15.1-15.5
```

### Order of Implementation
1. **15.1**: Real P2P Connection (foundation)
2. **15.2**: Auth & Errors (polish connection)
3. **15.3**: AppPlayerController (biggest piece)
4. **15.4**: Texture Widget (display)
5. **15.5**: Integration Test (verify)

### Key Files to Modify
- `lib/services/veepa_connection_manager.dart`
- `lib/services/veepa_player_service.dart`
- `lib/widgets/texture_video_widget.dart` (create)
- `lib/widgets/password_dialog.dart` (create)
- `lib/screens/video_screen.dart`
- `lib/screens/connection_screen.dart`

### SDK Files to Reference
- `lib/sdk/app_p2p_api.dart` - P2P connection
- `lib/sdk/app_player.dart` - Video player
- `lib/sdk/camera_device/` - PTZ commands

---

## Success Criteria

After Phase A completion:
- [ ] App connects to real camera (not simulated)
- [ ] Video displays on screen (not placeholder)
- [ ] FPS counter shows > 0
- [ ] No crashes or unhandled errors

---

## Notes

- Camera UID for testing: `OKB0379853SNLJ`
- Default password: `admin`
- Native library is arm64-only (physical device required)
- Test on real iPhone, not simulator
