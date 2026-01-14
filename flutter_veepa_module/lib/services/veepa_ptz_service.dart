import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:veepa_camera_poc/models/ptz_direction.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';

/// PTZ (Pan-Tilt-Zoom) control service for Veepa cameras
///
/// Provides camera movement control including pan, tilt, and zoom
/// with speed control and latency tracking for diagnostics.
class VeepaPTZService extends ChangeNotifier {
  static final VeepaPTZService _instance = VeepaPTZService._internal();
  factory VeepaPTZService() => _instance;
  VeepaPTZService._internal();

  /// Configuration
  static const int defaultSpeed = 50; // 0-100 scale
  static const int minSpeed = 0;
  static const int maxSpeed = 100;

  /// Connection manager reference
  final VeepaConnectionManager _connectionManager = VeepaConnectionManager();

  /// Current movement state
  PTZDirection _currentDirection = PTZDirection.stop;
  PTZDirection get currentDirection => _currentDirection;

  ZoomDirection _currentZoom = ZoomDirection.stop;
  ZoomDirection get currentZoom => _currentZoom;

  /// Movement speed (0-100)
  int _speed = defaultSpeed;
  int get speed => _speed;
  set speed(int value) {
    _speed = value.clamp(minSpeed, maxSpeed);
    notifyListeners();
  }

  /// Command latency tracking
  final List<int> _latencyHistory = [];

  /// Maximum latency history size
  static const int _maxLatencyHistory = 20;

  /// High latency threshold for warnings (ms)
  static const int highLatencyThreshold = 500;

  /// Get average latency in milliseconds
  double get averageLatency {
    if (_latencyHistory.isEmpty) return 0;
    return _latencyHistory.reduce((a, b) => a + b) / _latencyHistory.length;
  }

  /// Get last recorded latency
  int? get lastLatency =>
      _latencyHistory.isNotEmpty ? _latencyHistory.last : null;

  /// Get number of latency samples
  int get latencySampleCount => _latencyHistory.length;

  /// Whether currently moving
  bool get isMoving => _currentDirection != PTZDirection.stop;

  /// Whether currently zooming
  bool get isZooming => _currentZoom != ZoomDirection.stop;

  /// Start PTZ movement in specified direction
  ///
  /// Returns true if command was sent successfully
  Future<bool> startMovement(PTZDirection direction) async {
    if (!_canSendCommand()) {
      debugPrint('[PTZ] Cannot send command - not connected');
      return false;
    }

    if (_currentDirection == direction) {
      debugPrint('[PTZ] Already moving: ${direction.displayName}');
      return true;
    }

    _currentDirection = direction;
    notifyListeners();

    return _sendPTZCommand(direction);
  }

  /// Stop PTZ movement
  Future<bool> stopMovement() async {
    if (_currentDirection == PTZDirection.stop) {
      return true;
    }

    _currentDirection = PTZDirection.stop;
    notifyListeners();

    return _sendPTZCommand(PTZDirection.stop);
  }

  /// Start zoom in specified direction
  Future<bool> startZoom(ZoomDirection direction) async {
    if (!_canSendCommand()) {
      debugPrint('[PTZ] Cannot send zoom - not connected');
      return false;
    }

    if (_currentZoom == direction) {
      debugPrint('[PTZ] Already zooming: ${direction.displayName}');
      return true;
    }

    _currentZoom = direction;
    notifyListeners();

    return _sendZoomCommand(direction);
  }

  /// Stop zoom
  Future<bool> stopZoom() async {
    if (_currentZoom == ZoomDirection.stop) {
      return true;
    }

    _currentZoom = ZoomDirection.stop;
    notifyListeners();

    return _sendZoomCommand(ZoomDirection.stop);
  }

  /// Stop all movement and zoom
  Future<void> stopAll() async {
    await stopMovement();
    await stopZoom();
  }

