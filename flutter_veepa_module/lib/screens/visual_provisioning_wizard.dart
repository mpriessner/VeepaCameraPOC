import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:veepa_camera_poc/screens/qr_scanner_screen.dart';
import 'package:veepa_camera_poc/services/camera_config_service.dart';
import 'package:veepa_camera_poc/services/camera_connection_detector.dart';
import 'package:veepa_camera_poc/services/wifi_discovery_service.dart';
import 'package:veepa_camera_poc/services/wifi_qr_generator_service.dart';
import 'package:veepa_camera_poc/utils/qr_code_parser.dart';
import 'package:veepa_camera_poc/widgets/detection_progress_indicator.dart';
import 'package:veepa_camera_poc/widgets/provisioning_step_indicator.dart';
import 'package:veepa_camera_poc/widgets/qr_code_display.dart';

/// Wizard for visual WiFi provisioning using QR codes
class VisualProvisioningWizard extends StatefulWidget {
  /// If already scanned, pass the device data
  final VeepaQRData? initialDevice;

  /// Called when provisioning completes successfully
  final VoidCallback? onComplete;

  /// Called when user cancels
  final VoidCallback? onCancel;

  const VisualProvisioningWizard({
    super.key,
    this.initialDevice,
    this.onComplete,
    this.onCancel,
  });

  @override
  State<VisualProvisioningWizard> createState() =>
      _VisualProvisioningWizardState();
}

class _VisualProvisioningWizardState extends State<VisualProvisioningWizard> {
  ProvisioningStep _currentStep = ProvisioningStep.scanCamera;
  VeepaQRData? _deviceData;
  String? _selectedSSID;
  String _wifiPassword = '';
  String? _errorMessage;

  final _qrGenerator = WifiQRGeneratorService();
  final _connectionDetector = CameraConnectionDetector();
  final _wifiDiscovery = WifiDiscoveryService();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    _wifiDiscovery.startMonitoring();

