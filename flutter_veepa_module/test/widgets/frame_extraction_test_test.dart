import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/widgets/frame_extraction_test.dart';
import 'package:veepa_camera_poc/services/frame_extraction_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FrameExtractionService().reset();
  });

  tearDown(() {
    FrameExtractionService().reset();
  });

  group('FrameExtractionTest Widget', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('Frame Extraction Test'), findsOneWidget);
    });

    testWidgets('shows texture ID', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 42),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('has start button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('has stop button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('has PNG button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('PNG'), findsOneWidget);
    });

    testWidgets('shows IDLE status initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('IDLE'), findsOneWidget);
    });

    testWidgets('shows initial frame count of 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('shows logs section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('Logs'), findsOneWidget);
    });

    testWidgets('start button exists and can be tapped', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FrameExtractionTest(textureId: 1),
            ),
          ),
        );

        // Start button text exists
        expect(find.text('Start'), findsOneWidget);

        // Button should be tappable (not throw) initially
        await tester.tap(find.text('Start'));
        await tester.pump();

        // Clean up
        FrameExtractionService().stopExtraction();
      });
    });

    testWidgets('stop button exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      // Stop button text exists
      expect(find.text('Stop'), findsOneWidget);
    });

    testWidgets('PNG button exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      // PNG button text exists
      expect(find.text('PNG'), findsOneWidget);
    });

    testWidgets('tapping start changes status', (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: FrameExtractionTest(textureId: 1),
            ),
          ),
        );

        expect(find.text('IDLE'), findsOneWidget);

        await tester.tap(find.text('Start'));
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 100));
        await tester.pump();

        // Should show ACTIVE after starting
        expect(find.text('ACTIVE'), findsOneWidget);

        // Clean up
        FrameExtractionService().stopExtraction();
      });
    });

    testWidgets('displays stats labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.text('Status: '), findsOneWidget);
      expect(find.text('Texture ID: '), findsOneWidget);
      expect(find.text('Frames: '), findsOneWidget);
      expect(find.text('FPS: '), findsOneWidget);
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.color, equals(Colors.black87));
    });

    testWidgets('has camera icon in header', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FrameExtractionTest(textureId: 1),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera), findsOneWidget);
    });
  });
}
