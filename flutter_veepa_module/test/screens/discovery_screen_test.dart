import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/screens/discovery_screen.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    VeepaSDKManager().reset();
  });

  testWidgets('DiscoveryScreen shows app bar with title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryScreen()),
    );

    expect(find.text('Find Cameras'), findsOneWidget);
  });

  testWidgets('DiscoveryScreen shows refresh button in app bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryScreen()),
    );

    // Find refresh icon in app bar (there may be others elsewhere)
    expect(find.byIcon(Icons.refresh), findsWidgets);
  });

  testWidgets('DiscoveryScreen shows Manual IP FAB',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryScreen()),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Manual IP'), findsOneWidget);
  });

  testWidgets('Manual IP FAB opens dialog', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryScreen()),
    );

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Manual IP Entry'), findsOneWidget);
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('DiscoveryScreen shows error state when SDK not initialized',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryScreen()),
    );

    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(find.text('Discovery Error'), findsOneWidget);
    expect(find.text('SDK not initialized'), findsOneWidget);
  });

  testWidgets('Error state shows retry button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DiscoveryScreen()),
    );

    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(find.text('Retry'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
