import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_scanner_service.dart';
import '../utils/qr_code_parser.dart';
import '../widgets/scan_overlay.dart';

/// Screen for scanning QR codes from Veepa cameras
class QRScannerScreen extends StatefulWidget {
  final void Function(VeepaQRData data)? onScanComplete;

  const QRScannerScreen({
    super.key,
    this.onScanComplete,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final QRScannerService _scannerService = QRScannerService();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scannerService.startScanning();
  }

  @override
  void dispose() {
    _scannerService.stopScanning();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      // Check if it looks like a Veepa QR code
      if (!QRCodeParser.isVeepaQRCode(rawValue)) continue;

      setState(() => _isProcessing = true);

      final result = _scannerService.processQRCode(rawValue);

      if (result.isSuccess && result.parsedData != null) {
        // Haptic feedback
        HapticFeedback.mediumImpact();

        // Notify caller and close
        if (widget.onScanComplete != null) {
          widget.onScanComplete!(result.parsedData!);
        }
        Navigator.of(context).pop(result.parsedData);
      } else {
        // Show error briefly
        setState(() {
          _errorMessage = result.error;
          _isProcessing = false;
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() => _errorMessage = null);
          }
        });
      }
      break;
    }
  }

  void _toggleTorch() {
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan overlay
          const ScanOverlay(
            instructionText: 'Point camera at the QR code on your Veepa camera',
          ),

          // Top bar with controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Torch toggle
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      return IconButton(
                        onPressed: _toggleTorch,
                        icon: Icon(
                          state.torchState == TorchState.on
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: Colors.white,
                          size: 28,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          // Processing indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
