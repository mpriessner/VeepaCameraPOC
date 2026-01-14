# Story 4.3: Handle Video Errors

> **Epic**: 4 - Video Streaming
> **Status**: Draft
> **Priority**: P1 - Should Have
> **Estimated Effort**: Small

---

## User Story

**As a** user,
**I want** video errors handled gracefully,
**So that** I can continue using the app without frustration.

---

## Acceptance Criteria

- [ ] AC1: Video errors detected and logged
- [ ] AC2: User-friendly error message displayed (no technical jargon)
- [ ] AC3: Retry button available on error
- [ ] AC4: Option to return to camera list
- [ ] AC5: App doesn't crash on any video error
- [ ] AC6: Multiple error types distinguished (timeout, decode, stream)
- [ ] AC7: Recovery from transient errors automatic

---

## Technical Specification

### Video Error Types

```dart
/// Types of video errors
enum VideoErrorType {
  /// No data received within timeout
  bufferingTimeout,

  /// Frame decode failed
  decodeError,

  /// Stream unexpectedly ended
  streamEnded,

  /// Network error during streaming
  networkError,

  /// SDK/Player internal error
  playerError,

  /// Unknown error
  unknown,
}

extension VideoErrorTypeExtension on VideoErrorType {
  String get userMessage {
    switch (this) {
      case VideoErrorType.bufferingTimeout:
        return 'Unable to load video. Please check your connection and try again.';
      case VideoErrorType.decodeError:
        return 'Video format error. The stream may be corrupted.';
      case VideoErrorType.streamEnded:
        return 'Video stream ended unexpectedly. The camera may have disconnected.';
      case VideoErrorType.networkError:
        return 'Network error. Please check your WiFi connection.';
      case VideoErrorType.playerError:
        return 'Video player error. Please try restarting the stream.';
      case VideoErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  bool get isRecoverable {
    switch (this) {
      case VideoErrorType.bufferingTimeout:
      case VideoErrorType.networkError:
        return true;
      case VideoErrorType.decodeError:
      case VideoErrorType.streamEnded:
      case VideoErrorType.playerError:
      case VideoErrorType.unknown:
        return false;
    }
  }
}
```

### VideoErrorHandler

Create `lib/services/video_error_handler.dart`:

```dart
import 'package:flutter/foundation.dart';

/// Handles video error classification and recovery
class VideoErrorHandler {
  /// Classify error from exception
  static VideoErrorType classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout') || errorString.contains('buffering')) {
      return VideoErrorType.bufferingTimeout;
    }

    if (errorString.contains('decode') || errorString.contains('codec')) {
      return VideoErrorType.decodeError;
    }

    if (errorString.contains('end') || errorString.contains('eof')) {
      return VideoErrorType.streamEnded;
    }

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return VideoErrorType.networkError;
    }

    if (errorString.contains('player') || errorString.contains('sdk')) {
      return VideoErrorType.playerError;
    }

    return VideoErrorType.unknown;
  }

  /// Get retry delay based on error type
  static Duration getRetryDelay(VideoErrorType type) {
    switch (type) {
      case VideoErrorType.bufferingTimeout:
        return const Duration(seconds: 2);
      case VideoErrorType.networkError:
        return const Duration(seconds: 5);
      default:
        return const Duration(seconds: 3);
    }
  }

  /// Log error with context
  static void logError(VideoErrorType type, dynamic error, [StackTrace? stack]) {
    debugPrint('[VideoError] Type: ${type.name}');
    debugPrint('[VideoError] Message: ${type.userMessage}');
    debugPrint('[VideoError] Original: $error');
    if (stack != null) {
      debugPrint('[VideoError] Stack: $stack');
    }
  }
}
```

### VideoErrorWidget

Create `lib/widgets/video_error_widget.dart`:

```dart
import 'package:flutter/material.dart';

/// Widget displayed when video error occurs
class VideoErrorWidget extends StatelessWidget {
  final VideoErrorType errorType;
  final String? technicalError;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;
  final bool showTechnicalDetails;

  const VideoErrorWidget({
    super.key,
    required this.errorType,
    this.technicalError,
    required this.onRetry,
    required this.onGoBack,
    this.showTechnicalDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Icon(
                _getErrorIcon(),
                size: 64,
                color: Colors.red[400],
              ),
              const SizedBox(height: 24),

              // Error title
              Text(
                _getErrorTitle(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // User-friendly message
              Text(
                errorType.userMessage,
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),

              // Technical details (debug mode)
              if (showTechnicalDetails && technicalError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    technicalError!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onGoBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),

              // Recovery hint
              if (errorType.isRecoverable) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[600], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'This error may resolve automatically',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (errorType) {
      case VideoErrorType.bufferingTimeout:
        return Icons.hourglass_empty;
      case VideoErrorType.networkError:
        return Icons.wifi_off;
      case VideoErrorType.streamEnded:
        return Icons.videocam_off;
      case VideoErrorType.decodeError:
        return Icons.broken_image;
      default:
        return Icons.error_outline;
    }
  }

  String _getErrorTitle() {
    switch (errorType) {
      case VideoErrorType.bufferingTimeout:
        return 'Video Loading Timeout';
      case VideoErrorType.networkError:
        return 'Network Error';
      case VideoErrorType.streamEnded:
        return 'Stream Ended';
      case VideoErrorType.decodeError:
        return 'Video Format Error';
      default:
        return 'Video Error';
    }
  }
}
```

### Integration in VideoScreen

