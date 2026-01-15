import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:veepa_camera_poc/widgets/qr_code_display.dart';

void main() {
  group('QRCodeDisplay', () {
    testWidgets('renders QR code with provided data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(data: 'test-data'),
          ),
        ),
      );

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(data: 'test-data', size: 200),
          ),
        ),
      );

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.size, 200);
    });

    testWidgets('applies custom background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(
              data: 'test-data',
              backgroundColor: Colors.yellow,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(QrImageView),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.yellow);
    });

    testWidgets('shows border when showBorder is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(
              data: 'test-data',
              showBorder: true,
              borderColor: Colors.red,
              borderWidth: 5,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(QrImageView),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
    });

    testWidgets('hides border when showBorder is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(
              data: 'test-data',
              showBorder: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(QrImageView),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull);
    });

    testWidgets('applies border radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(
              data: 'test-data',
              borderRadius: 24,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(QrImageView),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(24));
    });

    testWidgets('applies padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(
              data: 'test-data',
              padding: 32,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.ancestor(
          of: find.byType(QrImageView),
          matching: find.byType(Container),
        ).first,
      );
      expect(container.padding, const EdgeInsets.all(32));
    });

    testWidgets('uses high error correction by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QRCodeDisplay(data: 'test-data'),
          ),
        ),
      );

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.errorCorrectionLevel, QrErrorCorrectLevel.H);
    });
  });

  group('CameraScanQRCode', () {
    testWidgets('renders QRCodeDisplay', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CameraScanQRCode(data: 'test-data'),
          ),
        ),
      );

      expect(find.byType(QRCodeDisplay), findsOneWidget);
    });

    testWidgets('displays network name when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CameraScanQRCode(
              data: 'test-data',
              networkName: 'MyNetwork',
            ),
          ),
        ),
      );

      expect(find.text('MyNetwork'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('hides network name when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CameraScanQRCode(data: 'test-data'),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi), findsNothing);
    });

    testWidgets('applies custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CameraScanQRCode(data: 'test-data', size: 300),
          ),
        ),
      );

      final qrDisplay = tester.widget<QRCodeDisplay>(find.byType(QRCodeDisplay));
      expect(qrDisplay.size, 300);
    });

    testWidgets('uses high contrast colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CameraScanQRCode(data: 'test-data'),
          ),
        ),
      );

      final qrDisplay = tester.widget<QRCodeDisplay>(find.byType(QRCodeDisplay));
      expect(qrDisplay.backgroundColor, Colors.white);
      expect(qrDisplay.foregroundColor, Colors.black);
    });
  });
}
