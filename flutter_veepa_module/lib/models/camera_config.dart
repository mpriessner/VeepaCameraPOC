/// Camera configuration for known cameras
class CameraConfig {
  final String uid;
  final String name;
  final String hotspotName;

  const CameraConfig({
    required this.uid,
    required this.name,
    required this.hotspotName,
  });

  @override
  String toString() => '$name ($uid)';
}

/// Known cameras in the system
class KnownCameras {
  static const camera1 = CameraConfig(
    uid: 'OKB0379196OXYB',
    name: 'Camera 1',
    hotspotName: '@MC-0379196',
  );

  static const camera2 = CameraConfig(
    uid: 'OKB0379832YFIY',
    name: 'Camera 2',
    hotspotName: '@MC-0379832',
  );

  // Camera connected via QR provisioning to home WiFi
  static const camera3 = CameraConfig(
    uid: 'OKB0379853SNLJ',
    name: 'Camera 3 (WiFi)',
    hotspotName: '@MC-0379853',
  );

  static const List<CameraConfig> all = [camera1, camera2, camera3];

  /// Get camera by UID
  static CameraConfig? byUid(String uid) {
    try {
      return all.firstWhere((c) => c.uid == uid);
    } catch (_) {
      return null;
    }
  }
}
