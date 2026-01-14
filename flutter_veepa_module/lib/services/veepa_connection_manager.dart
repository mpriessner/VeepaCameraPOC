import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

/// Manages P2P camera connections
class VeepaConnectionManager extends ChangeNotifier {
  static final VeepaConnectionManager _instance =
      VeepaConnectionManager._internal();
  factory VeepaConnectionManager() => _instance;
  VeepaConnectionManager._internal();

  /// Configuration
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxReconnectAttempts = 3;
  static const Duration reconnectDelay = Duration(seconds: 2);

  /// Current state
  ConnectionState _state = ConnectionState.disconnected;
  ConnectionState get state => _state;

  /// Connected device
  DiscoveredDevice? _connectedDevice;
  DiscoveredDevice? get connectedDevice => _connectedDevice;

  /// Error message
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Reconnect attempt counter
  int _reconnectAttempts = 0;
  int get reconnectAttempts => _reconnectAttempts;

  /// Connection stream for state updates
  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// SDK Manager reference
  final VeepaSDKManager _sdkManager = VeepaSDKManager();

  /// Active connection timer
  Timer? _timeoutTimer;

  /// Reset manager state (for testing)
  void reset() {
    _cancelTimeoutTimer();
    _state = ConnectionState.disconnected;
    _connectedDevice = null;
    _errorMessage = null;
    _reconnectAttempts = 0;
    notifyListeners();
  }

  /// Connect to a camera device
  Future<bool> connect(DiscoveredDevice device) async {
    if (_state == ConnectionState.connecting ||
        _state == ConnectionState.reconnecting) {
      debugPrint('[Connection] Already connecting, ignoring request');
      return false;
    }

    if (_state == ConnectionState.connected &&
        _connectedDevice?.deviceId == device.deviceId) {
      debugPrint('[Connection] Already connected to this device');
      return true;
    }

    // Disconnect from current device if connected to different one
    if (_state == ConnectionState.connected) {
      await disconnect();
    }

    _connectedDevice = device;
    _reconnectAttempts = 0;
    return _performConnection();
  }

  /// Internal connection logic
  Future<bool> _performConnection() async {
    _updateState(ConnectionState.connecting);
    _errorMessage = null;

    debugPrint('[Connection] Connecting to ${_connectedDevice?.name}...');
    debugPrint('[Connection] IP: ${_connectedDevice?.ipAddress}');

    // Start timeout timer
    _startTimeoutTimer();

    try {
      // Verify SDK is ready
      if (!_sdkManager.isReady) {
        throw Exception('SDK not initialized');
      }

      // Get P2P API
      final p2pApi = _sdkManager.p2pApi;
      if (p2pApi == null) {
        throw Exception('P2P API not available');
      }

      // Perform P2P connection
      final success = await _connectWithSDK();

      _cancelTimeoutTimer();

      if (success) {
        _updateState(ConnectionState.connected);
        debugPrint('[Connection] Successfully connected!');
        return true;
      } else {
        throw Exception('Connection refused by device');
      }
    } catch (e) {
      _cancelTimeoutTimer();
      debugPrint('[Connection] Connection failed: $e');
      _errorMessage = e.toString();

      // Check if we should retry
      if (_shouldRetry()) {
        return _attemptReconnect();
      }

      _updateState(ConnectionState.error);
      return false;
    }
  }

  /// Connect using SDK (actual implementation)
  Future<bool> _connectWithSDK() async {
    final device = _connectedDevice;
    if (device == null) return false;

    try {
      // Simulated connection delay for POC
      await Future.delayed(const Duration(milliseconds: 500));

      // For POC, we'll simulate success if device has IP
      if (device.ipAddress != null && device.ipAddress!.isNotEmpty) {
        debugPrint('[Connection] P2P session established');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('[Connection] SDK connection error: $e');
      rethrow;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    debugPrint('[Connection] Disconnecting...');

    _cancelTimeoutTimer();
    _reconnectAttempts = 0;

    try {
      await _disconnectWithSDK();
    } catch (e) {
      debugPrint('[Connection] Disconnect error: $e');
    }

    _connectedDevice = null;
    _errorMessage = null;
    _updateState(ConnectionState.disconnected);
  }

  /// Disconnect using SDK
  Future<void> _disconnectWithSDK() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Handle connection lost
  void onConnectionLost() {
    if (_state != ConnectionState.connected) return;

    debugPrint('[Connection] Connection lost detected');
    _attemptReconnect();
  }

  /// Attempt reconnection
  Future<bool> _attemptReconnect() async {
    if (_connectedDevice == null) {
      _updateState(ConnectionState.disconnected);
      return false;
    }

    _reconnectAttempts++;
    debugPrint(
        '[Connection] Reconnect attempt $_reconnectAttempts/$maxReconnectAttempts');

    _updateState(ConnectionState.reconnecting);

    // Wait before retry
    await Future.delayed(reconnectDelay);

    return _performConnection();
  }

  /// Check if should retry connection
  bool _shouldRetry() {
    return _reconnectAttempts < maxReconnectAttempts && _connectedDevice != null;
  }

  /// Start connection timeout timer
  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(connectionTimeout, () {
      if (_state == ConnectionState.connecting ||
          _state == ConnectionState.reconnecting) {
        debugPrint('[Connection] Connection timeout');
        _errorMessage = 'Connection timed out';

        if (_shouldRetry()) {
          _attemptReconnect();
        } else {
          _updateState(ConnectionState.error);
        }
      }
    });
  }

  /// Cancel timeout timer
  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  /// Update connection state
  void _updateState(ConnectionState newState) {
    if (_state == newState) return;

    debugPrint('[Connection] State: ${_state.name} -> ${newState.name}');
    _state = newState;
    _stateController.add(newState);
    notifyListeners();
  }

  /// Retry connection after error
  Future<bool> retry() async {
    if (_connectedDevice == null) {
      debugPrint('[Connection] No device to retry');
      return false;
    }

    _reconnectAttempts = 0;
    return _performConnection();
  }

  @override
  void dispose() {
    _cancelTimeoutTimer();
    _stateController.close();
    super.dispose();
  }
}
