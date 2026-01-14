import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/disconnection_handler.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/widgets/disconnection_overlay.dart';

/// Video display screen with disconnection handling
class VideoScreen extends StatefulWidget {
  final DiscoveredDevice device;

  const VideoScreen({
    super.key,
    required this.device,
  });

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  final DisconnectionHandler _disconnectionHandler = DisconnectionHandler();
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  bool _showDisconnectionOverlay = false;
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();

    // Setup disconnection handlers
    _disconnectionHandler.onDisconnected = _onDisconnected;
    _disconnectionHandler.onReconnecting = _onReconnecting;
    _disconnectionHandler.onReconnected = _onReconnected;
    _disconnectionHandler.onReconnectionFailed = _onReconnectionFailed;

    // Start monitoring
    _disconnectionHandler.startMonitoring();
  }

  @override
  void dispose() {
    _disconnectionHandler.stopMonitoring();
    super.dispose();
  }

  void _onDisconnected() {
    if (!mounted) return;
    setState(() {
      _showDisconnectionOverlay = true;
      _isReconnecting = true;
    });
  }

  void _onReconnecting() {
    if (!mounted) return;
    setState(() {
      _isReconnecting = true;
    });
  }

  void _onReconnected() {
    if (!mounted) return;
    setState(() {
      _showDisconnectionOverlay = false;
      _isReconnecting = false;
    });
  }

  void _onReconnectionFailed(String message) {
    if (!mounted) return;
    setState(() {
      _isReconnecting = false;
    });
  }

  void _retryConnection() {
    _connectionManager.retry();
    setState(() {
      _isReconnecting = true;
    });
  }

  void _goBackToCameraList() {
    _disconnectionHandler.forceDisconnect();
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _disconnectionHandler.forceDisconnect();
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // Main video content (placeholder for Epic 4)
          _buildVideoContent(),

          // Disconnection overlay
          if (_showDisconnectionOverlay)
            DisconnectionOverlay(
              onRetry: _retryConnection,
              onGoBack: _goBackToCameraList,
              errorMessage: _connectionManager.errorMessage,
              reconnectAttempt: _connectionManager.reconnectAttempts,
              maxAttempts: VeepaConnectionManager.maxReconnectAttempts,
              isReconnecting: _isReconnecting,
            ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    return Center(
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
            'Connected to: ${widget.device.name}',
            style: const TextStyle(color: Colors.green),
          ),
          if (widget.device.ipAddress != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.device.fullAddress,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}
