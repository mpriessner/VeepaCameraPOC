import 'package:flutter/foundation.dart';
import 'package:veepa_camera_poc/models/video_error_type.dart';

/// Handles video error classification and recovery
class VideoErrorHandler {
  /// Classify error from exception
  static VideoErrorType classifyError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('timeout') || errorString.contains('buffering')) {
      return VideoErrorType.bufferingTimeout;
    }

    if (errorString.contains('decode') || errorString.contains('codec')) {
      return VideoErrorType.decodeError;
    }

    if (errorString.contains('end') || errorString.contains('eof') || errorString.contains('ended')) {
      return VideoErrorType.streamEnded;
    }

    if (errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('connection')) {
      return VideoErrorType.networkError;
    }

    if (errorString.contains('player') || errorString.contains('sdk')) {
      return VideoErrorType.playerError;
    }

    return VideoErrorType.unknown;
  }

  /// Get retry delay based on error type
  static Duration getRetryDelay(VideoErrorType type) {
    switch (type) {
      case VideoErrorType.bufferingTimeout:
        return const Duration(seconds: 2);
      case VideoErrorType.networkError:
        return const Duration(seconds: 5);
      default:
        return const Duration(seconds: 3);
    }
  }

  /// Log error with context
  static void logError(VideoErrorType type, dynamic error, [StackTrace? stack]) {
    debugPrint('[VideoError] Type: ${type.name}');
    debugPrint('[VideoError] Message: ${type.userMessage}');
    debugPrint('[VideoError] Original: $error');
    if (stack != null) {
      debugPrint('[VideoError] Stack: $stack');
    }
  }
}
