import 'package:flutter/material.dart';

class EmptyDiscoveryView extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onManualEntry;

  const EmptyDiscoveryView({
    super.key,
    required this.onRetry,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No Cameras Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure your Veepa camera is:\n'
              '• Powered on\n'
              '• Connected to the same WiFi network\n'
              '• In pairing/discovery mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan Again'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: onManualEntry,
                  icon: const Icon(Icons.edit),
                  label: const Text('Enter IP'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
