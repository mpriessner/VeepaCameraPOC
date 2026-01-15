import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';

/// State of the camera detection process
enum DetectionState {
  /// Not currently detecting
  idle,

  /// Actively polling for camera
  detecting,

  /// Camera was found and connected
  found,

  /// Detection timed out without finding camera
  timeout,

  /// An error occurred during detection
  error,
}

/// Result of a camera detection attempt
class DetectionResult {
  /// Whether the camera was found
  final bool success;

  /// IP address of the camera (if found via LAN)
  final String? ipAddress;

  /// Time taken to detect the camera
  final Duration? connectionTime;

  /// Error message if detection failed
  final String? errorMessage;

  /// Number of attempts made before result
  final int attemptCount;

  const DetectionResult({
    required this.success,
    this.ipAddress,
    this.connectionTime,
    this.errorMessage,
    this.attemptCount = 0,
  });

  factory DetectionResult.success({
    String? ipAddress,
    Duration? connectionTime,
    int attemptCount = 0,
  }) {
    return DetectionResult(
      success: true,
      ipAddress: ipAddress,
      connectionTime: connectionTime,
      attemptCount: attemptCount,
    );
  }

  factory DetectionResult.failure({
    required String errorMessage,
    int attemptCount = 0,
  }) {
    return DetectionResult(
      success: false,
      errorMessage: errorMessage,
      attemptCount: attemptCount,
    );
  }

  factory DetectionResult.timeout({int attemptCount = 0}) {
    return DetectionResult(
      success: false,
      errorMessage: 'Detection timed out',
      attemptCount: attemptCount,
    );
  }
}

/// Interface for connection manager to support testing
abstract class IConnectionManager {
  ConnectionState get state;
  bool get isConnected;
  Future<bool> connect(DiscoveredDevice device);
  Future<void> disconnect();
}

/// Default implementation wrapping VeepaConnectionManager
class DefaultConnectionManager implements IConnectionManager {
  final VeepaConnectionManager _manager = VeepaConnectionManager();

  @override
  ConnectionState get state => _manager.state;

  @override
  bool get isConnected => _manager.state == ConnectionState.connected;

  @override
  Future<bool> connect(DiscoveredDevice device) => _manager.connect(device);

  @override
  Future<void> disconnect() => _manager.disconnect();
}

/// Service that detects when a camera has connected to the home network
/// after WiFi provisioning.
///
/// The detector polls for the camera using P2P connection attempts
/// and notifies when the camera is found or when timeout is reached.
class CameraConnectionDetector extends ChangeNotifier {
  final IConnectionManager _connectionManager;

  DetectionState _state = DetectionState.idle;
  int _attemptCount = 0;
  int _maxAttempts = 20;
  DateTime? _startTime;
  Timer? _pollTimer;
  Completer<DetectionResult>? _completer;
  bool _cancelled = false;

  CameraConnectionDetector({
    IConnectionManager? connectionManager,
  }) : _connectionManager = connectionManager ?? DefaultConnectionManager();

  /// Current detection state
  DetectionState get state => _state;

  /// Number of connection attempts made
  int get attemptCount => _attemptCount;

  /// Maximum number of attempts before timeout
  int get maxAttempts => _maxAttempts;

  /// Whether detection is currently in progress
  bool get isDetecting => _state == DetectionState.detecting;

  /// Detection progress as a value between 0.0 and 1.0
  double get progress {
    if (_maxAttempts == 0) return 0.0;
    return (_attemptCount / _maxAttempts).clamp(0.0, 1.0);
  }

  /// Start detecting camera on the home network
  ///
  /// [deviceId] - The camera's device ID
  /// [password] - The camera's password (currently unused, reserved for future)
  /// [timeout] - Maximum time to wait for camera (default: 60 seconds)
  /// [pollInterval] - Time between detection attempts (default: 3 seconds)
  ///
  /// Returns a [DetectionResult] when camera is found or timeout is reached.
  Future<DetectionResult> startDetection({
    required String deviceId,
    required String password,
    Duration timeout = const Duration(seconds: 60),
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    if (_state == DetectionState.detecting) {
      return DetectionResult.failure(
        errorMessage: 'Detection already in progress',
        attemptCount: _attemptCount,
      );
    }

    _reset();
    _state = DetectionState.detecting;
    _startTime = DateTime.now();
    _maxAttempts = (timeout.inMilliseconds / pollInterval.inMilliseconds).ceil();
    _cancelled = false;
    _completer = Completer<DetectionResult>();

    notifyListeners();

    // Create a device to connect to
    final device = DiscoveredDevice(
      deviceId: deviceId,
      name: 'Detected Camera',
      ipAddress: '192.168.1.100', // Will be discovered via P2P
      discoveryMethod: DiscoveryMethod.cloudLookup,
      discoveredAt: DateTime.now(),
    );

    // Start polling timer
    _pollTimer = Timer.periodic(pollInterval, (timer) async {
      if (_cancelled) {
        timer.cancel();
        return;
      }

      _attemptCount++;
      notifyListeners();

      debugPrint('[CameraDetector] Attempt $_attemptCount/$_maxAttempts');

      // Try to connect to the camera
      final success = await _tryConnect(device);

      if (success) {
        timer.cancel();
        _handleSuccess();
        return;
      }

      // Check if we've exceeded max attempts
      if (_attemptCount >= _maxAttempts) {
        timer.cancel();
        _handleTimeout();
        return;
      }
    });

    return _completer!.future;
  }

  /// Cancel the ongoing detection
  void cancelDetection() {
    if (_state != DetectionState.detecting) return;

    _cancelled = true;
    _pollTimer?.cancel();
    _state = DetectionState.idle;

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(DetectionResult.failure(
        errorMessage: 'Detection cancelled',
        attemptCount: _attemptCount,
      ));
    }

    notifyListeners();
  }

  /// Try to connect to the camera
  Future<bool> _tryConnect(DiscoveredDevice device) async {
    try {
      // Disconnect any existing connection first
      if (_connectionManager.isConnected) {
        await _connectionManager.disconnect();
      }

      // Attempt P2P connection
      final success = await _connectionManager.connect(device);
      return success;
    } catch (e) {
      debugPrint('[CameraDetector] Connection attempt failed: $e');
      return false;
    }
  }

  void _handleSuccess() {
    final connectionTime =
        _startTime != null ? DateTime.now().difference(_startTime!) : null;

    _state = DetectionState.found;
    notifyListeners();

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(DetectionResult.success(
        connectionTime: connectionTime,
        attemptCount: _attemptCount,
      ));
    }

    debugPrint('[CameraDetector] Camera found after $_attemptCount attempts');
  }

  void _handleTimeout() {
    _state = DetectionState.timeout;
    notifyListeners();

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(DetectionResult.timeout(
        attemptCount: _attemptCount,
      ));
    }

    debugPrint('[CameraDetector] Detection timed out after $_attemptCount attempts');
  }

  void _reset() {
    _pollTimer?.cancel();
    _state = DetectionState.idle;
    _attemptCount = 0;
    _startTime = null;
    _completer = null;
    _cancelled = false;
  }

  /// Reset the detector to idle state
  void reset() {
    cancelDetection();
    _reset();
    notifyListeners();
  }

  @override
  void dispose() {
    cancelDetection();
    super.dispose();
  }
}
