import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/widgets/wifi_credentials_form.dart';
import 'package:veepa_camera_poc/services/camera_config_service.dart';

void main() {
  group('WifiCredentials', () {
    test('creates with required fields', () {
      final creds = WifiCredentials(
        ssid: 'TestNetwork',
        password: 'password123',
        encryption: WifiEncryption.wpa2,
      );

      expect(creds.ssid, equals('TestNetwork'));
      expect(creds.password, equals('password123'));
      expect(creds.encryption, equals(WifiEncryption.wpa2));
    });

    test('toString does not include password', () {
      final creds = WifiCredentials(
        ssid: 'TestNetwork',
        password: 'secret123',
        encryption: WifiEncryption.wpa2,
      );

      final str = creds.toString();
      expect(str, contains('TestNetwork'));
      expect(str, contains('wpa2'));
      expect(str, isNot(contains('secret123')));
    });
  });

  group('WifiCredentialsForm', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(),
          ),
        ),
      );

      expect(find.text('WiFi Network Name (SSID)'), findsOneWidget);
      expect(find.text('WiFi Password'), findsOneWidget);
      expect(find.text('Security Type'), findsOneWidget);
      expect(find.text('Configure'), findsOneWidget);
    });

    testWidgets('shows initial SSID', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              initialSSID: 'PrefilledNetwork',
            ),
          ),
        ),
      );

      expect(find.text('PrefilledNetwork'), findsOneWidget);
    });

    testWidgets('shows cancel button when onCancel provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              onCancel: () {},
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('does not show cancel button when onCancel is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(),
          ),
        ),
      );

      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('validates empty SSID', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              onSubmit: (_) {},
            ),
          ),
        ),
      );

      // Tap configure without entering SSID
      await tester.tap(find.text('Configure'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the network name'), findsOneWidget);
    });

    testWidgets('validates empty password for secured networks', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              onSubmit: (_) {},
            ),
          ),
        ),
      );

      // Enter SSID but not password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'WiFi Network Name (SSID)'),
        'TestNetwork',
      );
      await tester.tap(find.text('Configure'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter the password'), findsOneWidget);
    });

    testWidgets('validates short password', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              onSubmit: (_) {},
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'WiFi Network Name (SSID)'),
        'TestNetwork',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'WiFi Password'),
        'short',
      );
      await tester.tap(find.text('Configure'));
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('calls onSubmit with valid credentials', (tester) async {
      WifiCredentials? receivedCreds;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              onSubmit: (creds) => receivedCreds = creds,
            ),
          ),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'WiFi Network Name (SSID)'),
        'TestNetwork',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'WiFi Password'),
        'password123',
      );
      await tester.tap(find.text('Configure'));
      await tester.pumpAndSettle();

      expect(receivedCreds, isNotNull);
      expect(receivedCreds!.ssid, equals('TestNetwork'));
      expect(receivedCreds!.password, equals('password123'));
      expect(receivedCreds!.encryption, equals(WifiEncryption.wpa2));
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables fields when loading', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(
              isLoading: true,
            ),
          ),
        ),
      );

      final ssidField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'WiFi Network Name (SSID)'),
      );
      expect(ssidField.enabled, isFalse);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WifiCredentialsForm(),
          ),
        ),
      );

      // Initially password is obscured (visibility_off icon shown)
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsNothing);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      // Password should now be visible (visibility icon shown)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });
  });
}
