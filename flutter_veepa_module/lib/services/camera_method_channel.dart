import 'package:flutter/services.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_ptz_service.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/models/ptz_direction.dart';

/// Method channel for handling Swift → Dart calls
class CameraMethodChannel {
  static const _channel = MethodChannel('com.veepapoc/camera');
  static bool _isSetup = false;

  /// Set up the method channel handler
  static void setup() {
    if (_isSetup) return;
    _channel.setMethodCallHandler(_handleMethodCall);
    _isSetup = true;
    print('[CameraMethodChannel] Setup complete');
  }

  /// Handle incoming method calls from Swift
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('[CameraMethodChannel] Received method: ${call.method}');

    switch (call.method) {
      case 'connect':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final deviceId = args?['deviceId'] as String?;
        if (deviceId == null) {
          throw PlatformException(
            code: 'INVALID_ARGUMENT',
            message: 'deviceId is required',
          );
        }
        return await _handleConnect(deviceId);

      case 'disconnect':
        return await _handleDisconnect();

      case 'setPTZ':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final direction = args?['direction'] as String?;
        final speed = args?['speed'] as int?;
        if (direction == null || speed == null) {
          throw PlatformException(
            code: 'INVALID_ARGUMENT',
            message: 'direction and speed are required',
          );
        }
        return await _handleSetPTZ(direction, speed);

      case 'setZoom':
        final args = call.arguments as Map<dynamic, dynamic>?;
        final direction = args?['direction'] as String?;
        final speed = args?['speed'] as int?;
        if (direction == null || speed == null) {
          throw PlatformException(
            code: 'INVALID_ARGUMENT',
            message: 'direction and speed are required',
          );
        }
        return await _handleSetZoom(direction, speed);

      case 'getConnectionStatus':
        return _handleGetConnectionStatus();

      default:
        throw PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Handle connect request
  static Future<void> _handleConnect(String deviceId) async {
    print('[CameraMethodChannel] Connecting to device: $deviceId');
    final connectionManager = VeepaConnectionManager();
    final device = DiscoveredDevice(
      deviceId: deviceId,
      name: 'External Camera',
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );
    await connectionManager.connect(device);
    print('[CameraMethodChannel] Connected to device: $deviceId');
  }

  /// Handle disconnect request
  static Future<void> _handleDisconnect() async {
    print('[CameraMethodChannel] Disconnecting');
    await VeepaConnectionManager().disconnect();
    print('[CameraMethodChannel] Disconnected');
  }

  /// Handle PTZ control request
  static Future<void> _handleSetPTZ(String direction, int speed) async {
    print('[CameraMethodChannel] Setting PTZ: $direction at speed $speed');
    final ptzService = VeepaPTZService();
    ptzService.speed = speed;

    final ptzDirection = PTZDirection.values.firstWhere(
      (d) => d.name == direction,
      orElse: () => PTZDirection.stop,
    );

    if (ptzDirection == PTZDirection.stop) {
      await ptzService.stopMovement();
    } else {
      await ptzService.startMovement(ptzDirection);
    }
    print('[CameraMethodChannel] PTZ set complete');
  }

  /// Handle zoom control request
  static Future<void> _handleSetZoom(String direction, int speed) async {
    print('[CameraMethodChannel] Setting Zoom: $direction at speed $speed');
    final ptzService = VeepaPTZService();
    ptzService.speed = speed;

    final zoomDirection = ZoomDirection.values.firstWhere(
      (d) => d.name == direction,
      orElse: () => ZoomDirection.stop,
    );

    if (zoomDirection == ZoomDirection.stop) {
      await ptzService.stopZoom();
    } else {
      await ptzService.startZoom(zoomDirection);
    }
    print('[CameraMethodChannel] Zoom set complete');
  }

  /// Get current connection status
  static Map<String, dynamic> _handleGetConnectionStatus() {
    final connectionManager = VeepaConnectionManager();
    return {
      'isConnected': connectionManager.state.name == 'connected',
      'state': connectionManager.state.name,
      'deviceId': connectionManager.connectedDevice?.deviceId,
      'deviceName': connectionManager.connectedDevice?.name,
    };
  }
}
