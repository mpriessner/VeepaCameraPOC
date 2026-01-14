import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';

/// Handles disconnection detection, user notification, and app lifecycle changes
class DisconnectionHandler with WidgetsBindingObserver {
  static final DisconnectionHandler _instance = DisconnectionHandler._internal();
  factory DisconnectionHandler() => _instance;
  DisconnectionHandler._internal();

  /// Connection manager reference
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  /// Heartbeat monitoring
  Timer? _heartbeatTimer;
  static const Duration heartbeatInterval = Duration(seconds: 2);
  DateTime? _lastHeartbeat;

  /// Disconnection callbacks
  VoidCallback? onDisconnected;
  VoidCallback? onReconnecting;
  VoidCallback? onReconnected;
  void Function(String message)? onReconnectionFailed;

  /// App lifecycle state
  AppLifecycleState? _lastLifecycleState;
  bool _wasConnectedBeforeBackground = false;
  bool _isMonitoring = false;

  /// Lifecycle callbacks
  VoidCallback? onAppBackgrounded;
  VoidCallback? onAppResumed;

  /// Connection state subscription
  StreamSubscription<ConnectionState>? _connectionSubscription;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Start monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    debugPrint('[DisconnectionHandler] Starting monitoring');
    _isMonitoring = true;

    // Register for app lifecycle events
    WidgetsBinding.instance.addObserver(this);

    // Monitor network connectivity
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Start heartbeat monitoring
    _startHeartbeatMonitoring();

    // Listen for connection state changes
    _connectionSubscription = _connectionManager.stateStream.listen((state) {
      if (state == ConnectionState.connected) {
        onReconnected?.call();
      } else if (state == ConnectionState.error) {
        onReconnectionFailed?.call(_connectionManager.errorMessage ?? 'Unknown error');
      }
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;

    debugPrint('[DisconnectionHandler] Stopping monitoring');
    _isMonitoring = false;

    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[DisconnectionHandler] Lifecycle change: $_lastLifecycleState -> $state');
    _lastLifecycleState = state;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _handleAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        forceDisconnect();
        break;
    }
  }

  /// Handle app going to background
  void _handleAppBackgrounded() {
    debugPrint('[DisconnectionHandler] App entering background');

    _wasConnectedBeforeBackground = _connectionManager.state.isConnected;

    if (_wasConnectedBeforeBackground) {
      debugPrint('[DisconnectionHandler] Pausing P2P connection for background');
      _heartbeatTimer?.cancel();
      onAppBackgrounded?.call();
    }
  }

  /// Handle app returning to foreground
  void _handleAppResumed() {
    debugPrint('[DisconnectionHandler] App returning to foreground');

    if (_wasConnectedBeforeBackground) {
      debugPrint('[DisconnectionHandler] Checking connection after resume');

      _startHeartbeatMonitoring();

      if (!_connectionManager.state.isConnected) {
        debugPrint('[DisconnectionHandler] Connection lost during background, reconnecting');
        _attemptReconnection();
      }

      onAppResumed?.call();
    }

    _wasConnectedBeforeBackground = false;
  }

  /// Handle connectivity change
  void _onConnectivityChanged(ConnectivityResult result) {
    final hasConnection = result == ConnectivityResult.wifi ||
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.ethernet;

    if (!hasConnection && _connectionManager.state.isConnected) {
      debugPrint('[DisconnectionHandler] Network lost while connected');
      _handleDisconnection('Network connection lost');
    } else if (hasConnection && _connectionManager.state == ConnectionState.error) {
      debugPrint('[DisconnectionHandler] Network restored, attempting reconnect');
      _attemptReconnection();
    }
  }

  /// Start heartbeat monitoring
  void _startHeartbeatMonitoring() {
    _heartbeatTimer?.cancel();
    _lastHeartbeat = DateTime.now();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      _checkHeartbeat();
    });
  }

  /// Record heartbeat received
  void recordHeartbeat() {
    _lastHeartbeat = DateTime.now();
  }

  /// Check heartbeat status
  void _checkHeartbeat() {
    if (!_connectionManager.state.isConnected) return;

    final now = DateTime.now();
    if (_lastHeartbeat != null) {
      final elapsed = now.difference(_lastHeartbeat!);
      if (elapsed > heartbeatInterval * 2) {
        debugPrint('[DisconnectionHandler] Heartbeat timeout: ${elapsed.inMilliseconds}ms');
        _handleDisconnection('Connection timeout - no response from camera');
      }
    }
  }

  /// Handle disconnection event
  void _handleDisconnection(String reason) {
    debugPrint('[DisconnectionHandler] Disconnection detected: $reason');
    onDisconnected?.call();
    _attemptReconnection();
  }

  /// Attempt automatic reconnection
  void _attemptReconnection() {
    debugPrint('[DisconnectionHandler] Attempting reconnection');
    onReconnecting?.call();
    _connectionManager.onConnectionLost();
  }

  /// Force disconnect and cleanup
  void forceDisconnect() {
    stopMonitoring();
    _connectionManager.disconnect();
  }

  /// Reset for testing
  void reset() {
    stopMonitoring();
    onDisconnected = null;
    onReconnecting = null;
    onReconnected = null;
    onReconnectionFailed = null;
    onAppBackgrounded = null;
    onAppResumed = null;
    _wasConnectedBeforeBackground = false;
    _lastLifecycleState = null;
    _lastHeartbeat = null;
  }
}
