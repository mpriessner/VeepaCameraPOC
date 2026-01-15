import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Result of a camera configuration operation
class ConfigResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  const ConfigResult({
    required this.success,
    this.message,
    this.data,
  });

  factory ConfigResult.success([String? message, Map<String, dynamic>? data]) {
    return ConfigResult(success: true, message: message, data: data);
  }

  factory ConfigResult.failure(String message) {
    return ConfigResult(success: false, message: message);
  }
}

/// WiFi encryption types
enum WifiEncryption {
  none,
  wep,
  wpa,
  wpa2,
  wpa3,
}

/// Service for configuring camera settings via CGI commands
class CameraConfigService {
  final String _baseUrl;
  final Dio _dio;
  final String _username;
  final String _password;

  CameraConfigService({
    required String cameraIP,
    String username = 'admin',
    String password = 'admin',
    int port = 80,
  })  : _baseUrl = 'http://$cameraIP:$port',
        _username = username,
        _password = password,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));

  /// Configure camera to connect to a WiFi network
  Future<ConfigResult> setWifiConfig({
    required String ssid,
    required String password,
    WifiEncryption encryption = WifiEncryption.wpa2,
  }) async {
    try {
      debugPrint('[CameraConfig] Setting WiFi: $ssid');

      final encType = _encryptionToString(encryption);

      final response = await _sendCgiCommand(
        'set_wifi.cgi',
        params: {
          'ssid': ssid,
          'password': password,
          'enctype': encType,
        },
      );

      if (response.statusCode == 200) {
        return ConfigResult.success('WiFi configuration sent');
      } else {
        return ConfigResult.failure('Failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[CameraConfig] WiFi config error: ${e.message}');
      return ConfigResult.failure('Network error: ${e.message}');
    } catch (e) {
      debugPrint('[CameraConfig] WiFi config error: $e');
      return ConfigResult.failure('Error: $e');
    }
  }

  /// Get current WiFi status from camera
  Future<ConfigResult> getWifiStatus() async {
    try {
      final response = await _sendCgiCommand('get_wifi_status.cgi');

      if (response.statusCode == 200) {
        // Parse response (format varies by camera model)
        return ConfigResult.success(
          'WiFi status retrieved',
          {'raw': response.data},
        );
      } else {
        return ConfigResult.failure('Failed: ${response.statusCode}');
      }
    } catch (e) {
      return ConfigResult.failure('Error: $e');
    }
  }

  /// Reboot the camera
  Future<ConfigResult> rebootCamera() async {
    try {
      debugPrint('[CameraConfig] Rebooting camera');

      final response = await _sendCgiCommand('reboot.cgi');

      if (response.statusCode == 200) {
        return ConfigResult.success('Reboot command sent');
      } else {
        return ConfigResult.failure('Failed: ${response.statusCode}');
      }
    } catch (e) {
      return ConfigResult.failure('Error: $e');
    }
  }

  /// Get camera device info
  Future<ConfigResult> getDeviceInfo() async {
    try {
      final response = await _sendCgiCommand('get_status.cgi');

      if (response.statusCode == 200) {
        return ConfigResult.success(
          'Device info retrieved',
          {'raw': response.data},
        );
      } else {
        return ConfigResult.failure('Failed: ${response.statusCode}');
      }
    } catch (e) {
      return ConfigResult.failure('Error: $e');
    }
  }

  /// Send a CGI command to the camera
  Future<Response> _sendCgiCommand(
    String command, {
    Map<String, dynamic>? params,
  }) async {
    final url = '$_baseUrl/$command';

    final queryParams = <String, dynamic>{
      'loginuser': _username,
      'loginpass': _password,
      ...?params,
    };

    debugPrint('[CameraConfig] Sending: $url');

    return await _dio.get(
      url,
      queryParameters: queryParams,
    );
  }

  String _encryptionToString(WifiEncryption enc) {
    switch (enc) {
      case WifiEncryption.none:
        return 'OPEN';
      case WifiEncryption.wep:
        return 'WEP';
      case WifiEncryption.wpa:
        return 'WPA';
      case WifiEncryption.wpa2:
        return 'WPA2';
      case WifiEncryption.wpa3:
        return 'WPA3';
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}

/// Factory for creating CameraConfigService instances
class CameraConfigServiceFactory {
  /// Create a service for a camera in AP mode (default IP)
  static CameraConfigService forAPMode({
    String ip = '192.168.1.1',
    String username = 'admin',
    String password = 'admin',
  }) {
    return CameraConfigService(
      cameraIP: ip,
      username: username,
      password: password,
    );
  }

  /// Create a service for a camera on the local network
  static CameraConfigService forLAN({
    required String ip,
    String username = 'admin',
    String password = 'admin',
  }) {
    return CameraConfigService(
      cameraIP: ip,
      username: username,
      password: password,
    );
  }
}
