import 'dart:typed_data';

/// Represents an extracted video frame from the camera stream
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

  /// Expected size based on dimensions and format (RGBA = 4 bytes per pixel)
  int get expectedSizeBytes {
    final bytesPerPixel = format.toLowerCase() == 'rgba' ? 4 : 3;
    return width * height * bytesPerPixel;
  }

  /// Whether frame data size matches expected size
  bool get isValidSize => data.length >= (width * height);

  @override
  String toString() =>
      'ExtractedFrame(${width}x$height, $format, ${sizeKB.toStringAsFixed(1)}KB, frame#$frameNumber)';

  /// Create a copy with new frame number
  ExtractedFrame copyWithFrameNumber(int newFrameNumber) {
    return ExtractedFrame(
      data: data,
      width: width,
      height: height,
      format: format,
      timestamp: timestamp,
      frameNumber: newFrameNumber,
    );
  }
}
