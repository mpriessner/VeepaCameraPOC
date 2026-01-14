import 'dart:convert';

/// Parsed result from a Veepa camera QR code
class VeepaQRData {
  final String deviceId;
  final String password;
  final String? model;
  final String? name;

  const VeepaQRData({
    required this.deviceId,
    required this.password,
    this.model,
    this.name,
  });

  @override
  String toString() {
    return 'VeepaQRData(deviceId: $deviceId, model: $model, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VeepaQRData &&
        other.deviceId == deviceId &&
        other.password == password &&
        other.model == model &&
        other.name == name;
  }

  @override
  int get hashCode {
    return deviceId.hashCode ^ password.hashCode ^ model.hashCode ^ name.hashCode;
  }
}

/// Exception thrown when QR code parsing fails
class QRParseException implements Exception {
  final String message;
  final String? rawData;

  QRParseException(this.message, [this.rawData]);

  @override
  String toString() => 'QRParseException: $message';
}

/// Parser for Veepa camera QR codes
///
/// Supports multiple QR formats:
/// - VSTC format: `VSTC:deviceId:password:model`
/// - JSON format: `{"id":"...","pwd":"...","model":"..."}`
/// - URL format: `vstc://deviceId?pwd=password&model=model`
class QRCodeParser {
  /// Parse a raw QR code string into VeepaQRData
  ///
  /// Throws [QRParseException] if the QR code is invalid or not a Veepa code
  static VeepaQRData parse(String rawData) {
    final trimmed = rawData.trim();

    if (trimmed.isEmpty) {
      throw QRParseException('Empty QR code data');
    }

    // Try JSON format first
    if (trimmed.startsWith('{')) {
      return _parseJson(trimmed);
    }

    // Try URL format first (before VSTC: check, since vstc:// starts with vstc:)
    if (trimmed.toLowerCase().startsWith('vstc://')) {
      return _parseUrlFormat(trimmed);
    }

    // Try VSTC colon-separated format
    if (trimmed.toUpperCase().startsWith('VSTC:')) {
      return _parseVstcFormat(trimmed);
    }

    // Try simple colon format (deviceId:password)
    if (trimmed.contains(':') && !trimmed.contains('://')) {
      return _parseSimpleFormat(trimmed);
    }

    throw QRParseException('Unrecognized QR code format', rawData);
  }

  /// Check if a raw string looks like a Veepa QR code
  static bool isVeepaQRCode(String rawData) {
    final trimmed = rawData.trim().toLowerCase();

    // Check for known Veepa patterns
    if (trimmed.startsWith('vstc')) return true;
    if (trimmed.startsWith('{') && trimmed.contains('"id"')) return true;

    // Check for device ID patterns (typically 12-20 char hex)
    final parts = trimmed.split(':');
    if (parts.isNotEmpty && _looksLikeDeviceId(parts[0])) return true;

    return false;
  }

  static bool _looksLikeDeviceId(String value) {
    // Veepa device IDs are typically uppercase alphanumeric, 8-24 characters
    // They should NOT contain spaces and must be a single token
    final trimmed = value.trim();

    // Reject if contains spaces (not a device ID)
    if (trimmed.contains(' ')) return false;

    // Must be alphanumeric only
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(trimmed)) return false;

    // Length check
    if (trimmed.length < 8 || trimmed.length > 24) return false;

    // Should start with typical prefixes or be mostly uppercase/numeric
    final upper = trimmed.toUpperCase();
    if (upper.startsWith('VSTC') || upper.startsWith('ABC')) return true;

    // Check if it looks hex-ish (common for device IDs)
    final hexChars = upper.replaceAll(RegExp(r'[^0-9A-F]'), '');
    return hexChars.length >= trimmed.length * 0.5; // At least 50% hex chars
  }

  /// Parse JSON format: {"id":"...","pwd":"...","model":"..."}
  static VeepaQRData _parseJson(String data) {
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;

      final deviceId = json['id'] as String? ??
                       json['deviceId'] as String? ??
                       json['device_id'] as String? ??
                       json['uid'] as String?;

      final password = json['pwd'] as String? ??
                       json['password'] as String? ??
                       json['pass'] as String? ??
                       'admin'; // Default password

      final model = json['model'] as String?;
      final name = json['name'] as String?;

      if (deviceId == null || deviceId.isEmpty) {
        throw QRParseException('Missing device ID in JSON', data);
      }

      return VeepaQRData(
        deviceId: deviceId,
        password: password,
        model: model,
        name: name,
      );
    } on FormatException catch (e) {
      throw QRParseException('Invalid JSON format: ${e.message}', data);
    }
  }

  /// Parse VSTC format: VSTC:deviceId:password:model
  static VeepaQRData _parseVstcFormat(String data) {
    final parts = data.split(':');

    if (parts.length < 2) {
      throw QRParseException('Invalid VSTC format - expected at least deviceId', data);
    }

    // VSTC:deviceId:password:model or VSTC:deviceId:password
    final deviceId = parts.length > 1 ? parts[1] : '';
    final password = parts.length > 2 ? parts[2] : 'admin';
    final model = parts.length > 3 ? parts[3] : null;

    if (deviceId.isEmpty) {
      throw QRParseException('Empty device ID in VSTC format', data);
    }

    return VeepaQRData(
      deviceId: deviceId,
      password: password,
      model: model,
    );
  }

  /// Parse URL format: vstc://deviceId?pwd=password&model=model
  static VeepaQRData _parseUrlFormat(String data) {
    try {
      // For custom schemes like vstc://, Uri.parse doesn't work well
      // Manually extract parts: vstc://DEVICE123?pwd=xxx&model=yyy

      String deviceId = '';
      String password = 'admin';
      String? model;
      String? name;

      // Remove scheme (vstc:// or VSTC://)
      var withoutScheme = data;
      if (data.toLowerCase().startsWith('vstc://')) {
        withoutScheme = data.substring(7); // Length of 'vstc://'
      }

      // Split by ? to get path and query
      final parts = withoutScheme.split('?');
      deviceId = parts[0];

      // Parse query parameters if present
      if (parts.length > 1) {
        final queryString = parts[1];
        final params = Uri.splitQueryString(queryString);
        password = params['pwd'] ?? params['password'] ?? 'admin';
        model = params['model'];
        name = params['name'];
      }

      if (deviceId.isEmpty) {
        throw QRParseException('Empty device ID in URL format', data);
      }

      return VeepaQRData(
        deviceId: deviceId,
        password: password,
        model: model,
        name: name,
      );
    } catch (e) {
      throw QRParseException('Invalid URL format: $e', data);
    }
  }

  /// Parse simple format: deviceId:password or just deviceId
  static VeepaQRData _parseSimpleFormat(String data) {
    final parts = data.split(':');

    final deviceId = parts[0].trim();
    final password = parts.length > 1 ? parts[1].trim() : 'admin';
    final model = parts.length > 2 ? parts[2].trim() : null;

    if (deviceId.isEmpty) {
      throw QRParseException('Empty device ID', data);
    }

    if (!_looksLikeDeviceId(deviceId)) {
      throw QRParseException('Value does not look like a Veepa device ID', data);
    }

    return VeepaQRData(
      deviceId: deviceId,
      password: password,
      model: model,
    );
  }
}
