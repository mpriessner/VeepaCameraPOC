import 'dart:async';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/models/player_state.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/models/video_error_type.dart';
import 'package:veepa_camera_poc/services/veepa_player_service.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/disconnection_handler.dart';
import 'package:veepa_camera_poc/services/video_error_handler.dart';
import 'package:veepa_camera_poc/widgets/disconnection_overlay.dart';
import 'package:veepa_camera_poc/widgets/video_error_widget.dart';

/// Video display screen with live video, controls overlay, and debug info
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
  final VeepaPlayerService _playerService = VeepaPlayerService();
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();
  final DisconnectionHandler _disconnectionHandler = DisconnectionHandler();

  bool _showControls = true;
  bool _showDebugInfo = false;
  bool _showDisconnectionOverlay = false;
  bool _isReconnecting = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();

    // Listen to player state
    _playerService.addListener(_onPlayerStateChanged);

    // Setup disconnection handling
    _setupDisconnectionHandler();

    // Start video playback
    _startVideo();

    // Auto-hide controls after delay
    _scheduleHideControls();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _playerService.removeListener(_onPlayerStateChanged);
    _playerService.stop();
    _disconnectionHandler.stopMonitoring();
    super.dispose();
  }

  void _setupDisconnectionHandler() {
    _disconnectionHandler.onDisconnected = () {
      if (!mounted) return;
      setState(() {
        _showDisconnectionOverlay = true;
        _isReconnecting = true;
      });
    };

    _disconnectionHandler.onReconnecting = () {
      if (!mounted) return;
      setState(() {
        _isReconnecting = true;
      });
    };

    _disconnectionHandler.onReconnected = () {
      if (!mounted) return;
      setState(() {
        _showDisconnectionOverlay = false;
        _isReconnecting = false;
      });
      // Restart video after reconnection
      _startVideo();
    };

    _disconnectionHandler.onReconnectionFailed = (message) {
      if (!mounted) return;
      setState(() {
        _isReconnecting = false;
      });
    };

    _disconnectionHandler.startMonitoring();
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _startVideo() async {
    await _playerService.start(widget.device);
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _scheduleHideControls();
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showControls) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleDebugInfo() {
    setState(() {
      _showDebugInfo = !_showDebugInfo;
    });
  }

  void _goBack() {
    _playerService.stop();
    _connectionManager.disconnect();
    Navigator.pop(context);
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
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video display
            _buildVideoDisplay(),

            // Controls overlay
            if (_showControls) _buildControlsOverlay(),

            // Debug info
            if (_showDebugInfo) _buildDebugOverlay(),

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
      ),
    );
  }

  Widget _buildVideoDisplay() {
    final playerState = _playerService.state;

    return Center(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: _buildVideoContent(playerState),
        ),
      ),
    );
  }

  Widget _buildVideoContent(PlayerState state) {
    switch (state) {
      case PlayerState.stopped:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videocam_off, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Video stopped', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );

      case PlayerState.buffering:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Loading video...', style: TextStyle(color: Colors.white)),
            ],
          ),
        );

      case PlayerState.playing:
        // POC: Placeholder for actual video texture
        return Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text(
                  'Video Playing',
                  style: TextStyle(color: Colors.green, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  '(Actual video texture coming with SDK integration)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        );

      case PlayerState.paused:
        return Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.pause_circle, size: 64, color: Colors.white),
          ),
        );

      case PlayerState.error:
        final errorType = VideoErrorHandler.classifyError(
          _playerService.errorMessage ?? 'Unknown error',
        );
        VideoErrorHandler.logError(errorType, _playerService.errorMessage);
        return VideoErrorWidget(
          errorType: errorType,
          technicalError: _playerService.errorMessage,
          showTechnicalDetails: _showDebugInfo,
          onRetry: _startVideo,
          onGoBack: _goBack,
        );
    }
  }

  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(),

              const Spacer(),

              // Bottom controls
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _goBack,
          ),

          // Device name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _connectionManager.state.isConnected
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _connectionManager.state.displayName,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Debug toggle
          IconButton(
            icon: Icon(
              Icons.bug_report,
              color: _showDebugInfo ? Colors.yellow : Colors.white,
            ),
            onPressed: _toggleDebugInfo,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Play/Pause button
          IconButton(
            iconSize: 48,
            icon: Icon(
              _playerService.state == PlayerState.playing
                  ? Icons.pause_circle
                  : Icons.play_circle,
              color: Colors.white,
            ),
            onPressed: () {
              if (_playerService.state == PlayerState.playing) {
                _playerService.pause();
              } else if (_playerService.state == PlayerState.paused) {
                _playerService.resume();
              } else {
                _startVideo();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebugOverlay() {
    return Positioned(
      top: 100,
      left: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Debug Info',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _debugRow('Player', _playerService.state.displayName),
            _debugRow('Connection', _connectionManager.state.displayName),
            _debugRow('FPS', _playerService.currentFPS.toStringAsFixed(1)),
            _debugRow('Device ID', widget.device.deviceId),
            _debugRow('IP', widget.device.ipAddress ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
