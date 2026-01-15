import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/screens/visual_provisioning_wizard.dart';
import 'package:veepa_camera_poc/utils/qr_code_parser.dart';
import 'package:veepa_camera_poc/widgets/provisioning_step_indicator.dart';

void main() {
  group('VisualProvisioningWizard', () {
    Future<void> pumpWizard(
      WidgetTester tester, {
      VeepaQRData? initialDevice,
      VoidCallback? onComplete,
      VoidCallback? onCancel,
    }) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: VisualProvisioningWizard(
            initialDevice: initialDevice,
            onComplete: onComplete,
            onCancel: onCancel,
          ),
        ),
      );
    }

    testWidgets('shows scan step by default', (tester) async {
      await pumpWizard(tester);

      expect(find.text('Scan Camera QR Code'), findsOneWidget);
      expect(find.text('Start Scanning'), findsOneWidget);
    });

    testWidgets('shows step indicator', (tester) async {
      await pumpWizard(tester);

      expect(find.byType(ProvisioningStepIndicator), findsOneWidget);
    });

    testWidgets('shows Camera Setup title in app bar', (tester) async {
      await pumpWizard(tester);

      expect(find.text('Camera Setup'), findsOneWidget);
    });

    testWidgets('has close button', (tester) async {
      await pumpWizard(tester);

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onCancel when close button is pressed', (tester) async {
      bool cancelCalled = false;

      await pumpWizard(
        tester,
        onCancel: () => cancelCalled = true,
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(cancelCalled, true);
    });

    testWidgets('starts at connect step when initialDevice is provided',
        (tester) async {
      final device = VeepaQRData(
        deviceId: 'TEST123',
        password: 'password',
      );

      await pumpWizard(tester, initialDevice: device);

      expect(find.text('Connect to Camera WiFi'), findsOneWidget);
    });

    testWidgets('shows camera device ID in connect step', (tester) async {
      final device = VeepaQRData(
        deviceId: 'ABC123',
        password: 'password',
      );

      await pumpWizard(tester, initialDevice: device);

      expect(find.textContaining('ABC123'), findsOneWidget);
    });

    testWidgets('has open wifi settings button in connect step',
        (tester) async {
      final device = VeepaQRData(
        deviceId: 'TEST123',
        password: 'password',
      );

      await pumpWizard(tester, initialDevice: device);

      expect(find.text('Open WiFi Settings'), findsOneWidget);
    });

    testWidgets('has I\'m Connected button in connect step', (tester) async {
      final device = VeepaQRData(
        deviceId: 'TEST123',
        password: 'password',
      );

      await pumpWizard(tester, initialDevice: device);

      expect(find.text("I'm Connected"), findsOneWidget);
    });
  });

  group('ProvisioningStepIndicator', () {
    testWidgets('shows 5 step dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProvisioningStepIndicator(
              currentStep: ProvisioningStep.scanCamera,
            ),
          ),
        ),
      );

      // Count Container widgets that represent step dots
      final dots = tester.widgetList(find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration) {
            return decoration.shape == BoxShape.circle;
          }
        }
        return false;
      }));

      expect(dots.length, 5);
    });

    testWidgets('hides for success step', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProvisioningStepIndicator(
              currentStep: ProvisioningStep.success,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('hides for failure step', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProvisioningStepIndicator(
              currentStep: ProvisioningStep.failure,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('CompactStepIndicator', () {
    testWidgets('shows current step number', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactStepIndicator(
              currentStep: ProvisioningStep.enterWifiCreds,
            ),
          ),
        ),
      );

      expect(find.text('Step 3 of 5'), findsOneWidget);
    });

    testWidgets('hides for success step', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactStepIndicator(
              currentStep: ProvisioningStep.success,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    });
  });

  group('ProvisioningStep', () {
    test('displayName returns correct values', () {
      expect(ProvisioningStep.scanCamera.displayName, 'Scan');
      expect(ProvisioningStep.connectToAP.displayName, 'Connect');
      expect(ProvisioningStep.enterWifiCreds.displayName, 'WiFi');
      expect(ProvisioningStep.showQR.displayName, 'QR Code');
      expect(ProvisioningStep.detecting.displayName, 'Detect');
      expect(ProvisioningStep.success.displayName, 'Done');
      expect(ProvisioningStep.failure.displayName, 'Error');
    });

    test('stepNumber returns correct values', () {
      expect(ProvisioningStep.scanCamera.stepNumber, 1);
      expect(ProvisioningStep.connectToAP.stepNumber, 2);
      expect(ProvisioningStep.enterWifiCreds.stepNumber, 3);
      expect(ProvisioningStep.showQR.stepNumber, 4);
      expect(ProvisioningStep.detecting.stepNumber, 5);
      expect(ProvisioningStep.success.stepNumber, 6);
      expect(ProvisioningStep.failure.stepNumber, 0);
    });

    test('isProgressStep returns correct values', () {
      expect(ProvisioningStep.scanCamera.isProgressStep, true);
      expect(ProvisioningStep.connectToAP.isProgressStep, true);
      expect(ProvisioningStep.enterWifiCreds.isProgressStep, true);
      expect(ProvisioningStep.showQR.isProgressStep, true);
      expect(ProvisioningStep.detecting.isProgressStep, true);
      expect(ProvisioningStep.success.isProgressStep, false);
      expect(ProvisioningStep.failure.isProgressStep, false);
    });
  });

  group('QRDisplayScreenContent', () {
    testWidgets('displays QR code with data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRDisplayScreenContent(
              qrData: 'WIFI:T:WPA;S:TestNetwork;P:password;;',
              ssid: 'TestNetwork',
            ),
          ),
        ),
      );

      expect(find.text('TestNetwork'), findsOneWidget);
    });

    testWidgets('uses provided size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRDisplayScreenContent(
              qrData: 'test',
              ssid: 'Test',
              size: 300,
            ),
          ),
        ),
      );

      // Widget should be created with the size
      expect(find.byType(QRDisplayScreenContent), findsOneWidget);
    });
  });
}
