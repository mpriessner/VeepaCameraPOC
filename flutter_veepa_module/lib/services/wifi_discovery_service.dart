import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Information about current WiFi connection
class WifiInfo {
  final String? ssid;
  final bool isConnected;
  final bool isVeepaAP;

  const WifiInfo({
    this.ssid,
    required this.isConnected,
    required this.isVeepaAP,
  });

  factory WifiInfo.disconnected() {
    return const WifiInfo(
      ssid: null,
      isConnected: false,
      isVeepaAP: false,
    );
  }

  factory WifiInfo.connected(String ssid) {
    return WifiInfo(
      ssid: ssid,
      isConnected: true,
      isVeepaAP: _isVeepaSSID(ssid),
    );
  }

  static bool _isVeepaSSID(String ssid) {
    final upper = ssid.toUpperCase();
    return upper.startsWith('VEEPA_') ||
           upper.startsWith('VSTC_') ||
           upper.startsWith('VEEPA-') ||
           upper.startsWith('VSTC-');
  }

  @override
  String toString() {
    return 'WifiInfo(ssid: $ssid, connected: $isConnected, isVeepaAP: $isVeepaAP)';
  }
}

/// Service for monitoring WiFi connection state
class WifiDiscoveryService extends ChangeNotifier {
  static final WifiDiscoveryService _instance = WifiDiscoveryService._internal();
  factory WifiDiscoveryService() => _instance;
  WifiDiscoveryService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  WifiInfo _currentWifi = WifiInfo.disconnected();
  bool _isMonitoring = false;

  // Callbacks
  void Function(WifiInfo)? onWifiChanged;
  void Function()? onVeepaAPDetected;
  void Function()? onVeepaAPLost;

  /// Current WiFi information
  WifiInfo get currentWifi => _currentWifi;

  /// Whether monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Whether currently connected to a Veepa camera AP
  bool get isConnectedToVeepaAP => _currentWifi.isVeepaAP;

  /// Start monitoring WiFi changes
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    debugPrint('[WifiDiscovery] Starting monitoring');

    // Get initial state
    await _checkCurrentConnection();

    // Subscribe to changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    notifyListeners();
  }

  /// Stop monitoring WiFi changes
  void stopMonitoring() {
    if (!_isMonitoring) return;

    _subscription?.cancel();
    _subscription = null;
    _isMonitoring = false;
    debugPrint('[WifiDiscovery] Stopped monitoring');
    notifyListeners();
  }

  /// Manually refresh WiFi state
  Future<void> refresh() async {
    await _checkCurrentConnection();
  }

  Future<void> _checkCurrentConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result == ConnectivityResult.wifi) {
        // Connected to WiFi - we need native code to get SSID
        // For now, simulate with a placeholder
        // In real implementation, use platform channel to get SSID
        _updateWifiInfo(WifiInfo.connected('Unknown_WiFi'));
      } else {
        _updateWifiInfo(WifiInfo.disconnected());
      }
    } catch (e) {
      debugPrint('[WifiDiscovery] Error checking connection: $e');
      _updateWifiInfo(WifiInfo.disconnected());
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    debugPrint('[WifiDiscovery] Connectivity changed: $result');

    if (result == ConnectivityResult.wifi) {
      // Need platform channel to get actual SSID
      _updateWifiInfo(WifiInfo.connected('Unknown_WiFi'));
    } else {
      _updateWifiInfo(WifiInfo.disconnected());
    }
  }

  void _updateWifiInfo(WifiInfo info) {
    final wasVeepaAP = _currentWifi.isVeepaAP;
    _currentWifi = info;

    debugPrint('[WifiDiscovery] WiFi info updated: $info');

    // Trigger callbacks
    onWifiChanged?.call(info);

    if (info.isVeepaAP && !wasVeepaAP) {
      onVeepaAPDetected?.call();
      debugPrint('[WifiDiscovery] Veepa AP detected!');
    } else if (!info.isVeepaAP && wasVeepaAP) {
      onVeepaAPLost?.call();
      debugPrint('[WifiDiscovery] Veepa AP lost');
    }

    notifyListeners();
  }

  /// Manually set WiFi info (for testing or when SSID is obtained via platform channel)
  void setWifiInfo(WifiInfo info) {
    _updateWifiInfo(info);
  }

  /// Check if a given SSID is a Veepa camera AP
  static bool isVeepaSSID(String ssid) {
    return WifiInfo.connected(ssid).isVeepaAP;
  }

  /// Reset the service
  void reset() {
    stopMonitoring();
    _currentWifi = WifiInfo.disconnected();
    onWifiChanged = null;
    onVeepaAPDetected = null;
    onVeepaAPLost = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