```dart
Widget _buildVideoContent(PlayerState state) {
  if (state == PlayerState.error) {
    final errorType = VideoErrorHandler.classifyError(
      _playerService.errorMessage ?? 'Unknown error'
    );

    return VideoErrorWidget(
      errorType: errorType,
      technicalError: _showDebugInfo ? _playerService.errorMessage : null,
      showTechnicalDetails: _showDebugInfo,
      onRetry: _startVideo,
      onGoBack: _goBack,
    );
  }

  // ... rest of video content
}
```

---

## Implementation Tasks

### Task 1: Create VideoErrorType Enum
Create error classification enum.

**Verification**: No lint errors

### Task 2: Create VideoErrorHandler
Create error classification and logging utility.

**Verification**: Errors classified correctly

### Task 3: Create VideoErrorWidget
Create user-friendly error display widget.

**Verification**: Widget renders correctly

### Task 4: Integrate in VideoScreen
Update video screen to use error widget.

**Verification**: Errors display correctly

### Task 5: Test All Error Types
Trigger each error type and verify display.

**Verification**: All error types handled

---

## Test Cases

### TC4.3.1: Error Classification
**Type**: Unit Test
**Priority**: P0

```dart
// test/services/video_error_handler_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/video_error_handler.dart';

void main() {
  group('VideoErrorHandler', () {
    test('classifies timeout errors', () {
      expect(
        VideoErrorHandler.classifyError('Buffering timeout'),
        VideoErrorType.bufferingTimeout,
      );
    });

    test('classifies network errors', () {
      expect(
        VideoErrorHandler.classifyError('Socket connection failed'),
        VideoErrorType.networkError,
      );
    });

    test('classifies decode errors', () {
      expect(
        VideoErrorHandler.classifyError('Codec decode error'),
        VideoErrorType.decodeError,
      );
    });

    test('returns unknown for unclassified errors', () {
      expect(
        VideoErrorHandler.classifyError('Random error message'),
        VideoErrorType.unknown,
      );
    });
  });
}
```

**Given**: Error message string
**When**: classifyError() called
**Then**: Returns correct error type

---

### TC4.3.2: User Messages Appropriate
**Type**: Unit Test
**Priority**: P1

```dart
test('user messages are non-technical', () {
  for (final type in VideoErrorType.values) {
    final message = type.userMessage;

    // Should not contain technical terms
    expect(message.toLowerCase(), isNot(contains('exception')));
    expect(message.toLowerCase(), isNot(contains('stack')));
    expect(message.toLowerCase(), isNot(contains('null')));

    // Should be helpful
    expect(message.length, greaterThan(20));
  }
});
```

**Given**: All error types
**When**: Getting user message
**Then**: Messages are user-friendly

---

### TC4.3.3: Error Widget Displays Correctly
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('VideoErrorWidget shows error info', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VideoErrorWidget(
          errorType: VideoErrorType.networkError,
          technicalError: 'Socket closed',
          onRetry: () {},
          onGoBack: () {},
        ),
      ),
    ),
  );

  expect(find.text('Network Error'), findsOneWidget);
  expect(find.textContaining('WiFi'), findsOneWidget);
  expect(find.text('Try Again'), findsOneWidget);
  expect(find.text('Go Back'), findsOneWidget);
});
```

**Given**: VideoErrorWidget
**When**: Rendered
**Then**: Shows title, message, and buttons

---

### TC4.3.4: Retry Button Works
**Type**: Widget Test
**Priority**: P0

```dart
testWidgets('Retry button triggers callback', (tester) async {
  bool retryCalled = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VideoErrorWidget(
          errorType: VideoErrorType.bufferingTimeout,
          onRetry: () => retryCalled = true,
          onGoBack: () {},
        ),
      ),
    ),
  );

  await tester.tap(find.text('Try Again'));
  expect(retryCalled, isTrue);
});
```

**Given**: Error widget displayed
**When**: Retry button tapped
**Then**: Callback invoked

---

### TC4.3.5: Manual Error Recovery Test
**Type**: Manual
**Priority**: P0

**Preconditions**:
- Connected to camera
- Video playing

**Steps**:
1. While video is playing, disable WiFi
2. Observe error display
3. Note error type shown
4. Re-enable WiFi
5. Tap "Try Again"
6. Verify video resumes

**Expected Results**:
- [ ] Error detected within seconds
- [ ] User-friendly message shown
- [ ] Network error correctly classified
- [ ] Retry works after network restored
- [ ] No app crash

---

### TC4.3.6: Technical Details in Debug Mode
**Type**: Widget Test
**Priority**: P2

```dart
testWidgets('Technical details shown in debug mode', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VideoErrorWidget(
          errorType: VideoErrorType.playerError,
          technicalError: 'SDK_ERROR_CODE_42',
          showTechnicalDetails: true,
          onRetry: () {},
          onGoBack: () {},
        ),
      ),
    ),
  );

  expect(find.text('SDK_ERROR_CODE_42'), findsOneWidget);
});
```

**Given**: Error widget with debug mode on
**When**: Rendered
**Then**: Technical error visible

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC7) verified
- [ ] All P0 test cases pass
- [ ] Error classification works for all types
- [ ] User messages are friendly and helpful
- [ ] Retry functionality works
- [ ] No crashes on any error
- [ ] Code committed with message: "feat(epic-4): Handle video errors - Story 4.3"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 4.1 (Player Service), Story 4.2 (Video UI)
- **Blocks**: None

---

## References

- [Material Design Error States](https://m3.material.io/foundations/interaction/states/error)
- [Flutter Error Handling](https://docs.flutter.dev/testing/errors)

---

## Dev Notes

*Implementation notes will be added during development*

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC4.3.1 | | | |
| TC4.3.2 | | | |
| TC4.3.3 | | | |
| TC4.3.4 | | | |
| TC4.3.5 | | | |
| TC4.3.6 | | | |

---
