import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';

/// Video display screen - placeholder for Epic 4
class VideoScreen extends StatelessWidget {
  final DiscoveredDevice device;

  const VideoScreen({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Video Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming in Epic 4',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'Connected to: ${device.name}',
              style: const TextStyle(color: Colors.green),
            ),
            if (device.ipAddress != null) ...[
              const SizedBox(height: 8),
              Text(
                device.fullAddress,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
