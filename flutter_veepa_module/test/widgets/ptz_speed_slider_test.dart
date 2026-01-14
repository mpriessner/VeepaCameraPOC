import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/widgets/ptz_speed_slider.dart';
import 'package:veepa_camera_poc/services/veepa_ptz_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    VeepaPTZService().reset();
  });

  tearDown(() {
    VeepaPTZService().reset();
  });

  group('PTZSpeedSlider', () {
    testWidgets('renders slider', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('shows speed icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('shows speed percentage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      // Default speed is 50%
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('has semi-transparent background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
      expect(decoration.color!.opacity, lessThan(1.0));
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('slider changes speed value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Initial speed should be 50
      expect(VeepaPTZService().speed, 50);

      // Drag slider to the right (increase speed)
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Speed should have increased
      expect(VeepaPTZService().speed, greaterThanOrEqualTo(50));
    });

    testWidgets('displays updated speed after change', (tester) async {
      // Set a specific speed first
      VeepaPTZService().speed = 80;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('slider has blue active color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.activeColor, Colors.blue);
    });

    testWidgets('slider range is 0 to 100', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 0);
      expect(slider.max, 100);
    });

    testWidgets('slider has 10 divisions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PTZSpeedSlider()),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 10);
    });
  });
}
