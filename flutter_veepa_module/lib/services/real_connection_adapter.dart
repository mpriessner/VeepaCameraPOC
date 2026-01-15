import 'dart:async';
import 'package:flutter/foundation.dart';
import 'sdk_integration_service.dart';

/// Adapter for real camera connections using the SDK
/// This wraps the IVeepaSDK interface and provides connection management
class RealConnectionAdapter extends ChangeNotifier {
  final IVeepaSDK _sdk;
  final String deviceId;
  final String password;
  final String? deviceName;

  int? _handle;
  RealConnectionState _state = RealConnectionState.disconnected;
  String? _errorMessage;
  DateTime? _connectedAt;

  RealConnectionAdapter({
    required IVeepaSDK sdk,
    required this.deviceId,
    required this.password,
    this.deviceName,
  }) : _sdk = sdk;

  /// Current connection state
  RealConnectionState get state => _state;

  /// Whether currently connected
  bool get isConnected => _state == RealConnectionState.connected;

  /// Whether currently connecting
  bool get isConnecting => _state == RealConnectionState.connecting;

  /// Error message if connection failed
  String? get errorMessage => _errorMessage;

  /// The SDK handle for this connection
  int? get handle => _handle;

  /// How long connected
  Duration? get connectionDuration {
    if (_connectedAt == null) return null;
    return DateTime.now().difference(_connectedAt!);
  }

  /// Connect to the camera
  Future<bool> connect() async {
    if (_state == RealConnectionState.connecting) {
      debugPrint('[RealAdapter] Already connecting');
      return false;
    }

    if (_state == RealConnectionState.connected) {
      debugPrint('[RealAdapter] Already connected');
      return true;
    }

    _transitionTo(RealConnectionState.connecting);
    _errorMessage = null;

    debugPrint('[RealAdapter] Connecting to $deviceId');

    try {
      _handle = await _sdk.connect(deviceId, password);
      _connectedAt = DateTime.now();
      _transitionTo(RealConnectionState.connected);
      debugPrint('[RealAdapter] Connected with handle $_handle');
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _transitionTo(RealConnectionState.failed);
      debugPrint('[RealAdapter] Connection failed: $e');
      return false;
    }
  }

  /// Disconnect from the camera
  Future<void> disconnect() async {
    if (_handle == null) return;

    debugPrint('[RealAdapter] Disconnecting handle $_handle');

    try {
      await _sdk.disconnect(_handle!);
    } catch (e) {
      debugPrint('[RealAdapter] Disconnect error: $e');
    }

    _handle = null;
    _connectedAt = null;
    _transitionTo(RealConnectionState.disconnected);
  }

  /// Send a PTZ command
  Future<bool> sendPTZCommand(int code, int speed) async {
    if (_handle == null || !isConnected) {
      debugPrint('[RealAdapter] Cannot send PTZ - not connected');
      return false;
    }

    return await _sdk.sendPTZCommand(_handle!, code, speed);
  }

  /// Start video stream
  Future<bool> startStream({int channel = 0}) async {
    if (_handle == null || !isConnected) {
      debugPrint('[RealAdapter] Cannot start stream - not connected');
      return false;
    }

    return await _sdk.startStream(_handle!, channel);
  }

  /// Stop video stream
  Future<void> stopStream() async {
    if (_handle == null) return;
    await _sdk.stopStream(_handle!);
  }

  /// Reconnect to the camera
  Future<bool> reconnect() async {
    await disconnect();
    await Future.delayed(const Duration(milliseconds: 500));
    return await connect();
  }

  void _transitionTo(RealConnectionState newState) {
    if (_state == newState) return;
    debugPrint('[RealAdapter] State: $_state -> $newState');
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cleanup connection without notifying (already disposing)
    if (_handle != null) {
      _sdk.disconnect(_handle!);
      _handle = null;
    }
    super.dispose();
  }
}

/// Connection states for real SDK connections
enum RealConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
  timeout,
}

/// Extension for state utilities
extension RealConnectionStateExtension on RealConnectionState {
  bool get isActive =>
      this == RealConnectionState.connecting ||
      this == RealConnectionState.connected;

  String get displayName {
    switch (this) {
      case RealConnectionState.disconnected:
        return 'Disconnected';
      case RealConnectionState.connecting:
        return 'Connecting...';
      case RealConnectionState.connected:
        return 'Connected';
      case RealConnectionState.failed:
        return 'Failed';
      case RealConnectionState.timeout:
        return 'Timed Out';
    }
  }
}
