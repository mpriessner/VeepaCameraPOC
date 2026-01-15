import 'dart:async';
import 'package:flutter/foundation.dart';
import 'real_connection_adapter.dart';

/// PTZ direction commands
enum PTZDirection {
  stop,
  up,
  down,
  left,
  right,
  upLeft,
  upRight,
  downLeft,
  downRight,
}

/// Zoom commands
enum ZoomDirection {
  stop,
  zoomIn,
  zoomOut,
}

/// PTZ command codes (standard ONVIF/VSTC codes)
class PTZCodes {
  static const int stop = 0;
  static const int up = 1;
  static const int down = 2;
  static const int left = 4;
  static const int right = 8;
  static const int upLeft = 5;
  static const int upRight = 9;
  static const int downLeft = 6;
  static const int downRight = 10;
  static const int zoomIn = 16;
  static const int zoomOut = 32;

  static int fromDirection(PTZDirection dir) {
    switch (dir) {
      case PTZDirection.stop:
        return stop;
      case PTZDirection.up:
        return up;
      case PTZDirection.down:
        return down;
      case PTZDirection.left:
        return left;
      case PTZDirection.right:
        return right;
      case PTZDirection.upLeft:
        return upLeft;
      case PTZDirection.upRight:
        return upRight;
      case PTZDirection.downLeft:
        return downLeft;
      case PTZDirection.downRight:
        return downRight;
    }
  }

  static int fromZoom(ZoomDirection zoom) {
    switch (zoom) {
      case ZoomDirection.stop:
        return stop;
      case ZoomDirection.zoomIn:
        return zoomIn;
      case ZoomDirection.zoomOut:
        return zoomOut;
    }
  }
}

/// Adapter for real PTZ control using the SDK
class RealPTZAdapter extends ChangeNotifier {
  final RealConnectionAdapter _connection;

  PTZDirection _currentDirection = PTZDirection.stop;
  ZoomDirection _currentZoom = ZoomDirection.stop;
  int _speed = 50; // 0-100
  bool _isMoving = false;

  // Statistics
  int _commandsSent = 0;
  DateTime? _lastCommandTime;

  RealPTZAdapter({required RealConnectionAdapter connection})
      : _connection = connection;

  /// Current movement direction
  PTZDirection get currentDirection => _currentDirection;

  /// Current zoom direction
  ZoomDirection get currentZoom => _currentZoom;

  /// Whether PTZ is currently moving
  bool get isMoving => _isMoving;

  /// Current speed (0-100)
  int get speed => _speed;

  /// Commands sent count
  int get commandsSent => _commandsSent;

  /// Set PTZ speed
  void setSpeed(int newSpeed) {
    _speed = newSpeed.clamp(0, 100);
    notifyListeners();
  }

  /// Move in a direction
  Future<bool> move(PTZDirection direction) async {
    if (!_connection.isConnected) {
      debugPrint('[RealPTZ] Cannot move - not connected');
      return false;
    }

    final code = PTZCodes.fromDirection(direction);
    debugPrint('[RealPTZ] Moving: $direction (code: $code, speed: $_speed)');

    final result = await _connection.sendPTZCommand(code, _speed);

    if (result) {
      _currentDirection = direction;
      _isMoving = direction != PTZDirection.stop;
      _commandsSent++;
      _lastCommandTime = DateTime.now();
      notifyListeners();
    }

    return result;
  }

  /// Stop movement
  Future<bool> stop() async {
    return await move(PTZDirection.stop);
  }

  /// Zoom in a direction
  Future<bool> zoom(ZoomDirection direction) async {
    if (!_connection.isConnected) {
      debugPrint('[RealPTZ] Cannot zoom - not connected');
      return false;
    }

    final code = PTZCodes.fromZoom(direction);
    debugPrint('[RealPTZ] Zoom: $direction (code: $code)');

    final result = await _connection.sendPTZCommand(code, _speed);

    if (result) {
      _currentZoom = direction;
      _commandsSent++;
      _lastCommandTime = DateTime.now();
      notifyListeners();
    }

    return result;
  }

  /// Stop zoom
  Future<bool> stopZoom() async {
    return await zoom(ZoomDirection.stop);
  }

  /// Go to preset position
  Future<bool> goToPreset(int presetId) async {
    if (!_connection.isConnected) {
      debugPrint('[RealPTZ] Cannot go to preset - not connected');
      return false;
    }

    // Preset commands use a different code scheme
    // Code 64 + preset number (in real SDK)
    final code = 64 + presetId;
    debugPrint('[RealPTZ] Going to preset $presetId (code: $code)');

    return await _connection.sendPTZCommand(code, _speed);
  }

  /// Save current position as preset
  Future<bool> savePreset(int presetId) async {
    if (!_connection.isConnected) {
      debugPrint('[RealPTZ] Cannot save preset - not connected');
      return false;
    }

    // Save preset commands use code 128 + preset number (in real SDK)
    final code = 128 + presetId;
    debugPrint('[RealPTZ] Saving preset $presetId (code: $code)');

    return await _connection.sendPTZCommand(code, _speed);
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    return {
      'commandsSent': _commandsSent,
      'lastCommandTime': _lastCommandTime?.toIso8601String(),
      'currentDirection': _currentDirection.name,
      'currentZoom': _currentZoom.name,
      'speed': _speed,
      'isMoving': _isMoving,
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _commandsSent = 0;
    _lastCommandTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Send stop commands without notifying (already disposing)
    if (_connection.isConnected) {
      _connection.sendPTZCommand(PTZCodes.stop, _speed);
    }
    super.dispose();
  }
}
