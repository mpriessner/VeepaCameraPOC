import 'package:flutter/material.dart';

/// Dialog for entering camera password
class PasswordDialog extends StatefulWidget {
  final String deviceName;
  final String? initialPassword;

  const PasswordDialog({
    super.key,
    required this.deviceName,
    this.initialPassword,
  });

  /// Show the dialog and return the password, or null if cancelled
  static Future<String?> show(
    BuildContext context,
    String deviceName, {
    String? initialPassword,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PasswordDialog(
        deviceName: deviceName,
        initialPassword: initialPassword,
      ),
    );
  }

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPassword ?? 'admin',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onConnect() {
    final password = _controller.text.trim();
    if (password.isEmpty) {
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Connect to ${widget.deviceName}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter camera password:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) => _onConnect(),
          ),
          const SizedBox(height: 8),
          Text(
            'Default password for most cameras is "admin"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _onConnect,
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
        ),
      ],
    );
  }
}
