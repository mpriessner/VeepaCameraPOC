import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/extracted_frame.dart';

void main() {
  group('ExtractedFrame', () {
    test('calculates sizeBytes correctly', () {
      final frame = ExtractedFrame(
        data: Uint8List(1024),
        width: 640,
        height: 480,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 1,
      );

      expect(frame.sizeBytes, equals(1024));
    });

    test('calculates sizeKB correctly', () {
      final frame = ExtractedFrame(
        data: Uint8List(1024 * 100), // 100 KB
        width: 640,
        height: 480,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 1,
      );

      expect(frame.sizeKB, closeTo(100, 0.1));
    });

    test('calculates sizeMB correctly', () {
      final frame = ExtractedFrame(
        data: Uint8List(1024 * 1024), // 1 MB
        width: 1280,
        height: 720,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 1,
      );

      expect(frame.sizeMB, closeTo(1.0, 0.01));
    });

    test('calculates expectedSizeBytes for RGBA format', () {
      final frame = ExtractedFrame(
        data: Uint8List(100),
        width: 100,
        height: 100,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 1,
      );

      // RGBA = 4 bytes per pixel, 100x100 = 10000 pixels = 40000 bytes
      expect(frame.expectedSizeBytes, equals(40000));
    });

    test('calculates expectedSizeBytes for RGB format', () {
      final frame = ExtractedFrame(
        data: Uint8List(100),
        width: 100,
        height: 100,
        format: 'rgb',
        timestamp: DateTime.now(),
        frameNumber: 1,
      );

      // RGB = 3 bytes per pixel, 100x100 = 10000 pixels = 30000 bytes
      expect(frame.expectedSizeBytes, equals(30000));
    });

    test('isValidSize returns true for valid frame', () {
      final width = 640;
      final height = 480;
      final frame = ExtractedFrame(
        data: Uint8List(width * height * 4), // RGBA
        width: width,
        height: height,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 1,
      );

      expect(frame.isValidSize, isTrue);
    });

    test('isValidSize returns false for undersized frame', () {
      final frame = ExtractedFrame(
        data: Uint8List(100), // Way too small for 640x480
        width: 640,
        height: 480,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 1,
      );

      expect(frame.isValidSize, isFalse);
    });

    test('toString includes dimensions and format', () {
      final frame = ExtractedFrame(
        data: Uint8List(1024),
        width: 640,
        height: 480,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 5,
      );

      final string = frame.toString();
      expect(string, contains('640x480'));
      expect(string, contains('rgba'));
      expect(string, contains('frame#5'));
    });

    test('copyWithFrameNumber preserves other properties', () {
      final original = ExtractedFrame(
        data: Uint8List(1024),
        width: 640,
        height: 480,
        format: 'rgba',
        timestamp: DateTime(2024, 1, 1),
        frameNumber: 1,
      );

      final copy = original.copyWithFrameNumber(10);

      expect(copy.frameNumber, equals(10));
      expect(copy.width, equals(original.width));
      expect(copy.height, equals(original.height));
      expect(copy.format, equals(original.format));
      expect(copy.timestamp, equals(original.timestamp));
      expect(copy.data, equals(original.data));
    });

    test('frame with typical HD dimensions', () {
      final frame = ExtractedFrame(
        data: Uint8List(1280 * 720 * 4), // HD RGBA
        width: 1280,
        height: 720,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 100,
      );

      expect(frame.sizeBytes, equals(1280 * 720 * 4));
      expect(frame.sizeMB, closeTo(3.52, 0.1));
      expect(frame.isValidSize, isTrue);
    });

    test('stores timestamp correctly', () {
      final timestamp = DateTime(2024, 6, 15, 10, 30, 45);
      final frame = ExtractedFrame(
        data: Uint8List(100),
        width: 10,
        height: 10,
        format: 'rgba',
        timestamp: timestamp,
        frameNumber: 1,
      );

      expect(frame.timestamp, equals(timestamp));
    });

    test('handles empty data', () {
      final frame = ExtractedFrame(
        data: Uint8List(0),
        width: 0,
        height: 0,
        format: 'rgba',
        timestamp: DateTime.now(),
        frameNumber: 0,
      );

      expect(frame.sizeBytes, equals(0));
      expect(frame.sizeKB, equals(0));
      expect(frame.sizeMB, equals(0));
    });
  });
}
