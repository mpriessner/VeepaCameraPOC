# Story 9.1: End-to-End Connection Test

> **Epic**: 9 - Integration Testing (Phase 2)
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium
> **Phase**: 2 - Flutter Add-to-App Integration

---

## User Story

**As a** developer,
**I want** to verify the full integration works end-to-end,
**So that** I can confirm the POC is successful.

---

## Acceptance Criteria

- [ ] AC1: SwiftUI app launches successfully
- [ ] AC2: Flutter module initializes without crash
- [ ] AC3: Camera connects via Platform Channel
- [ ] AC4: Video displays in Flutter view
- [ ] AC5: PTZ commands work from native controls (if applicable)
- [ ] AC6: Metrics collected: connection time, frame rate, command latency

---

## Technical Specification

### E2E Test Plan

```
Test Flow:
1. Launch SwiftUI app
2. Verify Flutter engine initializes
3. Navigate to camera view
4. Connect to Veepa camera
5. Verify video stream starts
6. Test PTZ controls
7. Disconnect cleanly
8. Return to native view
9. Verify no memory leaks
```

### Metrics Collection

```swift
struct E2EMetrics {
    var engineInitTime: TimeInterval = 0
    var connectionTime: TimeInterval = 0
    var firstFrameTime: TimeInterval = 0
    var averageFPS: Double = 0
    var ptzLatency: TimeInterval = 0

    func report() -> String {
        """
        E2E Test Metrics:
        - Engine Init: \(String(format: "%.2f", engineInitTime))s
        - Connection: \(String(format: "%.2f", connectionTime))s
        - First Frame: \(String(format: "%.2f", firstFrameTime))s
        - Average FPS: \(String(format: "%.1f", averageFPS))
        - PTZ Latency: \(String(format: "%.0f", ptzLatency * 1000))ms
        """
    }
}
```

---

## Test Cases

### TC9.1.1: Full Flow Test
**Type**: Manual/Integration
**Priority**: P0

**Steps**:
1. Fresh install of app
2. Launch app
3. Tap "Open Camera"
4. Wait for Flutter view
5. Select camera from list (or connect via manual IP)
6. Wait for video
7. Move camera with PTZ
8. Dismiss view
9. Repeat 3 times

**Expected Results**:
- [ ] No crashes in any run
- [ ] Connection < 10 seconds
- [ ] Video starts < 5 seconds after connection
- [ ] FPS > 10
- [ ] PTZ latency < 500ms
- [ ] Clean dismiss without leaks

### TC9.1.2: Performance Test
**Type**: Manual
**Priority**: P1

**Steps**:
1. Run app for 30 minutes with video streaming
2. Monitor memory usage
3. Check for frame drops
4. Monitor battery usage

**Expected Results**:
- [ ] Memory stable (no growth)
- [ ] No significant frame drops
- [ ] Battery usage reasonable

---

## Definition of Done

- [ ] E2E flow works completely
- [ ] Metrics meet targets
- [ ] Code committed with message: "feat(epic-9): E2E testing - Story 9.1"
