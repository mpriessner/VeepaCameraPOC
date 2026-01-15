import 'package:flutter/material.dart';
import '../services/camera_config_service.dart';

/// Form widget for entering WiFi credentials
class WifiCredentialsForm extends StatefulWidget {
  final String? initialSSID;
  final WifiEncryption initialEncryption;
  final ValueChanged<WifiCredentials>? onSubmit;
  final VoidCallback? onCancel;
  final bool isLoading;

  const WifiCredentialsForm({
    super.key,
    this.initialSSID,
    this.initialEncryption = WifiEncryption.wpa2,
    this.onSubmit,
    this.onCancel,
    this.isLoading = false,
  });

  @override
  State<WifiCredentialsForm> createState() => _WifiCredentialsFormState();
}

class _WifiCredentialsFormState extends State<WifiCredentialsForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ssidController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late WifiEncryption _selectedEncryption;

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController(text: widget.initialSSID);
    _selectedEncryption = widget.initialEncryption;
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final credentials = WifiCredentials(
      ssid: _ssidController.text.trim(),
      password: _passwordController.text,
      encryption: _selectedEncryption,
    );

    widget.onSubmit?.call(credentials);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SSID field
          TextFormField(
            controller: _ssidController,
            decoration: const InputDecoration(
              labelText: 'WiFi Network Name (SSID)',
              prefixIcon: Icon(Icons.wifi),
              border: OutlineInputBorder(),
            ),
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter the network name';
              }
              if (value.length > 32) {
                return 'SSID cannot exceed 32 characters';
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
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            enabled: !widget.isLoading,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (value) {
              if (_selectedEncryption != WifiEncryption.none) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the password';
                }
                if (value.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (value.length > 63) {
                  return 'Password cannot exceed 63 characters';
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
            onChanged: widget.isLoading
                ? null
                : (value) {
                    setState(() => _selectedEncryption = value!);
                  },
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              if (widget.onCancel != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isLoading ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
              if (widget.onCancel != null) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : _submit,
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Configure'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Data class for WiFi credentials
class WifiCredentials {
  final String ssid;
  final String password;
  final WifiEncryption encryption;

  const WifiCredentials({
    required this.ssid,
    required this.password,
    required this.encryption,
  });

  @override
  String toString() {
    return 'WifiCredentials(ssid: $ssid, encryption: $encryption)';
  }
}
