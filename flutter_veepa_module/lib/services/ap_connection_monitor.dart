import 'dart:async';
import 'package:flutter/foundation.dart';
import 'wifi_discovery_service.dart';

/// State of the AP connection flow
enum APConnectionState {
  initial,
  waitingForConnection,
  detectingAP,
  connected,
  timeout,
  error,
}

/// Result of the AP connection attempt
class APConnectionResult {
  final bool success;
  final String? ssid;
  final String? errorMessage;

  const APConnectionResult({
    required this.success,
    this.ssid,
    this.errorMessage,
  });

  factory APConnectionResult.success(String ssid) {
    return APConnectionResult(success: true, ssid: ssid);
  }

  factory APConnectionResult.timeout() {
    return const APConnectionResult(
      success: false,
      errorMessage: 'Connection timed out',
    );
  }

  factory APConnectionResult.error(String message) {
    return APConnectionResult(success: false, errorMessage: message);
  }
}

/// Monitor for AP mode connection flow with state machine
class APConnectionMonitor extends ChangeNotifier {
  final WifiDiscoveryService _wifiService;
  final Duration timeout;
  final List<String> acceptedPrefixes;

  Timer? _timeoutTimer;
  Timer? _pollTimer;
  Completer<APConnectionResult>? _completer;

  APConnectionState _state = APConnectionState.initial;

  APConnectionMonitor({
    WifiDiscoveryService? wifiService,
    this.timeout = const Duration(minutes: 2),
    this.acceptedPrefixes = const ['VEEPA_', 'VSTC_', 'VEEPA-', 'VSTC-'],
  }) : _wifiService = wifiService ?? WifiDiscoveryService();

  /// Current state of the connection flow
  APConnectionState get state => _state;

  /// Whether we are currently waiting for connection
  bool get isWaiting =>
      _state == APConnectionState.waitingForConnection ||
      _state == APConnectionState.detectingAP;

  /// Whether connection was successful
  bool get isConnected => _state == APConnectionState.connected;

  /// Start monitoring for AP connection
  Future<APConnectionResult> startMonitoring() async {
    if (_completer != null && !_completer!.isCompleted) {
      return _completer!.future;
    }

    _completer = Completer<APConnectionResult>();
    _transitionTo(APConnectionState.waitingForConnection);

    // Check if already connected BEFORE starting monitoring
    // This preserves any manually set WiFi info (e.g., in tests)
    if (_wifiService.isConnectedToVeepaAP) {
      _onAPDetected();
      return _completer!.future;
    }

    // Setup WiFi service callbacks
    _wifiService.onVeepaAPDetected = _onAPDetected;
    _wifiService.onWifiChanged = _onWifiChanged;

    // Start monitoring
    await _wifiService.startMonitoring();

    // Check again after monitoring started (in case it detected something)
    if (_wifiService.isConnectedToVeepaAP) {
      _onAPDetected();
      return _completer!.future;
    }

    // Start timeout timer
    _timeoutTimer = Timer(timeout, _onTimeout);

    // Start polling for faster detection
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _pollConnection(),
    );

    return _completer!.future;
  }

  /// Stop monitoring and cancel any pending operations
  void stopMonitoring() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    _pollTimer?.cancel();
    _pollTimer = null;

    _wifiService.onVeepaAPDetected = null;
    _wifiService.onWifiChanged = null;
    _wifiService.stopMonitoring();

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(APConnectionResult.error('Monitoring cancelled'));
    }

    _transitionTo(APConnectionState.initial);
  }

  /// Retry the connection attempt
  Future<APConnectionResult> retry() async {
    stopMonitoring();
    return startMonitoring();
  }

  void _transitionTo(APConnectionState newState) {
    if (_state == newState) return;

    debugPrint('[APMonitor] State: $_state -> $newState');
    _state = newState;
    notifyListeners();
  }

  void _onAPDetected() {
    debugPrint('[APMonitor] Veepa AP detected!');
    _transitionTo(APConnectionState.detectingAP);

    // Verify the connection
    final ssid = _wifiService.currentWifi.ssid;
    if (ssid != null && _isAcceptedSSID(ssid)) {
      _timeoutTimer?.cancel();
      _pollTimer?.cancel();

      _transitionTo(APConnectionState.connected);

      if (_completer != null && !_completer!.isCompleted) {
        _completer!.complete(APConnectionResult.success(ssid));
      }
    }
  }

  void _onWifiChanged(WifiInfo info) {
    debugPrint('[APMonitor] WiFi changed: $info');

    if (info.isVeepaAP) {
      _onAPDetected();
    } else if (_state == APConnectionState.connected) {
      // Lost connection after being connected
      _transitionTo(APConnectionState.waitingForConnection);
    }
  }

  void _pollConnection() {
    debugPrint('[APMonitor] Polling for connection...');
    _wifiService.refresh();
  }

  void _onTimeout() {
    debugPrint('[APMonitor] Connection timeout');
    _pollTimer?.cancel();

    _transitionTo(APConnectionState.timeout);

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(APConnectionResult.timeout());
    }
  }

  bool _isAcceptedSSID(String ssid) {
    final upper = ssid.toUpperCase();
    return acceptedPrefixes.any(
      (prefix) => upper.startsWith(prefix.toUpperCase()),
    );
  }

  /// Reset the monitor to initial state
  void reset() {
    stopMonitoring();
    _completer = null;
    _transitionTo(APConnectionState.initial);
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
