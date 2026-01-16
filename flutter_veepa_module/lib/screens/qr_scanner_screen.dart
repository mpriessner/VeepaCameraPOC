import 'package:flutter/material.dart';
import '../utils/qr_code_parser.dart';

/// Screen for scanning QR codes from Veepa cameras
/// NOTE: Temporarily disabled - mobile_scanner plugin removed for simpler build
class QRScannerScreen extends StatelessWidget {
  final void Function(VeepaQRData data)? onScanComplete;

  const QRScannerScreen({
    super.key,
    this.onScanComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Scanner'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'QR Scanner temporarily disabled',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Use Manual IP Entry instead to connect to your camera.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
