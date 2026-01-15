import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A widget that displays a QR code with optional styling
///
/// This widget is designed for displaying WiFi credential QR codes
/// that cameras can scan. It provides high contrast and appropriate
/// sizing for camera scanning.
class QRCodeDisplay extends StatelessWidget {
  /// The data to encode in the QR code
  final String data;

  /// Size of the QR code in pixels
  final double size;

  /// Background color of the QR code
  final Color backgroundColor;

  /// Foreground (dots) color of the QR code
  final Color foregroundColor;

  /// Error correction level for the QR code
  final int errorCorrectionLevel;

  /// Padding around the QR code
  final double padding;

  /// Whether to show a border around the QR code
  final bool showBorder;

  /// Border color if showBorder is true
  final Color borderColor;

  /// Border width if showBorder is true
  final double borderWidth;

  /// Border radius if showBorder is true
  final double borderRadius;

  const QRCodeDisplay({
    super.key,
    required this.data,
    this.size = 280,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.errorCorrectionLevel = QrErrorCorrectLevel.H,
    this.padding = 16,
    this.showBorder = true,
    this.borderColor = Colors.grey,
    this.borderWidth = 2,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    Widget qrWidget = Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
      ),
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        backgroundColor: backgroundColor,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: foregroundColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor,
        ),
        errorCorrectionLevel: errorCorrectionLevel,
        errorStateBuilder: (context, error) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Failed to generate QR code',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
          );
        },
      ),
    );

    return qrWidget;
  }
}

/// A high-contrast QR code optimized for camera scanning
class CameraScanQRCode extends StatelessWidget {
  /// The data to encode
  final String data;

  /// Optional network name to display below the QR code
  final String? networkName;

  /// Size of the QR code
  final double size;

  const CameraScanQRCode({
    super.key,
    required this.data,
    this.networkName,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        QRCodeDisplay(
          data: data,
          size: size,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          errorCorrectionLevel: QrErrorCorrectLevel.H, // High error correction
          showBorder: true,
          borderColor: Colors.grey.shade300,
          borderWidth: 3,
          borderRadius: 16,
          padding: 20,
        ),
        if (networkName != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi, size: 20, color: Colors.grey.shade700),
                const SizedBox(width: 8),
                Text(
                  networkName!,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
