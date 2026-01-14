import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/extracted_frame.dart';
import 'package:veepa_camera_poc/services/frame_extraction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FrameExtractionService', () {
    late FrameExtractionService service;

    setUp(() {
      service = FrameExtractionService();
      service.reset();
    });

    tearDown(() {
      service.stopExtraction();
      service.reset();
    });

    group('initial state', () {
      test('is not extracting initially', () {
        expect(service.isExtracting, isFalse);
      });

      test('frame count starts at zero', () {
        expect(service.frameCount, equals(0));
      });

      test('extraction FPS starts at zero', () {
        expect(service.extractionFPS, equals(0));
      });

      test('texture ID is null initially', () {
        expect(service.textureId, isNull);
      });

      test('last frame is null initially', () {
        expect(service.lastFrame, isNull);
      });
    });

    group('startExtraction', () {
      test('sets isExtracting to true', () async {
        await service.startExtraction(textureId: 1);
        expect(service.isExtracting, isTrue);
      });

      test('stores texture ID', () async {
        await service.startExtraction(textureId: 42);
        expect(service.textureId, equals(42));
      });

      test('resets frame count on new extraction', () async {
        await service.startExtraction(textureId: 1);
        // Wait for a few frames
        await Future.delayed(const Duration(milliseconds: 300));
        final firstCount = service.frameCount;
        expect(firstCount, greaterThan(0));

        // Restart extraction
        await service.startExtraction(textureId: 2);
        // After restart, frame count should reset or be very low
        expect(service.frameCount, lessThan(firstCount));
      });

      test('notifies listeners', () async {
        int notificationCount = 0;
        service.addListener(() => notificationCount++);

        await service.startExtraction(textureId: 1);
        expect(notificationCount, greaterThanOrEqualTo(1));
      });
    });

    group('stopExtraction', () {
      test('sets isExtracting to false', () async {
        await service.startExtraction(textureId: 1);
        await service.stopExtraction();
        expect(service.isExtracting, isFalse);
      });

      test('clears texture ID', () async {
        await service.startExtraction(textureId: 1);
        await service.stopExtraction();
        expect(service.textureId, isNull);
      });

      test('notifies listeners', () async {
        int notificationCount = 0;
        await service.startExtraction(textureId: 1);

        service.addListener(() => notificationCount++);
        await service.stopExtraction();

        expect(notificationCount, greaterThanOrEqualTo(1));
      });
    });

    group('frame extraction', () {
      test('extracts frames over time', () async {
        await service.startExtraction(textureId: 1);

        // Wait for frames to be extracted
        await Future.delayed(const Duration(milliseconds: 500));

        expect(service.frameCount, greaterThan(0));
        await service.stopExtraction();
      });

      test('calls onFrame callback with frames', () async {
        final receivedFrames = <ExtractedFrame>[];

        await service.startExtraction(
          textureId: 1,
          onFrame: (frame) => receivedFrames.add(frame),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        await service.stopExtraction();

        expect(receivedFrames, isNotEmpty);
      });

      test('frames have valid dimensions', () async {
        ExtractedFrame? receivedFrame;

        await service.startExtraction(
          textureId: 1,
          onFrame: (frame) => receivedFrame = frame,
        );

        await Future.delayed(const Duration(milliseconds: 200));
        await service.stopExtraction();

        expect(receivedFrame, isNotNull);
        expect(receivedFrame!.width, greaterThan(0));
        expect(receivedFrame!.height, greaterThan(0));
      });

      test('frames have non-empty data', () async {
        ExtractedFrame? receivedFrame;

        await service.startExtraction(
          textureId: 1,
          onFrame: (frame) => receivedFrame = frame,
        );

        await Future.delayed(const Duration(milliseconds: 200));
        await service.stopExtraction();

        expect(receivedFrame, isNotNull);
        expect(receivedFrame!.data, isNotEmpty);
      });

      test('frames have sequential frame numbers', () async {
        final receivedFrames = <ExtractedFrame>[];

        await service.startExtraction(
          textureId: 1,
          onFrame: (frame) => receivedFrames.add(frame),
        );

        await Future.delayed(const Duration(milliseconds: 500));
        await service.stopExtraction();

        expect(receivedFrames.length, greaterThanOrEqualTo(2));

        // Verify sequential numbering
        for (var i = 1; i < receivedFrames.length; i++) {
          expect(
            receivedFrames[i].frameNumber,
            equals(receivedFrames[i - 1].frameNumber + 1),
          );
        }
      });

      test('updates lastFrame property', () async {
        await service.startExtraction(textureId: 1);
        await Future.delayed(const Duration(milliseconds: 200));

        expect(service.lastFrame, isNotNull);
        await service.stopExtraction();
      });
    });

    group('FPS calculation', () {
      test('calculates FPS after multiple frames', () async {
        await service.startExtraction(textureId: 1);

        // Wait for enough frames to calculate FPS
        await Future.delayed(const Duration(milliseconds: 500));

        expect(service.extractionFPS, greaterThan(0));
        await service.stopExtraction();
      });

      test('FPS is within reasonable range', () async {
        await service.startExtraction(textureId: 1);
        await Future.delayed(const Duration(milliseconds: 500));

        // Target is 10 FPS, allow some variance
        expect(service.extractionFPS, greaterThan(5));
        expect(service.extractionFPS, lessThan(20));
        await service.stopExtraction();
      });
    });

    group('frame stream', () {
      test('emits frames to stream', () async {
        final receivedFrames = <ExtractedFrame>[];
        final subscription = service.frameStream.listen(receivedFrames.add);

        await service.startExtraction(textureId: 1);
        await Future.delayed(const Duration(milliseconds: 300));
        await service.stopExtraction();

        await subscription.cancel();

        expect(receivedFrames, isNotEmpty);
      });
    });

    group('getStatistics', () {
      test('returns statistics map', () async {
        await service.startExtraction(textureId: 42);
        await Future.delayed(const Duration(milliseconds: 200));

        final stats = service.getStatistics();

        expect(stats['isExtracting'], isTrue);
        expect(stats['frameCount'], greaterThan(0));
        expect(stats['textureId'], equals(42));
        expect(stats.containsKey('extractionFPS'), isTrue);
        expect(stats.containsKey('lastFrameSize'), isTrue);
        expect(stats.containsKey('lastFrameDimensions'), isTrue);

        await service.stopExtraction();
      });
    });

    group('reset', () {
      test('clears all state', () async {
        await service.startExtraction(textureId: 1);
        await Future.delayed(const Duration(milliseconds: 200));

        service.reset();

        expect(service.isExtracting, isFalse);
        expect(service.frameCount, equals(0));
        expect(service.extractionFPS, equals(0));
        expect(service.lastFrame, isNull);
      });
    });

    group('frameToPng', () {
      test('converts frame to PNG bytes', () async {
        await service.startExtraction(textureId: 1);
        await Future.delayed(const Duration(milliseconds: 200));

        final frame = service.lastFrame;
        expect(frame, isNotNull);

        final png = await service.frameToPng(frame!);
        expect(png, isNotNull);
        expect(png, isNotEmpty);

        await service.stopExtraction();
      });

      test('PNG has valid PNG header', () async {
        await service.startExtraction(textureId: 1);
        await Future.delayed(const Duration(milliseconds: 200));

        final frame = service.lastFrame;
        expect(frame, isNotNull);

        final png = await service.frameToPng(frame!);
        expect(png, isNotNull);
        expect(png!.length, greaterThan(8));

        // PNG magic bytes: 0x89 0x50 0x4E 0x47
        expect(png[0], equals(0x89));
        expect(png[1], equals(0x50)); // 'P'
        expect(png[2], equals(0x4E)); // 'N'
        expect(png[3], equals(0x47)); // 'G'

        await service.stopExtraction();
      });
    });
  });
}
