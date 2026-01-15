import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/screens/qr_display_screen.dart';
import 'package:veepa_camera_poc/services/camera_config_service.dart';
import 'package:veepa_camera_poc/widgets/qr_code_display.dart';

/// Mock brightness controller for testing
class MockBrightnessController implements BrightnessController {
  bool maxBrightnessSet = false;
  bool brightnessRestored = false;

  @override
  Future<void> setMaxBrightness() async {
    maxBrightnessSet = true;
  }

  @override
  Future<void> restoreBrightness() async {
    brightnessRestored = true;
  }
}

void main() {
  late MockBrightnessController mockBrightnessController;

  setUp(() {
    mockBrightnessController = MockBrightnessController();
  });

  group('QRDisplayScreen', () {
    testWidgets('renders QR code with WiFi data', (tester) async {
      // Set a phone-like screen size
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.byType(CameraScanQRCode), findsOneWidget);
    });

    testWidgets('displays SSID in network name', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'MyHomeWiFi',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.text('MyHomeWiFi'), findsOneWidget);
    });

    testWidgets('displays instructions', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.text('Hold your phone up to the camera'), findsOneWidget);
      expect(
        find.text('Position the QR code in front of the camera lens'),
        findsOneWidget,
      );
    });

    testWidgets('displays info message about keeping steady', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(
        find.text('Keep steady until the camera confirms connection'),
        findsOneWidget,
      );
    });

    testWidgets('shows cancel button', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.text('Cancel Setup'), findsOneWidget);
    });

    testWidgets('calls onCancel when cancel button is pressed', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
            onCancel: () => cancelCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Cancel Setup'));
      await tester.pump();

      expect(cancelCalled, true);
    });

    testWidgets('shows confirm button when onConfirm is provided', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
            onConfirm: () {},
          ),
        ),
      );

      expect(find.text('Camera scanned it'), findsOneWidget);
    });

    testWidgets('hides confirm button when onConfirm is not provided', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.text('Camera scanned it'), findsNothing);
    });

    testWidgets('calls onConfirm when confirm button is pressed', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool confirmCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
            onConfirm: () => confirmCalled = true,
          ),
        ),
      );

      await tester.tap(find.text('Camera scanned it'));
      await tester.pump();

      expect(confirmCalled, true);
    });

    testWidgets('sets max brightness on init', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      // Allow async operations to complete
      await tester.pumpAndSettle();

      expect(mockBrightnessController.maxBrightnessSet, true);
    });

    testWidgets('restores brightness on dispose', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away to trigger dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pumpAndSettle();

      expect(mockBrightnessController.brightnessRestored, true);
    });

    testWidgets('shows app bar with WiFi Setup title', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.text('WiFi Setup'), findsOneWidget);
    });

    testWidgets('back button calls onCancel', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
            onCancel: () => cancelCalled = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(cancelCalled, true);
    });

    testWidgets('uses standard WiFi format by default', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.byType(CameraScanQRCode), findsOneWidget);
    });

    testWidgets('can use Veepa format', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            useVeepaFormat: true,
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.byType(CameraScanQRCode), findsOneWidget);
    });

    testWidgets('handles different encryption types', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final encryption in WifiEncryption.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: QRDisplayScreen(
              ssid: 'TestNetwork',
              password: encryption == WifiEncryption.none ? '' : 'password123',
              encryption: encryption,
              brightnessController: mockBrightnessController,
            ),
          ),
        );

        expect(find.byType(CameraScanQRCode), findsOneWidget);
      }
    });

    testWidgets('shows error state for invalid credentials', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: '', // Invalid empty SSID
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      expect(find.text('Failed to generate QR code'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('calls onTimeout after specified duration', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool timeoutCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
            autoTimeout: const Duration(milliseconds: 100),
            onTimeout: () => timeoutCalled = true,
          ),
        ),
      );

      expect(timeoutCalled, false);

      // Wait for timeout
      await tester.pump(const Duration(milliseconds: 150));

      expect(timeoutCalled, true);
    });

    testWidgets('uses white background for high contrast', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: QRDisplayScreen(
            ssid: 'TestNetwork',
            password: 'password123',
            brightnessController: mockBrightnessController,
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);
    });
  });
}
