import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:veepa_camera_poc/services/wifi_qr_generator_service.dart';
import 'package:veepa_camera_poc/services/camera_config_service.dart';
import 'package:veepa_camera_poc/widgets/qr_code_display.dart';

/// Screen brightness controller abstraction for testability
abstract class BrightnessController {
  Future<void> setMaxBrightness();
  Future<void> restoreBrightness();
}

/// Default brightness controller that sets system brightness to maximum
class SystemBrightnessController implements BrightnessController {
  double? _previousBrightness;

  @override
  Future<void> setMaxBrightness() async {
    // On iOS, we can only suggest brightness through system chrome
    // For a real implementation, use screen_brightness package
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  Future<void> restoreBrightness() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
}

/// Screen that displays a QR code containing WiFi credentials
/// for the camera to scan
class QRDisplayScreen extends StatefulWidget {
  /// SSID of the WiFi network
  final String ssid;

  /// Password of the WiFi network
  final String password;

  /// Encryption type of the network
  final WifiEncryption encryption;

  /// Called when the user cancels
  final VoidCallback? onCancel;

  /// Called when timeout is reached (if autoTimeout is enabled)
  final VoidCallback? onTimeout;

  /// Called when user taps "Camera scanned it" button
  final VoidCallback? onConfirm;

  /// Whether to use Veepa-specific QR format instead of standard WiFi format
  final bool useVeepaFormat;

  /// Optional brightness controller for testing
  final BrightnessController? brightnessController;

  /// Auto timeout duration (null to disable)
  final Duration? autoTimeout;

  const QRDisplayScreen({
    super.key,
    required this.ssid,
    required this.password,
    this.encryption = WifiEncryption.wpa2,
    this.onCancel,
    this.onTimeout,
    this.onConfirm,
    this.useVeepaFormat = false,
    this.brightnessController,
    this.autoTimeout,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  late final WifiQRGeneratorService _qrGenerator;
  late final BrightnessController _brightnessController;
  String? _qrData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _qrGenerator = WifiQRGeneratorService();
    _brightnessController =
        widget.brightnessController ?? SystemBrightnessController();
    _generateQRCode();
    _setBrightness();
    _startTimeoutIfNeeded();
  }

  @override
  void dispose() {
    _restoreBrightness();
    super.dispose();
  }

  void _generateQRCode() {
    try {
      if (widget.useVeepaFormat) {
        _qrData = _qrGenerator.generateVeepaQRData(
          ssid: widget.ssid,
          password: widget.password,
          encryption: widget.encryption,
        );
      } else {
        _qrData = _qrGenerator.generateWifiQRData(
          ssid: widget.ssid,
          password: widget.password,
          encryption: widget.encryption,
        );
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> _setBrightness() async {
    try {
      await _brightnessController.setMaxBrightness();
    } catch (e) {
      // Brightness control may not be available on all platforms
      debugPrint('Could not set brightness: $e');
    }
  }

  Future<void> _restoreBrightness() async {
    try {
      await _brightnessController.restoreBrightness();
    } catch (e) {
      debugPrint('Could not restore brightness: $e');
    }
  }

  void _startTimeoutIfNeeded() {
    if (widget.autoTimeout != null) {
      Future.delayed(widget.autoTimeout!, () {
        if (mounted) {
          widget.onTimeout?.call();
        }
      });
    }
  }

  void _handleCancel() {
    widget.onCancel?.call();
    if (widget.onCancel == null) {
      Navigator.of(context).pop();
    }
  }

  void _handleConfirm() {
    widget.onConfirm?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('WiFi Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleCancel,
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Instructions
              Text(
                'Hold your phone up to the camera',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Position the QR code in front of the camera lens',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // QR Code
              Expanded(
                child: Center(
                  child: _buildQRContent(),
                ),
              ),

              const SizedBox(height: 24),

              // Bottom instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keep steady until the camera confirms connection',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Buttons
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRContent() {
    if (_error != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Failed to generate QR code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (_qrData == null) {
      return const CircularProgressIndicator();
    }

    return CameraScanQRCode(
      data: _qrData!,
      networkName: widget.ssid,
      size: 260,
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        if (widget.onConfirm != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleConfirm,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Camera scanned it'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (widget.onConfirm != null) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleCancel,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel Setup'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
