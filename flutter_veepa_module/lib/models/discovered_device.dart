/// Represents a Veepa camera discovered on the network
class DiscoveredDevice {
  /// Unique device identifier (MAC address or cloud ID)
  final String deviceId;

  /// Device display name
  final String name;

  /// Local IP address (if discovered via LAN)
  final String? ipAddress;

  /// Port number (default: 80)
  final int port;

  /// Device model identifier
  final String? model;

  /// Whether device is online
  final bool isOnline;

  /// Discovery method used
  final DiscoveryMethod discoveryMethod;

  /// Discovery timestamp
  final DateTime discoveredAt;

  const DiscoveredDevice({
    required this.deviceId,
    required this.name,
    this.ipAddress,
    this.port = 80,
    this.model,
    this.isOnline = true,
    required this.discoveryMethod,
    required this.discoveredAt,
  });

  /// Full address with port (e.g., "192.168.1.100:80")
  String get fullAddress {
    if (ipAddress == null) return '';
    return port == 80 ? ipAddress! : '$ipAddress:$port';
  }

  /// Create from SDK response
  factory DiscoveredDevice.fromSDK(Map<String, dynamic> data) {
    return DiscoveredDevice(
      deviceId: data['id'] ?? data['deviceId'] ?? '',
      name: data['name'] ?? data['deviceName'] ?? 'Unknown Camera',
      ipAddress: data['ip'] ?? data['ipAddress'],
      port: data['port'] ?? 80,
      model: data['model'],
      isOnline: data['online'] ?? true,
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );
  }

  /// Create for manual IP entry (legacy - uses IP as device ID)
  factory DiscoveredDevice.manual(String ip, {String? name, int port = 80}) {
    final deviceId = 'manual_${ip.replaceAll('.', '_')}_$port';
    return DiscoveredDevice(
      deviceId: deviceId,
      name: name ?? 'Camera at $ip',
      ipAddress: ip,
      port: port,
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );
  }

  /// Create for manual UID entry (for P2P connection)
  /// The UID is required for SDK P2P connection (e.g., OKB0379853SNLJ)
  factory DiscoveredDevice.manualUID(
    String uid, {
    String? name,
    String? ipAddress,
    int port = 80,
  }) {
    return DiscoveredDevice(
      deviceId: uid, // Use actual camera UID for P2P
      name: name ?? 'Camera $uid',
      ipAddress: ipAddress,
      port: port,
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'DiscoveredDevice(id: $deviceId, name: $name, ip: $fullAddress)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}

/// How the device was discovered
enum DiscoveryMethod {
  lanScan,
  cloudLookup,
  manual,
}
