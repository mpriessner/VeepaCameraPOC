import 'package:flutter/material.dart';
import 'package:qr/qr.dart';

/// Custom QR code widget that supports specific mask patterns
/// This is needed because qr_flutter doesn't expose mask pattern control
class MaskedQrWidget extends StatelessWidget {
  final String data;
  final int typeNumber;
  final int? maskPattern;
  final int errorCorrectLevel;
  final double size;
  final Color foregroundColor;
  final Color backgroundColor;

  const MaskedQrWidget({
    super.key,
    required this.data,
    required this.typeNumber,
    this.maskPattern,
    this.errorCorrectLevel = QrErrorCorrectLevel.L,
    this.size = 300,
    this.foregroundColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final qrCode = QrCode(typeNumber, errorCorrectLevel);
      qrCode.addData(data);

      final QrImage qrImage;
      if (maskPattern != null) {
        qrImage = QrImage.withMaskPattern(qrCode, maskPattern!);
      } else {
        qrImage = QrImage(qrCode);
      }

      return CustomPaint(
        painter: _QrPainter(
          qrImage: qrImage,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
        ),
        size: Size(size, size),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: Center(
          child: Text(
            'QR Error: $e',
            style: TextStyle(color: foregroundColor, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
  }
}

class _QrPainter extends CustomPainter {
  final QrImage qrImage;
  final Color foregroundColor;
  final Color backgroundColor;

  _QrPainter({
    required this.qrImage,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final moduleCount = qrImage.moduleCount;
    final moduleSize = size.width / moduleCount;

    final darkPaint = Paint()..color = foregroundColor;
    final lightPaint = Paint()..color = backgroundColor;

    // Fill background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), lightPaint);

    // Draw modules
    for (int y = 0; y < moduleCount; y++) {
      for (int x = 0; x < moduleCount; x++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(x * moduleSize, y * moduleSize, moduleSize, moduleSize),
            darkPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) {
    return oldDelegate.qrImage != qrImage ||
        oldDelegate.foregroundColor != foregroundColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
