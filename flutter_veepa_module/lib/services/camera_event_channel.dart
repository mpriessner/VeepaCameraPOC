import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_player_service.dart';

/// Event channel for sending events from Dart to Swift
/// Uses MethodChannel since EventChannel is native → Dart only
class CameraEventChannel {
  static const _methodChannel = MethodChannel('com.veepapoc/camera_events_out');
  static StreamSubscription? _connectionSubscription;
  static StreamSubscription? _playerSubscription;
  static bool _isSetup = false;

  /// Set up the event channel and start listening to services
  static void setup() {
    if (_isSetup) return;

    _isSetup = true;
    debugPrint('[CameraEventChannel] Setup complete');

    // Listen to connection manager state changes
    _connectionSubscription = VeepaConnectionManager().stateStream.listen(
      (state) {
        _sendEvent({
          'type': 'connectionState',
          'state': state.name,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      },
      onError: (error) {
        sendError('Connection stream error: $error');
      },
    );

    // Listen to player service state changes
    _playerSubscription = VeepaPlayerService().stateStream.listen(
      (state) {
        _sendEvent({
          'type': 'playerState',
          'state': state.name,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      },
      onError: (error) {
        sendError('Player stream error: $error');
      },
    );
  }

  /// Send an event to the native side
  static Future<void> _sendEvent(Map<String, dynamic> event) async {
    try {
      await _methodChannel.invokeMethod('sendEvent', event);
      debugPrint('[CameraEventChannel] Sent event: ${event['type']}');
    } catch (e) {
      // Log but don't crash - native side might not be listening yet
      debugPrint('[CameraEventChannel] Failed to send event: $e');
    }
  }

  /// Send frame rate update to native
  static void sendFrameRate(double fps) {
    _sendEvent({
      'type': 'frameRate',
      'fps': fps,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send error notification to native
  static void sendError(String error) {
    _sendEvent({
      'type': 'error',
      'message': error,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send PTZ state update to native
  static void sendPTZState(String direction, int speed, bool isMoving) {
    _sendEvent({
      'type': 'ptzState',
      'direction': direction,
      'speed': speed,
      'isMoving': isMoving,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Send device info to native
  static void sendDeviceInfo(String deviceId, String deviceName, String? ipAddress) {
    _sendEvent({
      'type': 'deviceInfo',
      'deviceId': deviceId,
      'deviceName': deviceName,
      'ipAddress': ipAddress,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Clean up resources
  static void dispose() {
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _playerSubscription?.cancel();
    _playerSubscription = null;
    _isSetup = false;
    debugPrint('[CameraEventChannel] Disposed');
  }
}
