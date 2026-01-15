import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

/// Result of camera discovery
class CameraDiscoveryResult {
  final bool found;
  final String? ip;
  final String? deviceId;
  final String? errorMessage;

  const CameraDiscoveryResult({
    required this.found,
    this.ip,
    this.deviceId,
    this.errorMessage,
  });

  factory CameraDiscoveryResult.success(String ip, {String? deviceId}) {
    return CameraDiscoveryResult(found: true, ip: ip, deviceId: deviceId);
  }

  factory CameraDiscoveryResult.notFound() {
    return const CameraDiscoveryResult(found: false);
  }

  factory CameraDiscoveryResult.error(String message) {
    return CameraDiscoveryResult(found: false, errorMessage: message);
  }
}

/// Service for detecting camera on local network after WiFi provisioning
class CameraReconnectionService {
  final Dio _dio;
  final String _deviceId;
  final Duration pollInterval;
  final Duration timeout;
  final List<String> searchRanges;

  Timer? _pollTimer;
  Timer? _timeoutTimer;
  Completer<CameraDiscoveryResult>? _completer;
  bool _isSearching = false;

  CameraReconnectionService({
    required String deviceId,
    this.pollInterval = const Duration(seconds: 3),
    this.timeout = const Duration(minutes: 3),
    this.searchRanges = const ['192.168.1', '192.168.0', '10.0.0'],
  })  : _deviceId = deviceId,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ));

  /// Whether currently searching for camera
  bool get isSearching => _isSearching;

  /// Start searching for the camera on the local network
  Future<CameraDiscoveryResult> startSearch() async {
    if (_completer != null && !_completer!.isCompleted) {
      return _completer!.future;
    }

    _completer = Completer<CameraDiscoveryResult>();
    _isSearching = true;

    debugPrint('[Reconnection] Starting search for device: $_deviceId');

    // Start polling
    _pollTimer = Timer.periodic(pollInterval, (_) => _searchNetwork());

    // Start timeout timer
    _timeoutTimer = Timer(timeout, _onTimeout);

    // Do initial search
    _searchNetwork();

    return _completer!.future;
  }

  /// Stop searching
  void stopSearch() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _isSearching = false;

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(CameraDiscoveryResult.notFound());
    }
  }

  /// Search for camera at a known IP address
  Future<CameraDiscoveryResult> searchAtIP(String ip) async {
    debugPrint('[Reconnection] Checking IP: $ip');

    try {
      final response = await _dio.get(
        'http://$ip/get_status.cgi',
        queryParameters: {
          'loginuser': 'admin',
          'loginpass': 'admin',
        },
      );

      if (response.statusCode == 200) {
        // Check if this is our camera by device ID (if available in response)
        final data = response.data.toString();
        if (data.contains(_deviceId) || _deviceId.isEmpty) {
          debugPrint('[Reconnection] Found camera at $ip');
          return CameraDiscoveryResult.success(ip, deviceId: _deviceId);
        }
      }
    } on DioException catch (e) {
      debugPrint('[Reconnection] IP $ip not responding: ${e.message}');
    } catch (e) {
      debugPrint('[Reconnection] Error checking $ip: $e');
    }

    return CameraDiscoveryResult.notFound();
  }

  Future<void> _searchNetwork() async {
    if (!_isSearching) return;

    debugPrint('[Reconnection] Scanning network...');

    // Search common IP ranges for cameras
    for (final range in searchRanges) {
      // Scan common camera IPs (typically assigned by DHCP)
      final ipsToCheck = [
        for (int i = 1; i <= 20; i++) '$range.$i',
        for (int i = 100; i <= 120; i++) '$range.$i',
        for (int i = 200; i <= 210; i++) '$range.$i',
      ];

      // Check IPs in parallel (batches of 10)
      for (int i = 0; i < ipsToCheck.length; i += 10) {
        if (!_isSearching) return;

        final batch = ipsToCheck.skip(i).take(10);
        final results = await Future.wait(
          batch.map((ip) => searchAtIP(ip)),
        );

        for (final result in results) {
          if (result.found && _completer != null && !_completer!.isCompleted) {
            _pollTimer?.cancel();
            _timeoutTimer?.cancel();
            _isSearching = false;
            _completer!.complete(result);
            return;
          }
        }
      }
    }
  }

  void _onTimeout() {
    debugPrint('[Reconnection] Search timeout');
    _pollTimer?.cancel();
    _isSearching = false;

    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(CameraDiscoveryResult.error('Search timed out'));
    }
  }

  /// Dispose resources
  void dispose() {
    stopSearch();
    _dio.close();
  }
}
