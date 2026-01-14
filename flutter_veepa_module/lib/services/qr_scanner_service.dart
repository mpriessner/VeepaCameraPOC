import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/qr_code_parser.dart';

/// Scan result from QR scanner
class QRScanResult {
  final String rawData;
  final VeepaQRData? parsedData;
  final String? error;
  final DateTime timestamp;

  QRScanResult._({
    required this.rawData,
    this.parsedData,
    this.error,
    required this.timestamp,
  });

  factory QRScanResult.success(String rawData, VeepaQRData data) {
    return QRScanResult._(
      rawData: rawData,
      parsedData: data,
      timestamp: DateTime.now(),
    );
  }

  factory QRScanResult.failure(String rawData, String error) {
    return QRScanResult._(
      rawData: rawData,
      error: error,
      timestamp: DateTime.now(),
    );
  }

  bool get isSuccess => parsedData != null && error == null;

  @override
  String toString() {
    if (isSuccess) {
      return 'QRScanResult.success(${parsedData!.deviceId})';
    }
    return 'QRScanResult.failure($error)';
  }
}

/// Service for handling QR code scanning and parsing
class QRScannerService extends ChangeNotifier {
  static final QRScannerService _instance = QRScannerService._internal();
  factory QRScannerService() => _instance;
  QRScannerService._internal();

  final List<QRScanResult> _scanHistory = [];
  QRScanResult? _lastResult;
  bool _isScanning = false;

  // Callbacks
  void Function(QRScanResult)? onScanComplete;
  void Function(String)? onError;

  /// Whether scanner is currently active
  bool get isScanning => _isScanning;

  /// Last scan result
  QRScanResult? get lastResult => _lastResult;

  /// History of all scans
  List<QRScanResult> get scanHistory => List.unmodifiable(_scanHistory);

  /// Start scanning mode
  void startScanning() {
    _isScanning = true;
    debugPrint('[QRScanner] Scanning started');
    notifyListeners();
  }

  /// Stop scanning mode
  void stopScanning() {
    _isScanning = false;
    debugPrint('[QRScanner] Scanning stopped');
    notifyListeners();
  }

  /// Process a raw QR code string from the camera
  ///
  /// Returns the scan result and triggers callbacks
  QRScanResult processQRCode(String rawData) {
    debugPrint('[QRScanner] Processing: $rawData');

    QRScanResult result;

    // First check if it looks like a Veepa QR code
    if (!QRCodeParser.isVeepaQRCode(rawData)) {
      result = QRScanResult.failure(
        rawData,
        'Not a recognized Veepa camera QR code',
      );
    } else {
      try {
        final data = QRCodeParser.parse(rawData);
        result = QRScanResult.success(rawData, data);
        debugPrint('[QRScanner] Parsed successfully: ${data.deviceId}');
      } on QRParseException catch (e) {
        result = QRScanResult.failure(rawData, e.message);
        debugPrint('[QRScanner] Parse error: ${e.message}');
      } catch (e) {
        result = QRScanResult.failure(rawData, 'Unexpected error: $e');
        debugPrint('[QRScanner] Unexpected error: $e');
      }
    }

    _lastResult = result;
    _scanHistory.add(result);

    // Trigger callbacks
    if (result.isSuccess) {
      onScanComplete?.call(result);
    } else {
      onError?.call(result.error!);
    }

    notifyListeners();
    return result;
  }

  /// Validate a device ID format
  bool isValidDeviceId(String deviceId) {
    if (deviceId.isEmpty) return false;
    // Veepa device IDs are typically 8-24 alphanumeric characters
    return RegExp(r'^[A-Za-z0-9]{8,24}$').hasMatch(deviceId);
  }

  /// Clear scan history
  void clearHistory() {
    _scanHistory.clear();
    _lastResult = null;
    notifyListeners();
  }

  /// Reset the service
  void reset() {
    _isScanning = false;
    _scanHistory.clear();
    _lastResult = null;
    onScanComplete = null;
    onError = null;
    notifyListeners();
  }

  /// Get count of successful scans
  int get successfulScanCount {
    return _scanHistory.where((r) => r.isSuccess).length;
  }

  /// Get count of failed scans
  int get failedScanCount {
    return _scanHistory.where((r) => !r.isSuccess).length;
  }
}
