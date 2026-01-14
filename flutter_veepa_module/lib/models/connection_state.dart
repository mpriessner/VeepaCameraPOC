/// Connection state for P2P camera connection
enum ConnectionState {
  /// No active connection
  disconnected,

  /// Currently establishing connection
  connecting,

  /// Successfully connected to camera
  connected,

  /// Connection lost, attempting to reconnect
  reconnecting,

  /// Connection failed with error
  error,
}

/// Extension for ConnectionState convenience methods
extension ConnectionStateExtension on ConnectionState {
  /// Whether currently connected
  bool get isConnected => this == ConnectionState.connected;

  /// Whether currently attempting to connect
  bool get isConnecting =>
      this == ConnectionState.connecting || this == ConnectionState.reconnecting;

  /// Whether can initiate a new connection
  bool get canConnect =>
      this == ConnectionState.disconnected || this == ConnectionState.error;

  /// Human-readable display name
  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.reconnecting:
        return 'Reconnecting...';
      case ConnectionState.error:
        return 'Connection Failed';
    }
  }
}
