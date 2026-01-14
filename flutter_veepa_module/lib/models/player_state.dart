/// Video player state
enum PlayerState {
  /// Player not started
  stopped,

  /// Stream started, waiting for first frame
  buffering,

  /// Actively playing video
  playing,

  /// Playback paused
  paused,

  /// Error occurred
  error,
}

/// Extension for PlayerState convenience methods
extension PlayerStateExtension on PlayerState {
  /// Whether player is in an active state (not stopped)
  bool get isActive =>
      this == PlayerState.buffering ||
      this == PlayerState.playing ||
      this == PlayerState.paused;

  /// Whether actively playing video
  bool get isPlaying => this == PlayerState.playing;

  /// Whether can start playback
  bool get canPlay => this == PlayerState.stopped || this == PlayerState.error;

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case PlayerState.stopped:
        return 'Stopped';
      case PlayerState.buffering:
        return 'Buffering...';
      case PlayerState.playing:
        return 'Playing';
      case PlayerState.paused:
        return 'Paused';
      case PlayerState.error:
        return 'Error';
    }
  }
}
