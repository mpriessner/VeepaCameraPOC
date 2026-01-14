# Story 13.2: Quality Gate Validation

## Story
As a developer, I need to validate all quality gates with real camera hardware.

## Acceptance Criteria
- [ ] All quality gates tested with real hardware
- [ ] Results compared to thresholds
- [ ] Pass/fail report generated
- [ ] Metrics exported for analysis
- [ ] Recommendations for failed gates

## Technical Details

### Quality Gates
| Gate | Threshold | Test Method |
|------|-----------|-------------|
| Connection Time | < 10s | Time from connect() to connected state |
| First Frame | < 5s | Time from connected to first video frame |
| FPS | > 10 | Average over 30 second window |
| PTZ Latency | < 500ms | Round-trip command time |
| Error Rate | 0 | Errors during test session |

### Implementation
1. Extend E2EMetrics for real hardware
2. Create validation runner
3. Generate pass/fail report
4. Export metrics to JSON/CSV

### Files to Modify
- `flutter_veepa_module/lib/utils/e2e_metrics.dart`
- `flutter_veepa_module/lib/testing/quality_gate_validator.dart`
- `flutter_veepa_module/lib/screens/hardware_test_screen.dart`

## Definition of Done
- [ ] All gates validated with real hardware
- [ ] Report generation works
- [ ] Export functionality works
- [ ] Results documented
- [ ] Code committed
