import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/widgets/manual_ip_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ManualIPDialog shows all fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => ManualIPDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Manual IP Entry'), findsOneWidget);
    expect(find.text('IP Address *'), findsOneWidget);
    expect(find.text('Port (optional)'), findsOneWidget);
    expect(find.text('Camera Name (optional)'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
  });

  testWidgets('Dialog validates IP before submission',
      (WidgetTester tester) async {
    DiscoveredDevice? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ManualIPDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(find.textContaining('required'), findsOneWidget);
    expect(result, isNull);
  });

  testWidgets('Dialog returns device on valid submission',
      (WidgetTester tester) async {
    DiscoveredDevice? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ManualIPDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '192.168.1.100');
    await tester.enterText(textFields.at(1), '8080');
    await tester.enterText(textFields.at(2), 'Test Camera');

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.ipAddress, '192.168.1.100');
    expect(result!.port, 8080);
    expect(result!.name, 'Test Camera');
    expect(result!.discoveryMethod, DiscoveryMethod.manual);
  });

  testWidgets('Cancel button closes dialog without result',
      (WidgetTester tester) async {
    DiscoveredDevice? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ManualIPDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, '192.168.1.100');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
    expect(find.text('Manual IP Entry'), findsNothing);
  });

  testWidgets('Dialog validates invalid port', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => ManualIPDialog.show(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '192.168.1.100');
    await tester.enterText(textFields.at(1), '99999');

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(find.textContaining('65535'), findsOneWidget);
  });

  testWidgets('Dialog uses default port 80 when empty',
      (WidgetTester tester) async {
    DiscoveredDevice? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ManualIPDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '192.168.1.100');

    final portField = textFields.at(1);
    await tester.enterText(portField, '');

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.port, 80);
  });

  testWidgets('Dialog default name when empty', (WidgetTester tester) async {
    DiscoveredDevice? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                result = await ManualIPDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), '192.168.1.100');

    await tester.tap(find.text('Connect'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.name, 'Camera at 192.168.1.100');
  });
}
