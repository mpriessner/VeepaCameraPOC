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
  final _uidController = TextEditingController();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '80');
  final _nameController = TextEditingController();

  bool _isLoading = true;
  String? _ipError;
  String? _uidError;

  static const String _lastUIDKey = 'last_manual_uid';
  static const String _lastIPKey = 'last_manual_ip';
  static const String _lastPortKey = 'last_manual_port';

  @override
  void initState() {
    super.initState();
    _loadLastUsedValues();
  }

  @override
  void dispose() {
    _uidController.dispose();
    _ipController.dispose();
    _portController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadLastUsedValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUID = prefs.getString(_lastUIDKey);
      final lastIP = prefs.getString(_lastIPKey);
      final lastPort = prefs.getString(_lastPortKey);

      if (lastUID != null) {
        _uidController.text = lastUID;
      }
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
      await prefs.setString(_lastUIDKey, _uidController.text.trim());
      await prefs.setString(_lastIPKey, _ipController.text.trim());
      await prefs.setString(_lastPortKey, _portController.text.trim());
    } catch (e) {
      debugPrint('Failed to save last used values: $e');
    }
  }

  /// Validate UID
  String? _validateUID(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Camera UID is required';
    }
    if (value.trim().length < 5) {
      return 'UID seems too short';
    }
    return null;
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
    // Validate UID (required)
    setState(() {
      _uidError = _validateUID(_uidController.text);
      // IP is now optional - only validate if provided
      if (_ipController.text.trim().isNotEmpty) {
        _ipError = IPValidator.validate(_ipController.text);
      } else {
        _ipError = null;
      }
    });

    if (!_formKey.currentState!.validate() || _uidError != null || _ipError != null) {
      return;
    }

    _saveLastUsedValues();

    final uid = _uidController.text.trim();
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 80;
    final name = _nameController.text.trim();

    // Use manualUID factory which creates device with proper UID for P2P connection
    final device = DiscoveredDevice.manualUID(
      uid,
      name: name.isNotEmpty ? name : 'Camera $uid',
      ipAddress: ip.isNotEmpty ? ip : null,
      port: port,
    );

    Navigator.pop(context, device);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.videocam, size: 24),
          SizedBox(width: 8),
          Text('Connect Camera'),
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
                    // Camera UID (required for P2P connection)
                    TextFormField(
                      controller: _uidController,
                      decoration: InputDecoration(
                        labelText: 'Camera UID *',
                        hintText: 'OKB0379853SNLJ',
                        prefixIcon: const Icon(Icons.key),
                        errorText: _uidError,
                        border: const OutlineInputBorder(),
                        helperText: 'Required for P2P connection',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      onChanged: (_) {
                        if (_uidError != null) {
                          setState(() {
                            _uidError = null;
                          });
                        }
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    // IP Address (optional)
                    TextFormField(
                      controller: _ipController,
                      decoration: InputDecoration(
                        labelText: 'IP Address (optional)',
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The Camera UID is found on the camera label or in the original Veepa app (e.g., OKB0379853SNLJ)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
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
