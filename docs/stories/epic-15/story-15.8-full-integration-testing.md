# Story 15.8: Full Integration Testing

> **Epic**: 15 - SDK Integration Completion
> **Phase**: D (Final Polish)
> **Status**: Ready
> **Priority**: P1 - Should Have
> **Estimated Effort**: Medium (1-2 hours)
> **Depends On**: Stories 15.1-15.7

---

## User Story

**As a** developer,
**I want** comprehensive end-to-end testing of the POC,
**So that** I can validate all features work together with real hardware.

---

## Background

After implementing all SDK integrations, we need to:
1. Run complete user flow tests
2. Validate quality gates are met
3. Document any known issues
4. Prepare for SciSymbioLens integration

---

## Acceptance Criteria

- [ ] AC1: Complete flow works: Launch → Discover → Connect → Video → PTZ
- [ ] AC2: Quality gates pass (see table below)
- [ ] AC3: Error recovery works (disconnect/reconnect)
- [ ] AC4: Performance is acceptable
- [ ] AC5: Known issues documented

---

## Quality Gates

| Metric | Target | Pass/Fail |
|--------|--------|-----------|
| Connection Time | < 10 seconds | |
| Time to First Frame | < 5 seconds | |
| Video Frame Rate | >= 10 FPS | |
| PTZ Response Latency | < 500ms | |
| Memory Usage | < 200 MB | |
| Error Count | 0 | |

---

## Test Scenarios

### Scenario 1: Happy Path
```
1. Launch app
2. SDK initializes (green status)
3. Tap "Find Cameras"
4. Enter camera UID manually (OKB0379853SNLJ)
5. Enter password (admin)
6. Connection succeeds
7. Video plays
8. PTZ controls work
9. Disconnect cleanly
```

### Scenario 2: Reconnection
```
1. Connect to camera
2. Video playing
3. Walk out of WiFi range (simulate disconnect)
4. App shows reconnecting overlay
5. Walk back in range
6. Auto-reconnect succeeds
7. Video resumes
```

### Scenario 3: Error Recovery
```
1. Connect with wrong password
2. Auth error shown
3. Tap retry
4. Enter correct password
5. Connection succeeds
```

### Scenario 4: Stress Test
```
1. Connect to camera
2. Watch video for 5 minutes
3. Use PTZ controls repeatedly
4. Check memory usage
5. Check for frame drops
6. Check for crashes
```

---

## Testing Checklist

### Pre-Testing Setup
- [ ] Physical Veepa camera available
- [ ] Camera on same WiFi as iPhone
- [ ] Camera UID known (OKB0379853SNLJ)
- [ ] Camera password known (admin)
- [ ] iPhone connected to Mac via USB
- [ ] Xcode console visible

### Flow Tests
- [ ] App launches without crash
- [ ] SDK initializes successfully
- [ ] Manual camera entry works
- [ ] Connection succeeds
- [ ] Video displays (not placeholder)
- [ ] Video FPS > 10
- [ ] PTZ up/down/left/right work
- [ ] PTZ zoom in/out works
- [ ] Disconnect works
- [ ] Reconnect works

### Quality Gate Tests
- [ ] Measure connection time: ___ seconds
- [ ] Measure first frame time: ___ seconds
- [ ] Measure video FPS: ___ FPS
- [ ] Measure PTZ latency: ___ ms
- [ ] Check memory in Xcode: ___ MB

### Edge Case Tests
- [ ] Wrong password handling
- [ ] Camera offline handling
- [ ] Network loss handling
- [ ] App backgrounding
- [ ] App foregrounding
- [ ] Multiple connect/disconnect cycles

---

## Bug Tracking

Document any issues found:

| ID | Description | Severity | Status |
|----|-------------|----------|--------|
| | | | |

---

## Definition of Done

- [ ] All test scenarios pass
- [ ] All quality gates met
- [ ] Known issues documented
- [ ] LEARNINGS.md updated
- [ ] Ready for SciSymbioLens integration

---

## Deliverables

1. **Test Report**: Results of all test scenarios
2. **Quality Gate Report**: Pass/fail for each metric
3. **Bug List**: Any issues found
4. **LEARNINGS.md Update**: Integration insights for SciSymbioLens

---

## LEARNINGS.md Template Update

```markdown
## Epic 15: SDK Integration Learnings

### What Worked
- ...

### What Didn't Work
- ...

### Key Integration Points
- Connection: Use UID-based P2P, not IP
- Video: AppPlayerController provides texture ID
- PTZ: CameraDevice.sendPTZ with client handle

### Recommendations for SciSymbioLens
- ...
```