    if (widget.initialDevice != null) {
      _deviceData = widget.initialDevice;
      _currentStep = ProvisioningStep.connectToAP;
    }
  }

  @override
  void dispose() {
    _connectionDetector.dispose();
    _wifiDiscovery.stopMonitoring();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToStep(ProvisioningStep step) {
    setState(() {
      _currentStep = step;
      _errorMessage = null;
    });
  }

  void _handleCancel() {
    if (_currentStep == ProvisioningStep.detecting) {
      _connectionDetector.cancelDetection();
    }
    widget.onCancel?.call();
    Navigator.of(context).pop();
  }

  Future<void> _handleScanComplete(VeepaQRData data) async {
    setState(() {
      _deviceData = data;
    });
    _goToStep(ProvisioningStep.connectToAP);
  }

  void _openWifiSettings() async {
    // On iOS, we can open the WiFi settings
    // Note: This opens the main settings app - iOS doesn't allow deep linking to WiFi settings directly
    const settingsUrl = 'App-Prefs:root=WIFI';
    if (await canLaunchUrl(Uri.parse(settingsUrl))) {
      await launchUrl(Uri.parse(settingsUrl));
    } else {
      // Fallback for Android or when URL scheme isn't available
      final generalSettings = Uri.parse('app-settings:');
      if (await canLaunchUrl(generalSettings)) {
        await launchUrl(generalSettings);
      }
    }
  }

  Future<void> _checkAPConnection() async {
    setState(() => _isCheckingConnection = true);

    // Wait a moment for WiFi to settle
    await Future.delayed(const Duration(seconds: 1));

    await _wifiDiscovery.refresh();

    setState(() => _isCheckingConnection = false);

    if (_wifiDiscovery.isConnectedToVeepaAP) {
      _goToStep(ProvisioningStep.enterWifiCreds);
    } else {
      setState(() {
        _errorMessage =
            'Not connected to camera WiFi. Please connect to a network starting with "VEEPA_" or "VSTC_"';
      });
    }
  }

  void _generateQR() {
    if (_formKey.currentState?.validate() ?? false) {
      _selectedSSID = _ssidController.text.trim();
      _wifiPassword = _passwordController.text;
      _goToStep(ProvisioningStep.showQR);
    }
  }

  void _startDetection() async {
    if (_deviceData == null || _selectedSSID == null) return;

    _goToStep(ProvisioningStep.detecting);

    final result = await _connectionDetector.startDetection(
      deviceId: _deviceData!.deviceId,
      password: _deviceData!.password,
      timeout: const Duration(seconds: 90),
      pollInterval: const Duration(seconds: 3),
    );

    if (!mounted) return;

    if (result.success) {
      _goToStep(ProvisioningStep.success);
    } else if (result.errorMessage == 'Detection cancelled') {
      // User cancelled, stay on current step or go back
      _goToStep(ProvisioningStep.showQR);
    } else {
      // Timeout or error
      setState(() {
        _currentStep = ProvisioningStep.failure;
        _errorMessage = result.errorMessage ?? 'Failed to detect camera';
      });
    }
  }

  Future<void> _fallbackToCGI() async {
    if (_selectedSSID == null) return;

    setState(() {
      _errorMessage = null;
      _isCheckingConnection = true;
    });

    try {
      final configService = CameraConfigServiceFactory.forAPMode();
      final result = await configService.setWifiConfig(
        ssid: _selectedSSID!,
        password: _wifiPassword,
        encryption: WifiEncryption.wpa2,
      );

      if (result.success) {
        _startDetection();
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Failed to configure WiFi via CGI';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'CGI method failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isCheckingConnection = false);
      }
    }
  }

  void _retry() {
    _connectionDetector.reset();
    _goToStep(ProvisioningStep.showQR);
  }

  void _complete() {
    widget.onComplete?.call();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Setup'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _handleCancel,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: ProvisioningStepIndicator(currentStep: _currentStep),
        ),
      ),
      body: SafeArea(
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case ProvisioningStep.scanCamera:
        return _buildScanStep();
      case ProvisioningStep.connectToAP:
        return _buildConnectAPStep();
      case ProvisioningStep.enterWifiCreds:
        return _buildWifiCredsStep();
      case ProvisioningStep.showQR:
        return _buildShowQRStep();
      case ProvisioningStep.detecting:
        return _buildDetectingStep();
      case ProvisioningStep.success:
        return _buildSuccessStep();
      case ProvisioningStep.failure:
        return _buildFailureStep();
    }
  }

  Widget _buildScanStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 32),
          Text(
            'Scan Camera QR Code',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Scan the QR code on your Veepa camera to begin setup',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push<VeepaQRData>(
                context,
                MaterialPageRoute(
                  builder: (_) => const QRScannerScreen(),
                ),
              );
              if (result != null) {
                _handleScanComplete(result);
              }
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectAPStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(
            Icons.wifi_tethering,
            size: 80,
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            'Connect to Camera WiFi',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Open your device settings and connect to:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'VEEPA_${_deviceData?.deviceId ?? '...'}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _openWifiSettings,
            icon: const Icon(Icons.settings),
            label: const Text('Open WiFi Settings'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isCheckingConnection ? null : _checkAPConnection,
            icon: _isCheckingConnection
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text("I'm Connected"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _handleCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiCredsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Home WiFi',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the credentials for your home WiFi network',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _ssidController,
              decoration: const InputDecoration(
                labelText: 'Network Name (SSID)',
                prefixIcon: Icon(Icons.wifi),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the network name';
                }
                if (value.length > 32) {
                  return 'Network name is too long (max 32 characters)';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                return null;
              },
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _generateQR,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR Code'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _goToStep(ProvisioningStep.connectToAP),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowQRStep() {
    final qrData = _qrGenerator.generateWifiQRData(
      ssid: _selectedSSID ?? '',
      password: _wifiPassword,
    );

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Show QR to Camera',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hold your phone up to the camera lens',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QRDisplayScreenContent(
                    qrData: qrData,
                    ssid: _selectedSSID ?? '',
                    size: 200,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep steady until the camera beeps or indicates it has scanned the code',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: _startDetection,
                icon: const Icon(Icons.check),
                label: const Text('Camera Scanned It'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _goToStep(ProvisioningStep.enterWifiCreds),
                      child: const Text('Back'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: _fallbackToCGI,
                      child: const Text('Use CGI Method'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetectingStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DetectionProgressIndicator(
            detector: _connectionDetector,
            message: 'Waiting for camera to connect to $_selectedSSID',
            onCancel: () {
              _connectionDetector.cancelDetection();
            },
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: _fallbackToCGI,
            child: const Text('Try CGI Method Instead'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Setup Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your camera is now connected to $_selectedSSID',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _complete,
            icon: const Icon(Icons.videocam),
            label: const Text('View Camera'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Setup Failed',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Could not connect to the camera',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Troubleshooting:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Make sure the camera is powered on\n'
                  '• Check that WiFi credentials are correct\n'
                  '• Ensure the camera is within WiFi range\n'
                  '• Try the CGI method as an alternative',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fallbackToCGI,
            icon: const Icon(Icons.settings_ethernet),
            label: const Text('Use CGI Method'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _handleCancel,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

/// Simple QR display content for embedding in wizard
class QRDisplayScreenContent extends StatelessWidget {
  final String qrData;
  final String ssid;
  final double size;

  const QRDisplayScreenContent({
    super.key,
    required this.qrData,
    required this.ssid,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return CameraScanQRCode(
      data: qrData,
      networkName: ssid,
      size: size,
    );
  }
}
