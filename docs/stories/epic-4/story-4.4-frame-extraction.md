# Story 4.4: Prototype Frame Extraction

> **Epic**: 4 - Video Streaming
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Medium

---

## User Story

**As a** developer,
**I want** to extract raw video frames from the Veepa SDK player,
**So that** I can validate that SciSymbioLens Phase 4 can send frames to Gemini API for AI analysis.

---

## Background & Rationale

This story addresses a **critical validation gap** identified in the POC feedback:

> "The current stories focus heavily on *displaying* video, but the ultimate goal (SciSymbioLens) requires *accessing the raw video frames* to send to Gemini."

Without validating frame extraction works, the entire Phase 4 strategy for SciSymbioLens is at risk. This story must be completed before declaring Phase 1 POC successful.

---

## Acceptance Criteria

- [ ] AC1: Raw video frame data (Uint8List) can be extracted from player callback
- [ ] AC2: Frame dimensions (width, height) are accessible
- [ ] AC3: Frame format (YUV/RGB) is identified and documented
- [ ] AC4: Frame extraction rate achieves at least 5 FPS
- [ ] AC5: Frame data can be converted to a standard image format (PNG/JPEG)
- [ ] AC6: Memory usage is stable during continuous frame extraction
- [ ] AC7: Frame extraction performance documented in LEARNINGS.md

---

## Technical Specification

### SDK Frame Callback Analysis

Based on `SDK_ANALYSIS.md`, the SDK provides frame callbacks via FFI:

```dart
// From app_player.dart - Player callbacks provide frame metadata
void _playerCallback(
  int textureId,
  int total_duration,
  int play_duration,
  int cache_progress,
  int loading_status,
  // ... additional frame metadata
)

// GPS data callback
void _playerGPSCallback(
  int textureId,
  int fix_status,
  int satellites_inview,
  double latitude,
  double longitude,
  double speed,
  double course
)

// Drawing/overlay callback with frame dimensions
void _playerDrawCallback(
  int textureId,
  int width,
  int height,
  int draw_type,
  double percent_x1,
  double percent_y1,
  double percent_x2,
  double percent_y2
)
```

### Frame Extraction Service

Create `lib/services/frame_extraction_service.dart`:

```dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// Callback for extracted frames
typedef FrameCallback = void Function(ExtractedFrame frame);

/// Represents an extracted video frame
class ExtractedFrame {
  /// Raw frame data as bytes
  final Uint8List data;

  /// Frame width in pixels
  final int width;

  /// Frame height in pixels
  final int height;

  /// Frame format (e.g., 'rgba', 'yuv420', 'bgra')
  final String format;

  /// Timestamp when frame was captured
  final DateTime timestamp;

  /// Frame sequence number
  final int frameNumber;

  ExtractedFrame({
    required this.data,
    required this.width,
    required this.height,
    required this.format,
    required this.timestamp,
    required this.frameNumber,
  });

  /// Size of frame data in bytes
  int get sizeBytes => data.length;

  /// Size of frame data in KB
  double get sizeKB => sizeBytes / 1024;

  /// Size of frame data in MB
  double get sizeMB => sizeKB / 1024;

  @override
  String toString() => 'ExtractedFrame(${width}x$height, $format, ${sizeKB.toStringAsFixed(1)}KB)';
}

/// Service for extracting raw frames from video stream
class FrameExtractionService {
  static final FrameExtractionService _instance = FrameExtractionService._internal();
  factory FrameExtractionService() => _instance;
  FrameExtractionService._internal();

  /// Whether frame extraction is currently active
  bool _isExtracting = false;
  bool get isExtracting => _isExtracting;

  /// Frame counter
  int _frameCount = 0;
  int get frameCount => _frameCount;

  /// Frame extraction rate (FPS)
  double _extractionFPS = 0;
  double get extractionFPS => _extractionFPS;

  /// Timestamps for FPS calculation
  final List<DateTime> _frameTimes = [];
  static const int _fpsWindowSize = 30;

  /// Frame callback
  FrameCallback? _onFrame;

  /// Error callback
  void Function(String error)? onError;

  /// Stream controller for frames
  final _frameController = StreamController<ExtractedFrame>.broadcast();
  Stream<ExtractedFrame> get frameStream => _frameController.stream;

  /// Texture ID from player
  int? _textureId;

  /// Start frame extraction
  ///
  /// [textureId] - The Flutter texture ID from the video player
  /// [onFrame] - Optional callback for each extracted frame
  Future<void> startExtraction({
    required int textureId,
    FrameCallback? onFrame,
  }) async {
    if (_isExtracting) {
      debugPrint('[FrameExtraction] Already extracting, stopping first');
      await stopExtraction();
    }

    debugPrint('[FrameExtraction] Starting frame extraction for texture $textureId');
    _textureId = textureId;
    _onFrame = onFrame;
    _isExtracting = true;
    _frameCount = 0;
    _frameTimes.clear();

    // Register for frame callbacks from the SDK
    // This will depend on the actual SDK implementation
    _registerFrameCallback();
  }

  /// Stop frame extraction
  Future<void> stopExtraction() async {
    debugPrint('[FrameExtraction] Stopping frame extraction');
    _isExtracting = false;
    _unregisterFrameCallback();
    _textureId = null;
    _onFrame = null;
  }

  /// Register for frame callbacks from SDK
  void _registerFrameCallback() {
    // Implementation depends on SDK's actual callback mechanism
    // Option 1: SDK provides direct frame callback
    // Option 2: Capture from Flutter texture
    // Option 3: Use platform channel to get frames from native layer

    debugPrint('[FrameExtraction] Registering frame callback');

    // TODO: Implement based on SDK exploration
    // This is the critical validation point
  }

  /// Unregister frame callback
  void _unregisterFrameCallback() {
    debugPrint('[FrameExtraction] Unregistering frame callback');
    // TODO: Clean up callback registration
  }

  /// Process an extracted frame
  void _processFrame(Uint8List data, int width, int height, String format) {
    if (!_isExtracting) return;

    _frameCount++;
    final now = DateTime.now();

    // Update FPS calculation
    _frameTimes.add(now);
    if (_frameTimes.length > _fpsWindowSize) {
      _frameTimes.removeAt(0);
    }
    _calculateFPS();

    // Create frame object
    final frame = ExtractedFrame(
      data: data,
      width: width,
      height: height,
      format: format,
      timestamp: now,
      frameNumber: _frameCount,
    );

    debugPrint('[FrameExtraction] Frame #$_frameCount: $frame @ ${_extractionFPS.toStringAsFixed(1)} FPS');

    // Notify listeners
    _onFrame?.call(frame);
    _frameController.add(frame);
  }

  /// Calculate current extraction FPS
  void _calculateFPS() {
    if (_frameTimes.length < 2) {
      _extractionFPS = 0;
      return;
    }

    final duration = _frameTimes.last.difference(_frameTimes.first);
    if (duration.inMilliseconds > 0) {
      _extractionFPS = (_frameTimes.length - 1) / (duration.inMilliseconds / 1000);
    }
  }

  /// Convert frame to PNG bytes (for Gemini API)
  Future<Uint8List?> frameToPng(ExtractedFrame frame) async {
    try {
      // Create image from raw data
      final completer = Completer<ui.Image>();

      ui.decodeImageFromPixels(
        frame.data,
        frame.width,
        frame.height,
        _getPixelFormat(frame.format),
        completer.complete,
      );

      final image = await completer.future;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[FrameExtraction] PNG conversion error: $e');
      onError?.call('Failed to convert frame to PNG: $e');
      return null;
    }
  }

  /// Convert frame to JPEG bytes (smaller size for API)
  Future<Uint8List?> frameToJpeg(ExtractedFrame frame, {int quality = 80}) async {
    // JPEG conversion requires additional package or platform channel
    // For POC, PNG should suffice
    debugPrint('[FrameExtraction] JPEG conversion not implemented, using PNG');
    return frameToPng(frame);
  }

  /// Get pixel format enum from string
  ui.PixelFormat _getPixelFormat(String format) {
    switch (format.toLowerCase()) {
      case 'rgba':
        return ui.PixelFormat.rgba8888;
      case 'bgra':
        return ui.PixelFormat.bgra8888;
      default:
        // Default to RGBA, may need conversion for YUV
        return ui.PixelFormat.rgba8888;
    }
  }

  /// Get extraction statistics
  Map<String, dynamic> getStatistics() {
    return {
      'isExtracting': _isExtracting,
      'frameCount': _frameCount,
      'extractionFPS': _extractionFPS,
      'textureId': _textureId,
    };
  }

  /// Dispose resources
  void dispose() {
    stopExtraction();
    _frameController.close();
  }
}
```

