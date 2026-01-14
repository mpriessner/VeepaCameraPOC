import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/widgets/empty_discovery_view.dart';

void main() {
  testWidgets('EmptyDiscoveryView displays all elements',
      (WidgetTester tester) async {
    bool retryTapped = false;
    bool manualTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyDiscoveryView(
            onRetry: () => retryTapped = true,
            onManualEntry: () => manualTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No Cameras Found'), findsOneWidget);
    expect(find.byIcon(Icons.videocam_off), findsOneWidget);
    expect(find.text('Scan Again'), findsOneWidget);
    expect(find.text('Enter IP'), findsOneWidget);
    expect(find.textContaining('Powered on'), findsOneWidget);
    expect(find.textContaining('WiFi network'), findsOneWidget);
  });

  testWidgets('EmptyDiscoveryView retry button works',
      (WidgetTester tester) async {
    bool retryTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyDiscoveryView(
            onRetry: () => retryTapped = true,
            onManualEntry: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Scan Again'));
    expect(retryTapped, isTrue);
  });

  testWidgets('EmptyDiscoveryView manual entry button works',
      (WidgetTester tester) async {
    bool manualTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyDiscoveryView(
            onRetry: () {},
            onManualEntry: () => manualTapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Enter IP'));
    expect(manualTapped, isTrue);
  });
}
