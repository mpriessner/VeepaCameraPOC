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

  /// Generate Veepa-specific QR code data in JSON format (legacy format)
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

  /// Generate official Veepa SDK QR code data for WiFi provisioning
  ///
  /// This is the format used by the official Veepa SDK for initial camera setup.
  /// Format: {"BS":"bssid","P":"password","U":"userid","RS":"ssid"}
  /// IMPORTANT: Field order matters! SDK uses: BS, P, U, RS
  ///
  /// Based on: flutter-sdk-demo/example/lib/wifi_connect/device_connect_logic.dart
  String generateOfficialVeepaQRData({
    required String ssid,
    required String password,
    String? bssid,
    String userId = '15463733-OEM',
  }) {
    final validation = validateCredentials(ssid, password);
    if (!validation.isValid) {
      throw ArgumentError(validation.errorMessage);
    }

    // Build payload with EXACT SDK field order: BS, P, U, RS
    // Using LinkedHashMap to preserve insertion order
    final Map<String, String> data = {};

    // 1. BS - BSSID (first)
    if (bssid != null && bssid.isNotEmpty) {
      data['BS'] = bssid.replaceAll(':', '');
    }

    // 2. P - Password (second)
    data['P'] = password;

    // 3. U - User ID (third)
    data['U'] = userId;

    // 4. RS - SSID (last)
    data['RS'] = ssid;

    return jsonEncode(data);
  }

  /// Generate multi-frame QR data (old format - kept for reference)
  List<String> generateMultiFrameQRData({
    required String ssid,
    required String password,
    required String bssid,
    required String userId,
    String region = '3',
  }) {
    final cleanBssid = bssid.replaceAll(':', '');
    final fullFrame = jsonEncode({'BS': cleanBssid, 'P': password, 'U': userId, 'S': ssid});
    final bssidUserFrame = jsonEncode({'BS': cleanBssid, 'U': userId, 'A': region});
    final ssidFrame = jsonEncode({'S': ssid, 'A': region});
    final passwordFrame = jsonEncode({'P': password, 'A': region});
    return [fullFrame, fullFrame, fullFrame, bssidUserFrame, ssidFrame, passwordFrame];
  }

  /// Generate EXACT official app pattern (decoded from official app screenshots)
  ///
  /// DECODED DATA from official QR screenshots:
  /// Frame 1: {"BS":"bssid","P":"password","U":"","S":"ssid"} - Full (U empty)
  /// Frame 2: {"BS":"bssid","P":"password","U":"userid","S":"ssid"} - Full WITH user ID (V4, Mask 4)
  /// Frame 3: {"BS":"bssid","U":"userid","A":"3"} - BSSID + User + Region (V3, Mask 2)
  /// Frame 4: {"S":"ssid","A":"3"} - SSID + Region
  /// Frame 5: {"P":"password","A":"3"} - Password + Region
  ///
  /// MASK PATTERNS DISCOVERED:
  /// - Frame 2 (User ID #1): Version 4 (33 modules), Mask 4, Error Correction L
  /// - Frame 3 (User ID #2): Version 3 (29 modules), Mask 2, Error Correction L
  List<String> generateOfficialPattern({
    required String ssid,
    required String password,
    required String bssid,
    String userId = '303628825',
    String region = '3',
  }) {
    final cleanBssid = bssid.replaceAll(':', '').toLowerCase();

    // Frame 1: Full data with EMPTY U field
    final fullFrame = jsonEncode({
      'BS': cleanBssid,
      'P': password,
      'U': '',
      'S': ssid,
    });

    // Frame 2: Full data WITH user ID (V4 = 33 modules, Mask 4)
    final fullWithUserId = jsonEncode({
      'BS': cleanBssid,
      'P': password,
      'U': userId,
      'S': ssid,
    });

    // Frame 3: BSSID + User ID + Region (V3 = 29 modules, Mask 2)
    final bssidUserFrame = jsonEncode({
      'BS': cleanBssid,
      'U': userId,
      'A': region,
    });

    // Frame 4: SSID + Region
    final ssidFrame = jsonEncode({
      'S': ssid,
      'A': region,
    });

    // Frame 5: Password + Region
    final passwordFrame = jsonEncode({
      'P': password,
      'A': region,
    });

    return [
      fullFrame,       // 0. Full data (U empty) - shown once
      fullWithUserId,  // 1. Full WITH user ID (V4, Mask 4)
      bssidUserFrame,  // 2. BSSID + User + Region (V3, Mask 2)
      ssidFrame,       // 3. SSID + Region
      passwordFrame,   // 4. Password + Region
    ];
  }

  /// Get QR configuration for each frame
  /// Returns (typeNumber, maskPattern) for frames that need specific masks
  static (int typeNumber, int? maskPattern) getQrConfigForFrame(int frameIndex) {
    switch (frameIndex) {
      case 0: // Full (U empty) - auto
        return (4, null);
      case 1: // Full WITH user ID - V4, Mask 4
        return (4, 4);
      case 2: // BSSID + User + Region - V3, Mask 2
        return (3, 2);
      case 3: // SSID + Region - V3, auto
        return (3, null);
      case 4: // Password + Region - V2, auto
        return (2, null);
      default:
        return (4, null);
    }
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