### Frame Extraction Test Widget

Create `lib/widgets/frame_extraction_test.dart`:

```dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_veepa_module/services/frame_extraction_service.dart';

/// Test widget for validating frame extraction
class FrameExtractionTest extends StatefulWidget {
  final int textureId;

  const FrameExtractionTest({
    super.key,
    required this.textureId,
  });

  @override
  State<FrameExtractionTest> createState() => _FrameExtractionTestState();
}

class _FrameExtractionTestState extends State<FrameExtractionTest> {
  final FrameExtractionService _service = FrameExtractionService();

  ExtractedFrame? _lastFrame;
  Uint8List? _lastFramePng;
  String _status = 'Not started';
  final List<String> _logs = [];

  @override
  void dispose() {
    _service.stopExtraction();
    super.dispose();
  }

  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String()}] $message');
      if (_logs.length > 50) _logs.removeAt(0);
    });
  }

  Future<void> _startExtraction() async {
    _log('Starting frame extraction...');
    setState(() => _status = 'Starting...');

    try {
      await _service.startExtraction(
        textureId: widget.textureId,
        onFrame: _onFrameReceived,
      );
      setState(() => _status = 'Extracting');
      _log('Frame extraction started');
    } catch (e) {
      _log('Error: $e');
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _stopExtraction() async {
    _log('Stopping frame extraction...');
    await _service.stopExtraction();
    setState(() => _status = 'Stopped');
    _log('Frame extraction stopped');
  }

  void _onFrameReceived(ExtractedFrame frame) {
    setState(() => _lastFrame = frame);

    // Log every 30th frame to avoid spam
    if (frame.frameNumber % 30 == 0) {
      _log('Frame #${frame.frameNumber}: ${frame.width}x${frame.height}, ${frame.sizeKB.toStringAsFixed(1)}KB');
    }
  }

  Future<void> _convertToPng() async {
    if (_lastFrame == null) {
      _log('No frame to convert');
      return;
    }

    _log('Converting frame to PNG...');
    final png = await _service.frameToPng(_lastFrame!);

    if (png != null) {
      setState(() => _lastFramePng = png);
      _log('PNG conversion successful: ${(png.length / 1024).toStringAsFixed(1)}KB');
    } else {
      _log('PNG conversion failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          const Text(
            'Frame Extraction Test',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Status
          _buildStatusRow('Status', _status),
          _buildStatusRow('Texture ID', '${widget.textureId}'),
          _buildStatusRow('Frames', '${_service.frameCount}'),
          _buildStatusRow('FPS', '${_service.extractionFPS.toStringAsFixed(1)}'),

          if (_lastFrame != null) ...[
            _buildStatusRow('Frame Size', '${_lastFrame!.width}x${_lastFrame!.height}'),
            _buildStatusRow('Data Size', '${_lastFrame!.sizeKB.toStringAsFixed(1)} KB'),
            _buildStatusRow('Format', _lastFrame!.format),
          ],

          const SizedBox(height: 16),

          // Controls
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _service.isExtracting ? null : _startExtraction,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _service.isExtracting ? _stopExtraction : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Stop'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _lastFrame != null ? _convertToPng : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text('To PNG'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Preview (if PNG available)
          if (_lastFramePng != null)
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  _lastFramePng!,
                  fit: BoxFit.contain,
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Logs
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logs[_logs.length - 1 - index],
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

### Investigation Tasks

The frame extraction implementation requires investigation of the actual SDK:

```dart
// Investigation checklist for SDK frame access:

// 1. Check app_player.dart for frame callbacks
//    - Look for: onFrame, frameCallback, videoFrame
//    - Check: _playerCallback parameters

// 2. Check if texture data is accessible
//    - Flutter Texture widget exposes textureId
//    - May need platform channel to read texture pixels

// 3. Check native layer (libVSTC.a)
//    - iOS may provide frame buffer access
//    - Look for CVPixelBuffer or CMSampleBuffer

// 4. Alternative: Screenshot approach
//    - Use RepaintBoundary to capture rendered frame
//    - Less efficient but guaranteed to work
```

---

## Implementation Tasks

### Task 1: Analyze SDK Frame Callbacks
Study `app_player.dart` to understand frame callback mechanism.

**Verification**: Document findings in dev notes

### Task 2: Create ExtractedFrame Model
Create the data model for extracted frames.

**Verification**: Model compiles without errors

### Task 3: Create FrameExtractionService
Implement the frame extraction service.

**Verification**: Service initializes correctly

### Task 4: Implement Frame Callback Registration
Connect to SDK's frame callback mechanism.

**Verification**: Callbacks received when video plays

### Task 5: Test Frame Data Extraction
Verify raw frame data is accessible.

**Verification**: Frame data is non-empty Uint8List

### Task 6: Implement PNG Conversion
Convert extracted frames to PNG format.

**Verification**: PNG data viewable as image

### Task 7: Create Test Widget
Create UI for testing frame extraction.

**Verification**: Widget displays frame statistics

### Task 8: Measure Performance
Measure extraction FPS and memory usage.

**Verification**: Achieves >= 5 FPS, memory stable

### Task 9: Document Findings
Document frame extraction approach in LEARNINGS.md.

**Verification**: Documentation complete

---

## Test Cases

### TC4.4.1: Frame Callback Registration
**Type**: Unit Test
**Priority**: P0

```dart
// test/services/frame_extraction_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_veepa_module/services/frame_extraction_service.dart';

