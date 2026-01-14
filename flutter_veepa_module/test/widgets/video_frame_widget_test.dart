import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/widgets/video_frame_widget.dart';

void main() {
  group('VideoFrame', () {
    test('creates with required parameters', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final frame = VideoFrame(
        data: data,
        width: 640,
        height: 480,
      );

      expect(frame.data, data);
      expect(frame.width, 640);
      expect(frame.height, 480);
      expect(frame.timestamp, isNotNull);
    });

    test('uses provided timestamp', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0, 0);
      final frame = VideoFrame(
        data: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
        timestamp: timestamp,
      );

      expect(frame.timestamp, timestamp);
    });
  });

  group('VideoFrameWidget', () {
    testWidgets('shows placeholder when no stream', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoFrameWidget(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading video...'), findsOneWidget);
    });

    testWidgets('shows custom placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: VideoFrameWidget(
              placeholder: Text('Custom Placeholder'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Placeholder'), findsOneWidget);
    });

    testWidgets('shows error widget on stream error', (tester) async {
      final controller = StreamController<VideoFrame>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFrameWidget(
              frameStream: controller.stream,
            ),
          ),
        ),
      );

      controller.addError('Test error');
      await tester.pump();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Video error'), findsOneWidget);

      await controller.close();
    });

    testWidgets('shows custom error widget', (tester) async {
      final controller = StreamController<VideoFrame>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFrameWidget(
              frameStream: controller.stream,
              errorWidget: const Text('Custom Error'),
            ),
          ),
        ),
      );

      controller.addError('Test error');
      await tester.pump();

      expect(find.text('Custom Error'), findsOneWidget);

      await controller.close();
    });

    testWidgets('updates when stream changes', (tester) async {
      final controller1 = StreamController<VideoFrame>.broadcast();
      final controller2 = StreamController<VideoFrame>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFrameWidget(
              frameStream: controller1.stream,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFrameWidget(
              frameStream: controller2.stream,
            ),
          ),
        ),
      );

      // Should show placeholder after stream change
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await controller1.close();
      await controller2.close();
    });

    testWidgets('disposes subscription on dispose', (tester) async {
      final controller = StreamController<VideoFrame>.broadcast();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFrameWidget(
              frameStream: controller.stream,
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(),
          ),
        ),
      );

      // Should not throw when adding after dispose
      controller.add(VideoFrame(
        data: Uint8List.fromList([1, 2, 3]),
        width: 640,
        height: 480,
      ));

      await controller.close();
    });
  });

  group('StaticFrameWidget', () {
    testWidgets('shows placeholder when no frame data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaticFrameWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    });

    testWidgets('shows custom placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaticFrameWidget(
              placeholder: Text('No Video'),
            ),
          ),
        ),
      );

      expect(find.text('No Video'), findsOneWidget);
    });

    testWidgets('uses default BoxFit.contain', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaticFrameWidget(),
          ),
        ),
      );

      final widget = tester.widget<StaticFrameWidget>(
        find.byType(StaticFrameWidget),
      );
      expect(widget.fit, BoxFit.contain);
    });

    testWidgets('accepts custom BoxFit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StaticFrameWidget(
              fit: BoxFit.cover,
            ),
          ),
        ),
      );

      final widget = tester.widget<StaticFrameWidget>(
        find.byType(StaticFrameWidget),
      );
      expect(widget.fit, BoxFit.cover);
    });
  });
}
