import 'package:flutter/material.dart';
import '../services/camera_config_service.dart';

/// Screen for configuring camera WiFi connection
class WifiProvisioningScreen extends StatefulWidget {
  final String? deviceId;
  final VoidCallback? onProvisioningComplete;

  const WifiProvisioningScreen({
    super.key,
    this.deviceId,
    this.onProvisioningComplete,
  });

  @override
  State<WifiProvisioningScreen> createState() => _WifiProvisioningScreenState();
}

class _WifiProvisioningScreenState extends State<WifiProvisioningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  CameraConfigService? _configService;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _successMessage;

  WifiEncryption _selectedEncryption = WifiEncryption.wpa2;

  @override
  void initState() {
    super.initState();
    // Create config service for camera in AP mode
    _configService = CameraConfigServiceFactory.forAPMode();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _configService?.dispose();
    super.dispose();
  }

  Future<void> _submitWifiConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _configService!.setWifiConfig(
        ssid: _ssidController.text.trim(),
        password: _passwordController.text,
        encryption: _selectedEncryption,
      );

      if (result.success) {
        setState(() {
          _successMessage = 'WiFi configuration sent to camera.\n'
              'The camera will restart and connect to your network.';
        });

        // Wait a moment then trigger reboot
        await Future.delayed(const Duration(seconds: 1));
        await _configService!.rebootCamera();

        // Notify completion
        widget.onProvisioningComplete?.call();

        // Close screen after delay
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Configuration failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                const Icon(
                  Icons.wifi_lock,
                  size: 60,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Connect Camera to WiFi',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your home WiFi credentials to connect the camera to your network.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                // SSID field
                TextFormField(
                  controller: _ssidController,
                  decoration: const InputDecoration(
                    labelText: 'WiFi Network Name (SSID)',
                    prefixIcon: Icon(Icons.wifi),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the network name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'WiFi Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (_selectedEncryption != WifiEncryption.none) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Encryption dropdown
                DropdownButtonFormField<WifiEncryption>(
                  value: _selectedEncryption,
                  decoration: const InputDecoration(
                    labelText: 'Security Type',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: WifiEncryption.wpa2,
                      child: Text('WPA2 (Recommended)'),
                    ),
                    DropdownMenuItem(
                      value: WifiEncryption.wpa3,
                      child: Text('WPA3'),
                    ),
                    DropdownMenuItem(
                      value: WifiEncryption.wpa,
                      child: Text('WPA'),
                    ),
                    DropdownMenuItem(
                      value: WifiEncryption.wep,
                      child: Text('WEP (Not Recommended)'),
                    ),
                    DropdownMenuItem(
                      value: WifiEncryption.none,
                      child: Text('None (Open Network)'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedEncryption = value!);
                  },
                ),
                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Success message
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitWifiConfig,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Configure Camera'),
                ),

                const SizedBox(height: 16),

                // Help text
                Text(
                  'After configuration, the camera will restart and connect to your WiFi network. '
                  'This may take up to 30 seconds.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
