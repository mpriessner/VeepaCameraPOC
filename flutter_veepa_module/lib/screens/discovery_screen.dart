import 'dart:async';
import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/screens/connection_screen.dart';
import 'package:veepa_camera_poc/services/veepa_discovery_service.dart';
import 'package:veepa_camera_poc/widgets/camera_list_item.dart';
import 'package:veepa_camera_poc/widgets/empty_discovery_view.dart';
import 'package:veepa_camera_poc/widgets/manual_ip_dialog.dart';

class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final VeepaDiscoveryService _discoveryService = VeepaDiscoveryService();
  StreamSubscription<DiscoveredDevice>? _deviceSubscription;

  @override
  void initState() {
    super.initState();
    _discoveryService.addListener(_onServiceStateChanged);
    _deviceSubscription = _discoveryService.deviceStream.listen(_onDeviceFound);
    _startDiscovery();
  }

  @override
  void dispose() {
    _deviceSubscription?.cancel();
    _discoveryService.removeListener(_onServiceStateChanged);
    _discoveryService.stopDiscovery();
    super.dispose();
  }

  void _onServiceStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onDeviceFound(DiscoveredDevice device) {
    debugPrint('[DiscoveryScreen] Device discovered: ${device.name}');
  }

  Future<void> _startDiscovery() async {
    _discoveryService.clearDevices();
    await _discoveryService.startDiscovery();
  }

  void _onCameraTapped(DiscoveredDevice device) {
    debugPrint('Camera tapped: ${device.name} (${device.ipAddress})');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectionScreen(device: device),
      ),
    );
  }

  Future<void> _onManualEntryTapped() async {
    final device = await ManualIPDialog.show(context);

    if (device != null) {
      _discoveryService.addDiscoveredDevice(device);
      if (mounted) {
        _onCameraTapped(device);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = _discoveryService.state.isScanning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Cameras'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: isScanning ? null : _startDiscovery,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onManualEntryTapped,
        icon: const Icon(Icons.edit),
        label: const Text('Manual IP'),
      ),
    );
  }

  Widget _buildBody() {
    final state = _discoveryService.state;
    final devices = _discoveryService.devices;
    final errorMessage = _discoveryService.errorMessage;

    if (state.isError && errorMessage != null) {
      return _buildErrorView(errorMessage);
    }

    if (state.isScanning && devices.isEmpty) {
      return _buildLoadingView();
    }

    if (!state.isScanning && devices.isEmpty) {
      return EmptyDiscoveryView(
        onRetry: _startDiscovery,
        onManualEntry: _onManualEntryTapped,
      );
    }

    return _buildDeviceList(devices, state.isScanning);
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Scanning for cameras...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Make sure cameras are on the same network',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Discovery Error',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startDiscovery,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<DiscoveredDevice> devices, bool isScanning) {
    return Column(
      children: [
        if (isScanning) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${devices.length} camera${devices.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isScanning) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return CameraListItem(
                device: device,
                onTap: () => _onCameraTapped(device),
              );
            },
          ),
        ),
      ],
    );
  }
}
