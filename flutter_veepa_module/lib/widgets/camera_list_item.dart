import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';

class CameraListItem extends StatelessWidget {
  final DiscoveredDevice device;
  final VoidCallback onTap;

  const CameraListItem({
    super.key,
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getMethodColor(),
          child: Icon(
            _getMethodIcon(),
            color: Colors.white,
          ),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (device.ipAddress != null) Text('IP: ${device.ipAddress}'),
            Text(
              'ID: ${device.deviceId}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              _getMethodLabel(),
              style: TextStyle(
                fontSize: 11,
                color: _getMethodColor(),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        isThreeLine: true,
      ),
    );
  }

  IconData _getMethodIcon() {
    switch (device.discoveryMethod) {
      case DiscoveryMethod.lanScan:
        return Icons.wifi;
      case DiscoveryMethod.cloudLookup:
        return Icons.cloud;
      case DiscoveryMethod.manual:
        return Icons.edit;
    }
  }

  Color _getMethodColor() {
    switch (device.discoveryMethod) {
      case DiscoveryMethod.lanScan:
        return Colors.blue;
      case DiscoveryMethod.cloudLookup:
        return Colors.purple;
      case DiscoveryMethod.manual:
        return Colors.orange;
    }
  }

  String _getMethodLabel() {
    switch (device.discoveryMethod) {
      case DiscoveryMethod.lanScan:
        return 'Found via LAN scan';
      case DiscoveryMethod.cloudLookup:
        return 'Found via cloud';
      case DiscoveryMethod.manual:
        return 'Manually entered';
    }
  }
}