  /// Convenience methods for common movements
  Future<bool> panLeft() => startMovement(PTZDirection.panLeft);
  Future<bool> panRight() => startMovement(PTZDirection.panRight);
  Future<bool> tiltUp() => startMovement(PTZDirection.tiltUp);
  Future<bool> tiltDown() => startMovement(PTZDirection.tiltDown);
  Future<bool> zoomIn() => startZoom(ZoomDirection.zoomIn);
  Future<bool> zoomOut() => startZoom(ZoomDirection.zoomOut);

  /// Check if can send commands (connected to camera)
  bool _canSendCommand() {
    return _connectionManager.state.isConnected;
  }

  /// Send PTZ command to camera
  Future<bool> _sendPTZCommand(PTZDirection direction) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('[PTZ] Sending: ${direction.displayName} (code: ${direction.commandCode}, speed: $_speed)');

      // POC: Simulated command with delay
      // In production, replace with actual SDK motor command:
      // await _connectionManager.connectedDevice?.sendMotorCommand(
      //   command: direction.commandCode,
      //   speed: _speed,
      // );
      await Future.delayed(const Duration(milliseconds: 20));

      stopwatch.stop();
      _recordLatency(stopwatch.elapsedMilliseconds);

      debugPrint('[PTZ] Command sent in ${stopwatch.elapsedMilliseconds}ms');
      return true;
    } catch (e) {
      debugPrint('[PTZ] Command failed: $e');
      return false;
    }
  }

  /// Send zoom command to camera
  Future<bool> _sendZoomCommand(ZoomDirection direction) async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('[PTZ] Zoom: ${direction.displayName} (code: ${direction.commandCode})');

      // POC: Simulated command
      await Future.delayed(const Duration(milliseconds: 20));

      stopwatch.stop();
      _recordLatency(stopwatch.elapsedMilliseconds);

      debugPrint('[PTZ] Zoom sent in ${stopwatch.elapsedMilliseconds}ms');
      return true;
    } catch (e) {
      debugPrint('[PTZ] Zoom failed: $e');
      return false;
    }
  }

  /// Record command latency
  void _recordLatency(int ms) {
    _latencyHistory.add(ms);

    // Keep only the most recent measurements
    if (_latencyHistory.length > _maxLatencyHistory) {
      _latencyHistory.removeAt(0);
    }

    // Warn if latency is high
    if (ms > highLatencyThreshold) {
      debugPrint('[PTZ] Warning: High latency ${ms}ms');
    }
  }

  /// Go to preset position (if supported by camera)
  Future<bool> goToPreset(int presetNumber) async {
    if (!_canSendCommand()) {
      debugPrint('[PTZ] Cannot go to preset - not connected');
      return false;
    }
    if (presetNumber < 1 || presetNumber > 255) {
      debugPrint('[PTZ] Invalid preset number: $presetNumber');
      return false;
    }

    debugPrint('[PTZ] Going to preset $presetNumber');

    // POC: Simulated - actual implementation depends on SDK
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  /// Save current position as preset
  Future<bool> savePreset(int presetNumber) async {
    if (!_canSendCommand()) {
      debugPrint('[PTZ] Cannot save preset - not connected');
      return false;
    }
    if (presetNumber < 1 || presetNumber > 255) {
      debugPrint('[PTZ] Invalid preset number: $presetNumber');
      return false;
    }

    debugPrint('[PTZ] Saving preset $presetNumber');

    // POC: Simulated
    await Future.delayed(const Duration(milliseconds: 50));
    return true;
  }

  /// Reset latency history
  void resetLatencyHistory() {
    _latencyHistory.clear();
    notifyListeners();
  }

  /// Get PTZ state statistics
  Map<String, dynamic> getStatistics() {
    return {
      'currentDirection': _currentDirection.displayName,
      'currentZoom': _currentZoom.displayName,
      'speed': _speed,
      'isMoving': isMoving,
      'isZooming': isZooming,
      'averageLatency': averageLatency,
      'lastLatency': lastLatency,
      'latencySamples': latencySampleCount,
    };
  }

  /// Reset service state
  void reset() {
    _currentDirection = PTZDirection.stop;
    _currentZoom = ZoomDirection.stop;
    _speed = defaultSpeed;
    _latencyHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    stopAll();
    super.dispose();
  }
}
