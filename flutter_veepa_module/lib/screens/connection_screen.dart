import 'dart:async';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/screens/video_screen.dart';

/// Screen showing connection status to a camera device
class ConnectionScreen extends StatefulWidget {
  final DiscoveredDevice device;

  const ConnectionScreen({
    super.key,
    required this.device,
  });

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with SingleTickerProviderStateMixin {
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  late AnimationController _pulseController;
  StreamSubscription<ConnectionState>? _stateSubscription;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for connecting state
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Listen to connection state changes
    _stateSubscription = _connectionManager.stateStream.listen(_onStateChanged);

    // Start connection
    _connect();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _stateSubscription?.cancel();
    super.dispose();
  }

  void _onStateChanged(ConnectionState state) {
    if (!mounted) return;

    setState(() {});

    // Navigate to video screen on successful connection
    if (state == ConnectionState.connected) {
      _navigateToVideo();
    }
  }

  Future<void> _connect() async {
    await _connectionManager.connect(widget.device);
  }

  void _retry() {
    _connectionManager.retry();
  }

  void _cancel() {
    _connectionManager.disconnect();
    Navigator.pop(context);
  }

  void _navigateToVideo() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => VideoScreen(device: widget.device),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connecting'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancel,
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Device info
              _buildDeviceInfo(),
              const SizedBox(height: 48),

              // Connection status
              _buildConnectionStatus(),
              const SizedBox(height: 32),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfo() {
    return Column(
      children: [
        // Device icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.videocam,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Device name
        Text(
          widget.device.name,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Device IP
        if (widget.device.ipAddress != null)
          Text(
            widget.device.fullAddress,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final state = _connectionManager.state;

    return Column(
      children: [
        // Status indicator
        _buildStatusIndicator(state),
        const SizedBox(height: 16),

        // Status text
        Text(
          state.displayName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: _getStatusColor(state),
          ),
        ),

        // Error message
        if (state == ConnectionState.error &&
            _connectionManager.errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _connectionManager.errorMessage!,
                    style: TextStyle(color: Colors.red[700], fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Reconnect attempt counter
        if (state == ConnectionState.reconnecting) ...[
          const SizedBox(height: 8),
          Text(
            'Attempt ${_connectionManager.reconnectAttempts}/${VeepaConnectionManager.maxReconnectAttempts}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              width: 60 + (_pulseController.value * 20),
              height: 60 + (_pulseController.value * 20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(0.2 - (_pulseController.value * 0.1)),
              ),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.blue,
                  ),
                ),
              ),
            );
          },
        );

      case ConnectionState.connected:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.green[100],
          ),
          child: Icon(
            Icons.check_circle,
            size: 40,
            color: Colors.green[700],
          ),
        );

      case ConnectionState.error:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red[100],
          ),
          child: Icon(
            Icons.error,
            size: 40,
            color: Colors.red[700],
          ),
        );

      case ConnectionState.disconnected:
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
          ),
          child: Icon(
            Icons.link_off,
            size: 40,
            color: Colors.grey[600],
          ),
        );
    }
  }

  Color _getStatusColor(ConnectionState state) {
    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return Colors.blue;
      case ConnectionState.connected:
        return Colors.green;
      case ConnectionState.error:
        return Colors.red;
      case ConnectionState.disconnected:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons() {
    final state = _connectionManager.state;

    switch (state) {
      case ConnectionState.connecting:
      case ConnectionState.reconnecting:
        return OutlinedButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close),
          label: const Text('Cancel'),
        );

      case ConnectionState.error:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        );

      case ConnectionState.connected:
        // Brief display before navigation
        return const Text(
          'Opening video stream...',
          style: TextStyle(color: Colors.green),
        );

      case ConnectionState.disconnected:
        return ElevatedButton.icon(
          onPressed: _connect,
          icon: const Icon(Icons.link),
          label: const Text('Connect'),
        );
    }
  }
}
