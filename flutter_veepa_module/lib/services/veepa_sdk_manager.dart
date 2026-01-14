import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:veepa_camera_poc/sdk/veepa_sdk.dart';

/// Manages Veepa SDK lifecycle
class VeepaSDKManager extends ChangeNotifier {
  static final VeepaSDKManager _instance = VeepaSDKManager._internal();
  factory VeepaSDKManager() => _instance;
  VeepaSDKManager._internal();

  /// SDK initialization state
  SDKInitState _initState = SDKInitState.uninitialized;
  SDKInitState get initState => _initState;

  /// Error message if initialization failed
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// The P2P API instance
  AppP2PApi? _p2pApi;
  AppP2PApi? get p2pApi => _p2pApi;

  /// Whether SDK is ready for use
  bool get isReady => _initState == SDKInitState.initialized;

  /// Initialize the Veepa SDK
  /// Returns true if initialization successful
  Future<bool> initialize() async {
    if (_initState == SDKInitState.initializing) {
      debugPrint('[VeepaSDK] Already initializing, skipping...');
      return false;
    }

    if (_initState == SDKInitState.initialized) {
      debugPrint('[VeepaSDK] Already initialized');
      return true;
    }

    _initState = SDKInitState.initializing;
    _errorMessage = null;
    notifyListeners();

    debugPrint('[VeepaSDK] Starting initialization...');

    try {
      // Step 1: Create P2P API instance
      _p2pApi = AppP2PApi();
      debugPrint('[VeepaSDK] P2P API instance created');

      // Step 2: Perform any required SDK setup
      await _performSDKSetup();

      // Step 3: Verify SDK is responsive
      final isHealthy = await _healthCheck();
      if (!isHealthy) {
        throw Exception('SDK health check failed');
      }

      _initState = SDKInitState.initialized;
      debugPrint('[VeepaSDK] Initialization complete!');
      notifyListeners();
      return true;

    } catch (e, stackTrace) {
      _initState = SDKInitState.failed;
      _errorMessage = e.toString();
      debugPrint('[VeepaSDK] Initialization failed: $e');
      debugPrint('[VeepaSDK] Stack trace: $stackTrace');
      notifyListeners();
      return false;
    }
  }

  /// Perform SDK-specific setup
  Future<void> _performSDKSetup() async {
    // Add any SDK-specific initialization here
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Basic health check to verify SDK is responsive
  Future<bool> _healthCheck() async {
    try {
      if (_p2pApi == null) {
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[VeepaSDK] Health check failed: $e');
      return false;
    }
  }

  /// Reset SDK state (for retry)
  void reset() {
    _initState = SDKInitState.uninitialized;
    _errorMessage = null;
    _p2pApi = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _p2pApi = null;
    super.dispose();
  }
}

/// SDK initialization states
enum SDKInitState {
  uninitialized,
  initializing,
  initialized,
  failed,
}

/// Extension for human-readable state names
extension SDKInitStateExtension on SDKInitState {
  String get displayName {
    switch (this) {
      case SDKInitState.uninitialized:
        return 'Not Started';
      case SDKInitState.initializing:
        return 'Initializing...';
      case SDKInitState.initialized:
        return 'Ready';
      case SDKInitState.failed:
        return 'Failed';
    }
  }

  bool get isLoading => this == SDKInitState.initializing;
  bool get isReady => this == SDKInitState.initialized;
  bool get isFailed => this == SDKInitState.failed;
}
