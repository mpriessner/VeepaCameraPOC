import 'dart:convert';

/// A camera device stored locally for quick reconnection
class StoredDevice {
  final String deviceId;
  final String name;
  final String password;
  final String? model;
  final DateTime addedAt;
  final DateTime? lastConnected;

  const StoredDevice({
    required this.deviceId,
    required this.name,
    required this.password,
    this.model,
    required this.addedAt,
    this.lastConnected,
  });

  /// Create from QR scan data with custom name
  factory StoredDevice.fromQRData({
    required String deviceId,
    required String password,
    required String name,
    String? model,
  }) {
    return StoredDevice(
      deviceId: deviceId,
      name: name,
      password: password,
      model: model,
      addedAt: DateTime.now(),
    );
  }

  /// Create from JSON
  factory StoredDevice.fromJson(Map<String, dynamic> json) {
    return StoredDevice(
      deviceId: json['deviceId'] as String,
      name: json['name'] as String,
      password: json['password'] as String,
      model: json['model'] as String?,
      addedAt: DateTime.parse(json['addedAt'] as String),
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'name': name,
      'password': password,
      'model': model,
      'addedAt': addedAt.toIso8601String(),
      'lastConnected': lastConnected?.toIso8601String(),
    };
  }

  /// Create copy with updated last connected time
  StoredDevice copyWithLastConnected(DateTime time) {
    return StoredDevice(
      deviceId: deviceId,
      name: name,
      password: password,
      model: model,
      addedAt: addedAt,
      lastConnected: time,
    );
  }

  /// Create copy with updated name
  StoredDevice copyWithName(String newName) {
    return StoredDevice(
      deviceId: deviceId,
      name: newName,
      password: password,
      model: model,
      addedAt: addedAt,
      lastConnected: lastConnected,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StoredDevice && other.deviceId == deviceId;
  }

  @override
  int get hashCode => deviceId.hashCode;

  @override
  String toString() {
    return 'StoredDevice(deviceId: $deviceId, name: $name, model: $model)';
  }

  /// Serialize list of devices to JSON string
  static String serializeList(List<StoredDevice> devices) {
    return jsonEncode(devices.map((d) => d.toJson()).toList());
  }

  /// Deserialize list of devices from JSON string
  static List<StoredDevice> deserializeList(String jsonString) {
    if (jsonString.isEmpty) return [];
    final list = jsonDecode(jsonString) as List;
    return list.map((item) => StoredDevice.fromJson(item as Map<String, dynamic>)).toList();
  }
}
