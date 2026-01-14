import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/utils/ip_validator.dart';

class ManualIPDialog extends StatefulWidget {
  const ManualIPDialog({super.key});

  /// Show the dialog and return the created device, or null if cancelled
  static Future<DiscoveredDevice?> show(BuildContext context) {
    return showDialog<DiscoveredDevice>(
      context: context,
      builder: (context) => const ManualIPDialog(),
    );
  }

  @override
  State<ManualIPDialog> createState() => _ManualIPDialogState();
}

class _ManualIPDialogState extends State<ManualIPDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  final _nameController = TextEditingController();

  bool _isLoading = true;
  String? _ipError;

  static const String _lastIPKey = 'last_manual_ip';
  static const String _lastPortKey = 'last_manual_port';

  @override
  void initState() {
    super.initState();
    _loadLastUsedValues();
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadLastUsedValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastIP = prefs.getString(_lastIPKey);
      final lastPort = prefs.getString(_lastPortKey);

      if (lastIP != null) {
        _ipController.text = lastIP;
      }
      if (lastPort != null) {
        _portController.text = lastPort;
      }
    } catch (e) {
      debugPrint('Failed to load last used values: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLastUsedValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastIPKey, _ipController.text.trim());
      await prefs.setString(_lastPortKey, _portController.text.trim());
    } catch (e) {
      debugPrint('Failed to save last used values: $e');
    }
  }

  /// Validate port number
  String? _validatePort(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final port = int.tryParse(value.trim());
    if (port == null || port < 1 || port > 65535) {
      return 'Port must be 1-65535';
    }

    return null;
  }

  void _onConnect() {
    setState(() {
      _ipError = IPValidator.validate(_ipController.text);
    });

    if (!_formKey.currentState!.validate() || _ipError != null) {
      return;
    }

    _saveLastUsedValues();

    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 80;
    final name = _nameController.text.trim();

    final device = DiscoveredDevice.manual(
      ip,
      name: name.isNotEmpty ? name : null,
      port: port,
    );

    Navigator.pop(context, device);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.edit, size: 24),
          SizedBox(width: 8),
          Text('Manual IP Entry'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'IP Address *',
                        hintText: '192.168.1.100',
                        prefixIcon: const Icon(Icons.lan),
                        errorText: _ipError,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                        LengthLimitingTextInputFormatter(15),
                      ],
                      onChanged: (_) {
                        if (_ipError != null) {
                          setState(() {
                            _ipError = null;
                          });
                        }
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port (optional)',
                        hintText: '80',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      validator: _validatePort,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Camera Name (optional)',
                        hintText: 'Living Room Camera',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter the IP address of your Veepa camera. '
                      'You can find this in your router\'s admin page.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _onConnect,
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
        ),
      ],
    );
  }
}
