/// Types of video errors
enum VideoErrorType {
  /// No data received within timeout
  bufferingTimeout,

  /// Frame decode failed
  decodeError,

  /// Stream unexpectedly ended
  streamEnded,

  /// Network error during streaming
  networkError,

  /// SDK/Player internal error
  playerError,

  /// Unknown error
  unknown,
}

extension VideoErrorTypeExtension on VideoErrorType {
  /// User-friendly error message
  String get userMessage {
    switch (this) {
      case VideoErrorType.bufferingTimeout:
        return 'Unable to load video. Please check your connection and try again.';
      case VideoErrorType.decodeError:
        return 'Video format error. The stream may be corrupted.';
      case VideoErrorType.streamEnded:
        return 'Video stream ended unexpectedly. The camera may have disconnected.';
      case VideoErrorType.networkError:
        return 'Network error. Please check your WiFi connection.';
      case VideoErrorType.playerError:
        return 'Video player error. Please try restarting the stream.';
      case VideoErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Error title for display
  String get title {
    switch (this) {
      case VideoErrorType.bufferingTimeout:
        return 'Video Loading Timeout';
      case VideoErrorType.networkError:
        return 'Network Error';
      case VideoErrorType.streamEnded:
        return 'Stream Ended';
      case VideoErrorType.decodeError:
        return 'Video Format Error';
      case VideoErrorType.playerError:
        return 'Player Error';
      case VideoErrorType.unknown:
        return 'Video Error';
    }
  }

  /// Whether this error type can potentially recover automatically
  bool get isRecoverable {
    switch (this) {
      case VideoErrorType.bufferingTimeout:
      case VideoErrorType.networkError:
        return true;
      case VideoErrorType.decodeError:
      case VideoErrorType.streamEnded:
      case VideoErrorType.playerError:
      case VideoErrorType.unknown:
        return false;
    }
  }
}
