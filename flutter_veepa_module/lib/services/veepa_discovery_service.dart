import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

/// Service for discovering Veepa cameras on the network
class VeepaDiscoveryService extends ChangeNotifier {
  final VeepaSDKManager _sdkManager;

  /// Discovery state
  DiscoveryState _state = DiscoveryState.idle;
  DiscoveryState get state => _state;

  /// List of discovered devices
  final List<DiscoveredDevice> _devices = [];
  List<DiscoveredDevice> get devices => List.unmodifiable(_devices);

  /// Error message if discovery failed
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Stream controller for real-time device discovery
  final _deviceStreamController =
      StreamController<DiscoveredDevice>.broadcast();
  Stream<DiscoveredDevice> get deviceStream => _deviceStreamController.stream;

  /// Discovery timeout duration
  Duration discoveryTimeout;

  /// Timer for timeout
  Timer? _timeoutTimer;

  VeepaDiscoveryService({
    VeepaSDKManager? sdkManager,
    this.discoveryTimeout = const Duration(seconds: 5),
  }) : _sdkManager = sdkManager ?? VeepaSDKManager();

  /// Start device discovery
  /// Returns list of discovered devices after timeout
  Future<List<DiscoveredDevice>> startDiscovery() async {
    if (_state == DiscoveryState.scanning) {
      debugPrint('[Discovery] Already scanning, skipping...');
      return _devices;
    }

    // Verify SDK is ready
    if (!_sdkManager.isReady) {
      _state = DiscoveryState.error;
      _errorMessage = 'SDK not initialized';
      notifyListeners();
      return [];
    }

    _state = DiscoveryState.scanning;
    _errorMessage = null;
    _devices.clear();
    notifyListeners();

    debugPrint('[Discovery] Starting LAN scan...');

    try {
      // Start timeout timer
      _startTimeoutTimer();

      // Perform LAN discovery using SDK
      await _performLANDiscovery();

      // Wait for timeout or completion
      await Future.delayed(discoveryTimeout);

      _state = _devices.isEmpty
          ? DiscoveryState.noDevicesFound
          : DiscoveryState.completed;
      debugPrint('[Discovery] Scan complete. Found ${_devices.length} device(s)');
    } catch (e, stackTrace) {
      _state = DiscoveryState.error;
      _errorMessage = e.toString();
      debugPrint('[Discovery] Error during scan: $e');
      debugPrint('[Discovery] Stack trace: $stackTrace');
    } finally {
      _cancelTimeoutTimer();
      notifyListeners();
    }

    return _devices;
  }

  /// Perform LAN discovery using SDK
  Future<void> _performLANDiscovery() async {
    try {
      final p2pApi = _sdkManager.p2pApi;
      if (p2pApi == null) {
        throw Exception('P2P API not available');
      }

      // SDK discovery call
      // In real implementation, SDK callback will add devices
      debugPrint('[Discovery] Scanning local network...');
    } catch (e) {
      debugPrint('[Discovery] LAN discovery error: $e');
      rethrow;
    }
  }

  /// Add a discovered device (called by SDK callback or manually)
  void addDiscoveredDevice(DiscoveredDevice device) {
    // Avoid duplicates
    if (!_devices.contains(device)) {
      _devices.add(device);
      _deviceStreamController.add(device);
      debugPrint(
          '[Discovery] Found device: ${device.name} (${device.ipAddress})');
      notifyListeners();
    }
  }

  /// Add device via manual IP entry
  Future<DiscoveredDevice?> addManualDevice(String ipAddress,
      {String? name}) async {
    // Validate IP format
    if (!_isValidIP(ipAddress)) {
      _errorMessage = 'Invalid IP address format';
      notifyListeners();
      return null;
    }

    final device = DiscoveredDevice.manual(ipAddress, name: name);
    addDiscoveredDevice(device);
    return device;
  }

  /// Validate IP address format
  bool _isValidIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }

    return true;
  }

  /// Stop ongoing discovery
  void stopDiscovery() {
    if (_state == DiscoveryState.scanning) {
      _cancelTimeoutTimer();
      _state = _devices.isEmpty
          ? DiscoveryState.noDevicesFound
          : DiscoveryState.completed;
      debugPrint('[Discovery] Scan stopped manually');
      notifyListeners();
    }
  }

  /// Clear discovered devices and reset state
  void clearDevices() {
    _devices.clear();
    _state = DiscoveryState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  void _startTimeoutTimer() {
    _cancelTimeoutTimer();
    _timeoutTimer = Timer(discoveryTimeout, () {
      if (_state == DiscoveryState.scanning) {
        stopDiscovery();
      }
    });
  }

  void _cancelTimeoutTimer() {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
  }

  @override
  void dispose() {
    _cancelTimeoutTimer();
    _deviceStreamController.close();
    super.dispose();
  }
}

/// Discovery state
enum DiscoveryState {
  idle,
  scanning,
  completed,
  noDevicesFound,
  error,
}

/// Extension for human-readable state names
extension DiscoveryStateExtension on DiscoveryState {
  String get displayName {
    switch (this) {
      case DiscoveryState.idle:
        return 'Ready to scan';
      case DiscoveryState.scanning:
        return 'Scanning...';
      case DiscoveryState.completed:
        return 'Scan complete';
      case DiscoveryState.noDevicesFound:
        return 'No cameras found';
      case DiscoveryState.error:
        return 'Scan failed';
    }
  }

  bool get isScanning => this == DiscoveryState.scanning;
  bool get hasDevices => this == DiscoveryState.completed;
  bool get isEmpty => this == DiscoveryState.noDevicesFound;
  bool get isError => this == DiscoveryState.error;
}
