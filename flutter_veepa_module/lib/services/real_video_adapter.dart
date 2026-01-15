import 'dart:async';
import 'package:flutter/foundation.dart';
import 'real_connection_adapter.dart';

/// Video playback state
enum VideoPlaybackState {
  stopped,
  initializing,
  buffering,
  playing,
  paused,
  error,
}

/// Frame metrics from video player
class VideoFrameMetrics {
  final int textureId;
  final Duration duration;
  final int frameCount;
  final double fps;
  final int width;
  final int height;

  const VideoFrameMetrics({
    this.textureId = 0,
    this.duration = Duration.zero,
    this.frameCount = 0,
    this.fps = 0,
    this.width = 0,
    this.height = 0,
  });

  factory VideoFrameMetrics.empty() => const VideoFrameMetrics();
}

/// Adapter for real video playback using the SDK
class RealVideoAdapter extends ChangeNotifier {
  final RealConnectionAdapter _connection;

  VideoPlaybackState _state = VideoPlaybackState.stopped;
  VideoFrameMetrics _metrics = VideoFrameMetrics.empty();
  String? _errorMessage;
  int _channel = 0;
  bool _isMuted = false;

  // Callbacks
  void Function(VideoFrameMetrics)? onFrameUpdate;

  RealVideoAdapter({required RealConnectionAdapter connection})
      : _connection = connection;

  /// Current playback state
  VideoPlaybackState get state => _state;

  /// Whether video is playing
  bool get isPlaying => _state == VideoPlaybackState.playing;

  /// Whether video is buffering
  bool get isBuffering => _state == VideoPlaybackState.buffering;

  /// Current frame metrics
  VideoFrameMetrics get metrics => _metrics;

  /// Error message if playback failed
  String? get errorMessage => _errorMessage;

  /// Current channel
  int get channel => _channel;

  /// Whether audio is muted
  bool get isMuted => _isMuted;

  /// Start video playback
  Future<bool> play({int channel = 0}) async {
    if (!_connection.isConnected) {
      _errorMessage = 'Not connected to camera';
      _transitionTo(VideoPlaybackState.error);
      return false;
    }

    _channel = channel;
    _transitionTo(VideoPlaybackState.initializing);

    debugPrint('[RealVideo] Starting playback on channel $channel');

    try {
      _transitionTo(VideoPlaybackState.buffering);

      final result = await _connection.startStream(channel: channel);
      if (result) {
        _transitionTo(VideoPlaybackState.playing);
        // In real implementation, start receiving frames
        _simulateFrameUpdates();
        return true;
      } else {
        _errorMessage = 'Failed to start stream';
        _transitionTo(VideoPlaybackState.error);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _transitionTo(VideoPlaybackState.error);
      return false;
    }
  }

  /// Stop video playback
  Future<void> stop() async {
    debugPrint('[RealVideo] Stopping playback');

    try {
      await _connection.stopStream();
    } catch (e) {
      debugPrint('[RealVideo] Stop error: $e');
    }

    _metrics = VideoFrameMetrics.empty();
    _transitionTo(VideoPlaybackState.stopped);
  }

  /// Pause video playback
  void pause() {
    if (_state == VideoPlaybackState.playing) {
      _transitionTo(VideoPlaybackState.paused);
    }
  }

  /// Resume video playback
  void resume() {
    if (_state == VideoPlaybackState.paused) {
      _transitionTo(VideoPlaybackState.playing);
    }
  }

  /// Toggle mute
  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
    debugPrint('[RealVideo] Muted: $_isMuted');
  }

  /// Switch channel
  Future<void> switchChannel(int newChannel) async {
    if (_channel == newChannel) return;

    final wasPlaying = isPlaying;
    if (wasPlaying) {
      await stop();
    }

    _channel = newChannel;

    if (wasPlaying) {
      await play(channel: newChannel);
    }
  }

  void _transitionTo(VideoPlaybackState newState) {
    if (_state == newState) return;
    debugPrint('[RealVideo] State: $_state -> $newState');
    _state = newState;
    notifyListeners();
  }

  // Simulate frame updates for mock mode
  void _simulateFrameUpdates() {
    int frameCount = 0;

    Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (_state != VideoPlaybackState.playing) {
        timer.cancel();
        return;
      }

      frameCount++;
      _metrics = VideoFrameMetrics(
        textureId: 1,
        duration: Duration(milliseconds: frameCount * 33),
        frameCount: frameCount,
        fps: 30.0,
        width: 1920,
        height: 1080,
      );

      onFrameUpdate?.call(_metrics);

      // Only run for limited time in mock mode
      if (frameCount > 300) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    // Cleanup stream without notifying (already disposing)
    _connection.stopStream();
    _state = VideoPlaybackState.stopped;
    super.dispose();
  }
}
