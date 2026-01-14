# Story 13.1: Hardware Test Suite

## Story
As a developer, I need a comprehensive test suite for validating real camera integration.

## Acceptance Criteria
- [ ] Test harness for real camera tests
- [ ] Connection test (LAN and P2P)
- [ ] Video streaming test
- [ ] PTZ movement test
- [ ] Latency measurement tests
- [ ] Test results logging

## Technical Details

### Test Categories
1. **Connection Tests**
   - LAN discovery time
   - P2P connection time
   - Reconnection after disconnect
   - Multiple connection attempts

2. **Video Tests**
   - Time to first frame
   - Frame rate stability
   - Resolution verification
   - Stream duration test

3. **PTZ Tests**
   - Command response time
   - All directions work
   - Stop command effectiveness
   - Preset position accuracy

### Implementation
1. Create `HardwareTestRunner` class
2. Create individual test cases
3. Results collection and reporting
4. Manual trigger UI for tests

### Files to Create
- `flutter_veepa_module/lib/testing/hardware_test_runner.dart`
- `flutter_veepa_module/lib/testing/connection_tests.dart`
- `flutter_veepa_module/lib/testing/video_tests.dart`
- `flutter_veepa_module/lib/testing/ptz_tests.dart`
- `flutter_veepa_module/lib/screens/hardware_test_screen.dart`

## Definition of Done
- [ ] Test harness implemented
- [ ] All test categories covered
- [ ] Results reporting works
- [ ] Test UI accessible
- [ ] Code committed
