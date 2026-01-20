import 'package:qr/qr.dart';

/// Test utility to generate QR codes with specific mask patterns
/// Use this to find which mask pattern matches the official app
class QrMaskTest {
  /// Generate QR data for all 8 mask patterns
  /// Returns a list of QrImage objects (one for each mask 0-7)
  static List<QrImage> generateAllMasks(String data, {int errorCorrectLevel = QrErrorCorrectLevel.L}) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: errorCorrectLevel,
    );

    final results = <QrImage>[];
    for (int mask = 0; mask <= 7; mask++) {
      results.add(QrImage.withMaskPattern(qrCode, mask));
    }
    return results;
  }

  /// Generate QR with a specific mask pattern
  static QrImage generateWithMask(String data, int maskPattern, {int errorCorrectLevel = QrErrorCorrectLevel.L}) {
    assert(maskPattern >= 0 && maskPattern <= 7);
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: errorCorrectLevel,
    );
    return QrImage.withMaskPattern(qrCode, maskPattern);
  }

  /// Print QR code to console (for debugging)
  static void printQr(QrImage qrImage) {
    final size = qrImage.moduleCount;
    for (int y = 0; y < size; y++) {
      final row = StringBuffer();
      for (int x = 0; x < size; x++) {
        row.write(qrImage.isDark(y, x) ? '██' : '  ');
      }
      print(row.toString());
    }
  }
}
