/// IP address validation utilities
class IPValidator {
  /// Validates an IPv4 address string
  /// Returns null if valid, error message if invalid
  static String? validate(String? ip) {
    if (ip == null || ip.trim().isEmpty) {
      return 'IP address is required';
    }

    final trimmed = ip.trim();
    final parts = trimmed.split('.');

    if (parts.length != 4) {
      return 'Invalid format. Use x.x.x.x';
    }

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];

      if (part.isEmpty) {
        return 'Invalid format';
      }

      final num = int.tryParse(part);
      if (num == null) {
        return 'Only numbers allowed';
      }

      if (num < 0 || num > 255) {
        return 'Each octet must be 0-255';
      }
    }

    if (trimmed == '0.0.0.0') {
      return 'Invalid: 0.0.0.0 not allowed';
    }

    if (trimmed == '255.255.255.255') {
      return 'Invalid: broadcast address';
    }

    if (trimmed.startsWith('127.')) {
      return 'Invalid: loopback address';
    }

    return null;
  }

  /// Check if IP is in private range
  static bool isPrivateIP(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;

    final octets = parts.map((p) => int.tryParse(p) ?? -1).toList();
    if (octets.any((o) => o < 0 || o > 255)) return false;

    // 10.0.0.0 - 10.255.255.255
    if (octets[0] == 10) return true;

    // 172.16.0.0 - 172.31.255.255
    if (octets[0] == 172 && octets[1] >= 16 && octets[1] <= 31) return true;

    // 192.168.0.0 - 192.168.255.255
    if (octets[0] == 192 && octets[1] == 168) return true;

    return false;
  }

  /// Format IP with optional port
  static String formatWithPort(String ip, int port) {
    if (port == 80 || port == 0) {
      return ip;
    }
    return '$ip:$port';
  }
}
