import 'package:flutter/material.dart';
import 'package:veepa_camera_poc/models/player_state.dart';

/// Widget that displays video from a native texture
class TextureVideoWidget extends StatelessWidget {
  /// The texture ID from AppPlayerController (-1 if not ready)
  final int textureId;

  /// Current player state
  final PlayerState playerState;

  /// Aspect ratio (default 16:9)
  final double aspectRatio;

  /// Error message if in error state
  final String? errorMessage;

  /// Callback when user taps retry
  final VoidCallback? onRetry;

  const TextureVideoWidget({
    super.key,
    required this.textureId,
    required this.playerState,
    this.aspectRatio = 16 / 9,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        color: Colors.black,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    switch (playerState) {
      case PlayerState.stopped:
        return _buildStoppedState();

      case PlayerState.buffering:
        return _buildBufferingState();

      case PlayerState.playing:
      case PlayerState.paused:
        return _buildVideoTexture();

      case PlayerState.error:
        return _buildErrorState();
    }
  }

  Widget _buildStoppedState() {
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
  }

  Widget _buildBufferingState() {
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
  }

  Widget _buildVideoTexture() {
    // Check if texture is ready
    if (textureId < 0) {
      debugPrint('[TextureVideo] Invalid texture ID: $textureId, showing buffer state');
      return _buildBufferingState();
    }

    // Display the native texture
    return Stack(
      children: [
        // The actual video texture
        Positioned.fill(
          child: Texture(textureId: textureId),
        ),

        // Pause overlay
        if (playerState == PlayerState.paused)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Icon(
                Icons.pause_circle_outline,
                size: 64,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              errorMessage ?? 'Video error',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
