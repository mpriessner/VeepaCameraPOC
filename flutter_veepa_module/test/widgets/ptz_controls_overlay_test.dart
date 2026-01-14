import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/ptz_direction.dart';
import 'package:veepa_camera_poc/widgets/ptz_controls_overlay.dart';
import 'package:veepa_camera_poc/services/veepa_ptz_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    VeepaPTZService().reset();
  });

  tearDown(() {
    VeepaPTZService().reset();
  });

  group('PTZControlsOverlay', () {
    testWidgets('shows all direction buttons when visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PTZControlsOverlay(visible: true),
              ],
            ),
          ),
        ),
      );

      // Cardinal directions
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_left), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
    });

    testWidgets('shows diagonal buttons when visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PTZControlsOverlay(visible: true),
              ],
            ),
          ),
        ),
      );

      // Diagonal directions
      expect(find.byIcon(Icons.north_west), findsOneWidget);
      expect(find.byIcon(Icons.north_east), findsOneWidget);
      expect(find.byIcon(Icons.south_west), findsOneWidget);
      expect(find.byIcon(Icons.south_east), findsOneWidget);
    });

    testWidgets('shows zoom buttons when visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PTZControlsOverlay(visible: true),
              ],
            ),
          ),
        ),
      );

      // Zoom buttons
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
    });

    testWidgets('shows ZOOM label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PTZControlsOverlay(visible: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('ZOOM'), findsOneWidget);
    });

    testWidgets('hidden when visible is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PTZControlsOverlay(visible: false),
              ],
            ),
          ),
        ),
      );

      // Nothing should be visible
      expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.text('ZOOM'), findsNothing);
    });

    testWidgets('returns SizedBox.shrink when not visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PTZControlsOverlay(visible: false),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('PTZButton', () {
    testWidgets('renders with correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PTZButton(
              icon: Icons.arrow_upward,
              direction: PTZDirection.tiltUp,
              ptzService: VeepaPTZService(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('has circular shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PTZButton(
              icon: Icons.arrow_upward,
              direction: PTZDirection.tiltUp,
              ptzService: VeepaPTZService(),
            ),
          ),
        ),
      );

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('responds to tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PTZButton(
              icon: Icons.arrow_upward,
              direction: PTZDirection.tiltUp,
              ptzService: VeepaPTZService(),
            ),
          ),
        ),
      );

      // Should not throw when tapped
      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
    });
  });

  group('ZoomButton', () {
    testWidgets('renders with correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomButton(
              icon: Icons.add,
              zoomDirection: ZoomDirection.zoomIn,
              ptzService: VeepaPTZService(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('has blue background color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomButton(
              icon: Icons.add,
              zoomDirection: ZoomDirection.zoomIn,
              ptzService: VeepaPTZService(),
            ),
          ),
        ),
      );

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = animatedContainer.decoration as BoxDecoration;
      expect(decoration.color, isA<Color>());
      // Blue with some opacity
      expect(decoration.color!.blue, greaterThan(100));
    });

    testWidgets('responds to tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomButton(
              icon: Icons.add,
              zoomDirection: ZoomDirection.zoomIn,
              ptzService: VeepaPTZService(),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
    });
  });
}
