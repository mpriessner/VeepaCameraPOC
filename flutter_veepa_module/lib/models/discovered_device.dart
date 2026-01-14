/// Represents a Veepa camera discovered on the network
class DiscoveredDevice {
  /// Unique device identifier (MAC address or cloud ID)
  final String deviceId;

  /// Device display name
  final String name;

  /// Local IP address (if discovered via LAN)
  final String? ipAddress;

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
    this.model,
    this.isOnline = true,
    required this.discoveryMethod,
    required this.discoveredAt,
  });

  /// Create from SDK response
  factory DiscoveredDevice.fromSDK(Map<String, dynamic> data) {
    return DiscoveredDevice(
      deviceId: data['id'] ?? data['deviceId'] ?? '',
      name: data['name'] ?? data['deviceName'] ?? 'Unknown Camera',
      ipAddress: data['ip'] ?? data['ipAddress'],
      model: data['model'],
      isOnline: data['online'] ?? true,
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );
  }

  /// Create for manual IP entry
  factory DiscoveredDevice.manual(String ip, {String? name}) {
    return DiscoveredDevice(
      deviceId: ip,
      name: name ?? 'Camera at $ip',
      ipAddress: ip,
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'DiscoveredDevice(id: $deviceId, name: $name, ip: $ipAddress)';

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
