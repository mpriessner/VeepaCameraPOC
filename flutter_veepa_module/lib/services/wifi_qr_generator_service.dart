import 'dart:convert';
import 'package:veepa_camera_poc/services/camera_config_service.dart';

/// Result of WiFi credential validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Service for generating QR codes containing WiFi credentials
///
/// Supports two formats:
/// 1. Standard WiFi QR format (WIFI:T:WPA;S:ssid;P:password;;)
/// 2. Veepa-specific JSON format for cameras that require it
class WifiQRGeneratorService {
  /// Generate standard WiFi QR code data string
  ///
  /// Format: WIFI:T:<auth>;S:<ssid>;P:<password>;H:<hidden>;;
  ///
  /// This format is recognized by most devices including cameras
  /// that support WiFi QR scanning.
  String generateWifiQRData({
    required String ssid,
    required String password,
    WifiEncryption encryption = WifiEncryption.wpa2,
    bool isHidden = false,
  }) {
    final validation = validateCredentials(ssid, password);
    if (!validation.isValid) {
      throw ArgumentError(validation.errorMessage);
    }

    final authType = _encryptionToAuthType(encryption);
    final escapedSsid = _escapeSpecialChars(ssid);
    final escapedPassword = _escapeSpecialChars(password);

    final buffer = StringBuffer('WIFI:');
    buffer.write('T:$authType;');
    buffer.write('S:$escapedSsid;');

    if (encryption != WifiEncryption.none && password.isNotEmpty) {
      buffer.write('P:$escapedPassword;');
    }

    if (isHidden) {
      buffer.write('H:true;');
    }

    buffer.write(';');

    return buffer.toString();
  }

  /// Generate Veepa-specific QR code data in JSON format
  ///
  /// Some Veepa cameras may require credentials in JSON format:
  /// {"ssid":"NetworkName","pwd":"password123","enc":"WPA2"}
  String generateVeepaQRData({
    required String ssid,
    required String password,
    WifiEncryption encryption = WifiEncryption.wpa2,
  }) {
    final validation = validateCredentials(ssid, password);
    if (!validation.isValid) {
      throw ArgumentError(validation.errorMessage);
    }

    final data = {
      'ssid': ssid,
      'pwd': password,
      'enc': _encryptionToVeepaType(encryption),
    };

    return jsonEncode(data);
  }

  /// Validate WiFi credentials before generating QR code
  ValidationResult validateCredentials(String ssid, String password) {
    // SSID validation
    if (ssid.isEmpty) {
      return const ValidationResult.invalid('SSID cannot be empty');
    }

    if (ssid.length > 32) {
      return const ValidationResult.invalid('SSID must be 32 characters or less');
    }

    // Password validation (WPA/WPA2 requires 8-63 characters)
    if (password.isNotEmpty && password.length < 8) {
      return const ValidationResult.invalid('Password must be at least 8 characters');
    }

    if (password.length > 63) {
      return const ValidationResult.invalid('Password must be 63 characters or less');
    }

    return const ValidationResult.valid();
  }

  /// Convert WifiEncryption enum to standard WiFi QR auth type
  String _encryptionToAuthType(WifiEncryption encryption) {
    switch (encryption) {
      case WifiEncryption.none:
        return 'nopass';
      case WifiEncryption.wep:
        return 'WEP';
      case WifiEncryption.wpa:
      case WifiEncryption.wpa2:
      case WifiEncryption.wpa3:
        return 'WPA';
    }
  }

  /// Convert WifiEncryption enum to Veepa-specific type string
  String _encryptionToVeepaType(WifiEncryption encryption) {
    switch (encryption) {
      case WifiEncryption.none:
        return 'NONE';
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

  /// Escape special characters for WiFi QR format
  ///
  /// Characters that need escaping: \ ; , " :
  String _escapeSpecialChars(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('"', '\\"')
        .replaceAll(':', '\\:');
  }
}