void main() {
  group('FrameExtractionService', () {
    late FrameExtractionService service;

    setUp(() {
      service = FrameExtractionService();
    });

    tearDown(() {
      service.dispose();
    });

    test('starts extraction successfully', () async {
      await service.startExtraction(textureId: 1);
      expect(service.isExtracting, isTrue);
    });

    test('stops extraction successfully', () async {
      await service.startExtraction(textureId: 1);
      await service.stopExtraction();
      expect(service.isExtracting, isFalse);
    });

    test('tracks frame count', () async {
      expect(service.frameCount, equals(0));
    });
  });
}
```

**Given**: FrameExtractionService instance
**When**: startExtraction called
**Then**: Service is in extracting state

---

### TC4.4.2: Frame Data Non-Empty
**Type**: Integration Test (Device Only)
**Priority**: P0

```dart
test('extracted frame data is non-empty', () async {
  final service = FrameExtractionService();
  ExtractedFrame? receivedFrame;

  await service.startExtraction(
    textureId: testTextureId,
    onFrame: (frame) => receivedFrame = frame,
  );

  // Wait for first frame
  await Future.delayed(const Duration(seconds: 2));

  expect(receivedFrame, isNotNull);
  expect(receivedFrame!.data.isNotEmpty, isTrue);
  expect(receivedFrame!.width, greaterThan(0));
  expect(receivedFrame!.height, greaterThan(0));

  await service.stopExtraction();
});
```

**Given**: Video playing from Veepa camera
**When**: Frame extraction active
**Then**: Frame data contains valid bytes

---

### TC4.4.3: Frame Dimensions Valid
**Type**: Integration Test (Device Only)
**Priority**: P0

```dart
test('frame dimensions are valid', () async {
  // Expect reasonable video dimensions (e.g., 640x480, 1280x720, 1920x1080)
  final frame = await extractTestFrame();

  expect(frame.width, greaterThanOrEqualTo(320));
  expect(frame.width, lessThanOrEqualTo(4096));
  expect(frame.height, greaterThanOrEqualTo(240));
  expect(frame.height, lessThanOrEqualTo(2160));
});
```

**Given**: Extracted frame
**When**: Checking dimensions
**Then**: Width and height are valid video dimensions

---

### TC4.4.4: PNG Conversion Works
**Type**: Integration Test (Device Only)
**Priority**: P0

```dart
test('frame converts to valid PNG', () async {
  final service = FrameExtractionService();
  final frame = await extractTestFrame();

  final png = await service.frameToPng(frame);

  expect(png, isNotNull);
  expect(png!.isNotEmpty, isTrue);

  // PNG magic bytes: 0x89 0x50 0x4E 0x47
  expect(png[0], equals(0x89));
  expect(png[1], equals(0x50)); // 'P'
  expect(png[2], equals(0x4E)); // 'N'
  expect(png[3], equals(0x47)); // 'G'
});
```

**Given**: Extracted frame
**When**: Converting to PNG
**Then**: Output is valid PNG data

---

### TC4.4.5: Extraction FPS Meets Minimum
**Type**: Integration Test (Device Only)
**Priority**: P0

```dart
test('extraction achieves minimum 5 FPS', () async {
  final service = FrameExtractionService();

  await service.startExtraction(textureId: testTextureId);

  // Let it run for 5 seconds
  await Future.delayed(const Duration(seconds: 5));

  expect(service.extractionFPS, greaterThanOrEqualTo(5.0));
  expect(service.frameCount, greaterThanOrEqualTo(25));

  await service.stopExtraction();
});
```

**Given**: Frame extraction running
**When**: After 5 seconds
**Then**: FPS >= 5, frame count >= 25

---

### TC4.4.6: Memory Stability Test
**Type**: Integration Test (Device Only)
**Priority**: P1

```dart
test('memory stable during extraction', () async {
  final service = FrameExtractionService();

  // Get baseline memory
  final baselineMemory = await getAppMemoryUsage();

  await service.startExtraction(textureId: testTextureId);

  // Run for 30 seconds
  await Future.delayed(const Duration(seconds: 30));

  final finalMemory = await getAppMemoryUsage();

  // Allow 50MB growth maximum
  final memoryGrowth = finalMemory - baselineMemory;
  expect(memoryGrowth, lessThan(50 * 1024 * 1024));

  await service.stopExtraction();
});
```

**Given**: Frame extraction running for 30 seconds
**When**: Checking memory usage
**Then**: Memory growth < 50MB

---

### TC4.4.7: ExtractedFrame Model Test
**Type**: Unit Test
**Priority**: P1

```dart
test('ExtractedFrame calculates sizes correctly', () {
  final frame = ExtractedFrame(
    data: Uint8List(1024 * 100), // 100 KB
    width: 640,
    height: 480,
    format: 'rgba',
    timestamp: DateTime.now(),
    frameNumber: 1,
  );

  expect(frame.sizeBytes, equals(1024 * 100));
  expect(frame.sizeKB, closeTo(100, 0.1));
  expect(frame.sizeMB, closeTo(0.0977, 0.01));
});
```

**Given**: ExtractedFrame with known data size
**When**: Accessing size properties
**Then**: Calculations are accurate

---

### TC4.4.8: Manual Frame Extraction Verification
**Type**: Manual (Device Only)
**Priority**: P0

**Preconditions**:
- Physical iOS device connected
- Veepa camera available
- Video stream working (Story 4.2 complete)

**Steps**:
1. Launch app on physical device
2. Connect to Veepa camera
3. Start video playback
4. Open frame extraction test UI
5. Tap "Start" to begin extraction
6. Observe frame count increasing
7. Observe FPS value
8. Tap "To PNG" to convert frame
9. Verify PNG preview displays
10. Run for 2 minutes, note memory in Xcode
11. Tap "Stop" to end extraction

**Expected Results**:
- [ ] Frame count increases steadily
- [ ] FPS >= 5 sustained
- [ ] PNG conversion produces visible image
- [ ] Image matches current camera view
- [ ] Memory stable (no continuous growth)
- [ ] No crashes or errors

---

### TC4.4.9: Frame Format Identification
**Type**: Investigation/Manual
**Priority**: P1

**Steps**:
1. Start frame extraction
2. Log frame format from SDK
3. Document pixel format (RGBA, BGRA, YUV420, etc.)
4. Verify format in LEARNINGS.md

**Expected Results**:
- [ ] Frame format identified
- [ ] Format documented
- [ ] Conversion strategy documented if YUV

---

## Test Environment Requirements

**IMPORTANT**: This story requires testing on a **physical iOS device**. The Veepa SDK native library (`libVSTC.a`) is arm64 architecture only and does not support iOS Simulator.

| Test Case | Simulator | Device |
|-----------|-----------|--------|
| TC4.4.1 | Yes | Yes |
| TC4.4.2 | No | **Required** |
| TC4.4.3 | No | **Required** |
| TC4.4.4 | No | **Required** |
| TC4.4.5 | No | **Required** |
| TC4.4.6 | No | **Required** |
| TC4.4.7 | Yes | Yes |
| TC4.4.8 | No | **Required** |
| TC4.4.9 | No | **Required** |

---

## Definition of Done

- [ ] All acceptance criteria (AC1-AC7) verified
- [ ] All P0 test cases pass on physical device
- [ ] Frame extraction achieves >= 5 FPS
- [ ] PNG conversion produces valid images
- [ ] Memory usage is stable
- [ ] Findings documented in LEARNINGS.md
- [ ] Code committed with message: "feat(epic-4): Frame extraction prototype - Story 4.4"
- [ ] Story status updated to "Done"

---

## Dependencies

- **Depends On**: Story 4.1 (Player Service), Story 4.2 (Video Display)
- **Blocks**: Phase 1 completion (critical validation for SciSymbioLens)

---

## Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| SDK doesn't expose frame data | Critical | Medium | Use screenshot fallback with RepaintBoundary |
| Frames are GPU-only textures | High | Medium | Platform channel to read native texture |
| YUV format requires conversion | Medium | High | Implement YUV→RGB converter |
| Poor extraction performance | High | Low | Reduce resolution or frame rate |
| Memory leaks with frame data | Medium | Medium | Careful disposal, limit stored frames |

---

## Fallback Approaches

If direct frame extraction fails, these fallbacks are available:

### Fallback 1: RepaintBoundary Screenshot
```dart
Future<Uint8List?> captureVideoFrame(GlobalKey repaintKey) async {
  final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;

  final image = await boundary.toImage(pixelRatio: 1.0);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
```

### Fallback 2: Native Platform Channel
```swift
// iOS side - read from CVPixelBuffer if available
func captureFrame() -> Data? {
    // Access video frame buffer from SDK
    // Convert to PNG/JPEG
    // Return to Flutter
}
```

---

## References

- [SDK_ANALYSIS.md - Data Extraction Points](/Users/mpriessner/windsurf_repos/Veepaisdk/SDK_ANALYSIS.md)
- [Flutter Texture Widget](https://api.flutter.dev/flutter/widgets/Texture-class.html)
- [dart:ui Image](https://api.flutter.dev/flutter/dart-ui/Image-class.html)

---

## Dev Notes

*To be filled during implementation:*

- Frame callback mechanism discovered: ___
- Frame format: ___
- Actual FPS achieved: ___
- Memory usage pattern: ___
- Fallback approach needed: Yes/No

---

## QA Results

| Test Case | Result | Date | Notes |
|-----------|--------|------|-------|
| TC4.4.1 | | | |
| TC4.4.2 | | | |
| TC4.4.3 | | | |
| TC4.4.4 | | | |
| TC4.4.5 | | | |
| TC4.4.6 | | | |
| TC4.4.7 | | | |
| TC4.4.8 | | | |
| TC4.4.9 | | | |

---
