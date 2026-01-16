import 'package:veepa_camera_poc/sdk/app_p2p_api.dart';

/// Maps SDK error codes and states to user-friendly messages
class ConnectionErrorMapper {
  /// Map numeric error codes to user-friendly messages
  static String mapErrorCode(int code) {
    switch (code) {
      case 0:
        return 'Connection successful';
      case -1:
        return 'SDK not initialized. Please restart the app.';
      case -2:
        return 'Connection timeout. Device may be offline.';
      case -3:
        return 'Authentication failed. Check your password.';
      case -4:
        return 'Device is busy. Try again later.';
      case -5:
        return 'Invalid parameter. Check device ID.';
      case -11:
        return 'Session invalid. Please reconnect.';
      case -12:
        return 'Connection closed by device.';
      case -13:
        return 'Connection timeout. Check your network.';
      case -15:
        return 'Device buffer full. Try again later.';
      default:
        if (code < 0) {
          return 'Connection failed (error $code)';
        }
        return 'Unknown error';
    }
  }

  /// Map SDK connection states to user-friendly messages
  static String mapConnectionState(ClientConnectState state) {
    switch (state) {
      case ClientConnectState.CONNECT_STATUS_INVALID_CLIENT:
        return 'Invalid client. Please restart.';
      case ClientConnectState.CONNECT_STATUS_CONNECTING:
        return 'Connecting to camera...';
      case ClientConnectState.CONNECT_STATUS_INITIALING:
        return 'Initializing connection...';
      case ClientConnectState.CONNECT_STATUS_ONLINE:
        return 'Connected successfully';
      case ClientConnectState.CONNECT_STATUS_CONNECT_FAILED:
        return 'Connection failed. Check device ID.';
      case ClientConnectState.CONNECT_STATUS_DISCONNECT:
        return 'Disconnected from camera.';
      case ClientConnectState.CONNECT_STATUS_INVALID_ID:
        return 'Invalid device ID. Check the camera UID.';
      case ClientConnectState.CONNECT_STATUS_OFFLINE:
        return 'Camera is offline. Check if it\'s powered on.';
      case ClientConnectState.CONNECT_STATUS_CONNECT_TIMEOUT:
        return 'Connection timed out. Camera may be unreachable.';
      case ClientConnectState.CONNECT_STATUS_MAX_SESSION:
        return 'Maximum connections reached. Disconnect other sessions.';
      case ClientConnectState.CONNECT_STATUS_MAX:
        return 'Connection limit reached.';
      case ClientConnectState.CONNECT_STATUS_REMOVE_CLOSE:
        return 'Connection closed remotely.';
    }
  }

  /// Check if error code indicates an authentication error
  static bool isAuthError(int code) => code == -3;

  /// Check if the connection state indicates an auth error
  static bool isAuthStateError(ClientConnectState state) =>
      state == ClientConnectState.CONNECT_STATUS_CONNECT_FAILED;

  /// Check if error code indicates a network error
  static bool isNetworkError(int code) => code == -2 || code == -5 || code == -13;

  /// Check if error code indicates a device error
  static bool isDeviceError(int code) => code == -1 || code == -4 || code == -11;

  /// Parse exception message to provide better error text
  static String parseExceptionMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('authentication failed') ||
        lowerMessage.contains('login') ||
        lowerMessage.contains('password')) {
      return 'Authentication failed. Check your password.';
    }

    if (lowerMessage.contains('timeout')) {
      return 'Connection timed out. Camera may be offline.';
    }

    if (lowerMessage.contains('p2p') && lowerMessage.contains('failed')) {
      return 'P2P connection failed. Check device UID.';
    }

    if (lowerMessage.contains('sdk') || lowerMessage.contains('initialize')) {
      return 'SDK error. Please restart the app.';
    }

    if (lowerMessage.contains('not available')) {
      return 'Camera not available. Try again later.';
    }

    // Return cleaned-up version of original message
    return message.replaceAll('Exception: ', '');
  }
}
