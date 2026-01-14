import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:veepa_camera_poc/models/extracted_frame.dart';

/// Callback for extracted frames
typedef FrameCallback = void Function(ExtractedFrame frame);

/// Service for extracting raw frames from video stream
///
/// This service provides frame extraction capabilities for sending
/// video frames to external APIs like Gemini for AI analysis.
class FrameExtractionService extends ChangeNotifier {
  static final FrameExtractionService _instance =
      FrameExtractionService._internal();
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
  StreamController<ExtractedFrame>? _frameController;
  Stream<ExtractedFrame> get frameStream {
    _frameController ??= StreamController<ExtractedFrame>.broadcast();
    return _frameController!.stream;
  }

  /// Texture ID from player
  int? _textureId;
  int? get textureId => _textureId;

  /// Last extracted frame
  ExtractedFrame? _lastFrame;
  ExtractedFrame? get lastFrame => _lastFrame;

  /// RepaintBoundary key for screenshot fallback
  GlobalKey? _repaintBoundaryKey;

  /// Frame extraction timer for simulated/screenshot mode
  Timer? _extractionTimer;

  /// Target FPS for extraction
  static const int targetFPS = 10;

  /// Start frame extraction
  ///
  /// [textureId] - The Flutter texture ID from the video player
  /// [onFrame] - Optional callback for each extracted frame
  /// [repaintBoundaryKey] - Optional key for screenshot fallback method
  Future<void> startExtraction({
    required int textureId,
    FrameCallback? onFrame,
    GlobalKey? repaintBoundaryKey,
  }) async {
    if (_isExtracting) {
      debugPrint('[FrameExtraction] Already extracting, stopping first');
      await stopExtraction();
    }

    debugPrint('[FrameExtraction] Starting frame extraction for texture $textureId');
    _textureId = textureId;
    _onFrame = onFrame;
    _repaintBoundaryKey = repaintBoundaryKey;
    _isExtracting = true;
    _frameCount = 0;
    _frameTimes.clear();
    _lastFrame = null;
    _frameController ??= StreamController<ExtractedFrame>.broadcast();

    // Start frame extraction
    // POC: Use timer-based extraction. In production, would hook into SDK callbacks.
    _startExtractionTimer();

    notifyListeners();
  }

  /// Stop frame extraction
  Future<void> stopExtraction() async {
    debugPrint('[FrameExtraction] Stopping frame extraction');
    _isExtracting = false;
    _extractionTimer?.cancel();
    _extractionTimer = null;
    _textureId = null;
    _onFrame = null;
    _repaintBoundaryKey = null;

    notifyListeners();
  }

  /// Start the frame extraction timer
  void _startExtractionTimer() {
    _extractionTimer?.cancel();
    final interval = Duration(milliseconds: 1000 ~/ targetFPS);

    _extractionTimer = Timer.periodic(interval, (_) {
      if (!_isExtracting) return;
      _captureFrame();
    });
  }

  /// Capture a single frame
  Future<void> _captureFrame() async {
    if (!_isExtracting) return;

    try {
      Uint8List? frameData;
      int width = 1280;
      int height = 720;
      String format = 'rgba';

      // Try RepaintBoundary screenshot if available
      if (_repaintBoundaryKey != null) {
        final boundary = _repaintBoundaryKey!.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.0);
          width = image.width;
          height = image.height;
          final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          if (byteData != null) {
            frameData = byteData.buffer.asUint8List();
            format = 'rgba';
          }
        }
      }

      // Fallback: Generate placeholder frame data for POC testing
      // In production, this would read from actual SDK frame buffer
      frameData ??= _generatePlaceholderFrame(width, height);

      _processFrame(frameData, width, height, format);
    } catch (e, stack) {
      debugPrint('[FrameExtraction] Capture error: $e');
      onError?.call('Frame capture failed: $e');
      debugPrint('$stack');
    }
  }

  /// Generate placeholder frame data for POC testing
  Uint8List _generatePlaceholderFrame(int width, int height) {
    // Generate a simple gradient frame for testing
    // Real implementation would read actual video frame
    final frameSize = width * height * 4; // RGBA
    final data = Uint8List(frameSize);

    // Create a simple pattern based on frame count for visual verification
    final colorPhase = (_frameCount * 10) % 255;
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        data[i] = ((x + colorPhase) % 255); // R
        data[i + 1] = ((y + colorPhase) % 255); // G
        data[i + 2] = ((x + y + colorPhase) % 255); // B
        data[i + 3] = 255; // A
      }
    }

    return data;
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

    _lastFrame = frame;

    if (_frameCount % 30 == 1) {
      debugPrint('[FrameExtraction] Frame #$_frameCount: $frame @ ${_extractionFPS.toStringAsFixed(1)} FPS');
    }

    // Notify listeners
    _onFrame?.call(frame);
    _frameController?.add(frame);
    notifyListeners();
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
      debugPrint('[FrameExtraction] Converting frame to PNG...');

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

      if (byteData != null) {
        final png = byteData.buffer.asUint8List();
        debugPrint('[FrameExtraction] PNG conversion successful: ${(png.length / 1024).toStringAsFixed(1)}KB');
        return png;
      }

      return null;
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
      'lastFrameSize': _lastFrame?.sizeKB ?? 0,
      'lastFrameDimensions': _lastFrame != null
          ? '${_lastFrame!.width}x${_lastFrame!.height}'
          : 'N/A',
    };
  }

  /// Reset the service
  void reset() {
    stopExtraction();
    _frameCount = 0;
    _extractionFPS = 0;
    _frameTimes.clear();
    _lastFrame = null;
    _frameController?.close();
    _frameController = null;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    stopExtraction();
    _frameController?.close();
    super.dispose();
  }
}
