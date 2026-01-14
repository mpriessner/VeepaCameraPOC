import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stored_device.dart';

/// Service for persisting camera devices locally
class DeviceStorageService extends ChangeNotifier {
  static final DeviceStorageService _instance = DeviceStorageService._internal();
  factory DeviceStorageService() => _instance;
  DeviceStorageService._internal();

  static const String _storageKey = 'veepa_stored_devices';

  List<StoredDevice> _devices = [];
  bool _isInitialized = false;

  /// All stored devices
  List<StoredDevice> get devices => List.unmodifiable(_devices);

  /// Whether the service has loaded from storage
  bool get isInitialized => _isInitialized;

  /// Number of stored devices
  int get deviceCount => _devices.length;

  /// Initialize and load devices from storage
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey) ?? '';

      if (jsonString.isNotEmpty) {
        _devices = StoredDevice.deserializeList(jsonString);
        debugPrint('[DeviceStorage] Loaded ${_devices.length} devices');
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[DeviceStorage] Error loading devices: $e');
      _devices = [];
      _isInitialized = true;
    }
  }

  /// Save a new device
  Future<bool> saveDevice(StoredDevice device) async {
    // Check for duplicate
    if (_devices.any((d) => d.deviceId == device.deviceId)) {
      debugPrint('[DeviceStorage] Device already exists: ${device.deviceId}');
      return false;
    }

    _devices.add(device);
    await _persist();
    debugPrint('[DeviceStorage] Saved device: ${device.name}');
    notifyListeners();
    return true;
  }

  /// Update an existing device
  Future<bool> updateDevice(StoredDevice device) async {
    final index = _devices.indexWhere((d) => d.deviceId == device.deviceId);
    if (index == -1) {
      debugPrint('[DeviceStorage] Device not found: ${device.deviceId}');
      return false;
    }

    _devices[index] = device;
    await _persist();
    debugPrint('[DeviceStorage] Updated device: ${device.name}');
    notifyListeners();
    return true;
  }

  /// Delete a device by ID
  Future<bool> deleteDevice(String deviceId) async {
    final initialLength = _devices.length;
    _devices.removeWhere((d) => d.deviceId == deviceId);

    if (_devices.length < initialLength) {
      await _persist();
      debugPrint('[DeviceStorage] Deleted device: $deviceId');
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Get a device by ID
  StoredDevice? getDevice(String deviceId) {
    try {
      return _devices.firstWhere((d) => d.deviceId == deviceId);
    } catch (e) {
      return null;
    }
  }

  /// Check if a device exists
  bool hasDevice(String deviceId) {
    return _devices.any((d) => d.deviceId == deviceId);
  }

  /// Update last connected time for a device
  Future<void> updateLastConnected(String deviceId) async {
    final device = getDevice(deviceId);
    if (device != null) {
      final updated = device.copyWithLastConnected(DateTime.now());
      await updateDevice(updated);
    }
  }

  /// Rename a device
  Future<bool> renameDevice(String deviceId, String newName) async {
    final device = getDevice(deviceId);
    if (device != null) {
      final updated = device.copyWithName(newName);
      return await updateDevice(updated);
    }
    return false;
  }

  /// Clear all stored devices
  Future<void> clearAll() async {
    _devices.clear();
    await _persist();
    debugPrint('[DeviceStorage] Cleared all devices');
    notifyListeners();
  }

  /// Persist devices to storage
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = StoredDevice.serializeList(_devices);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('[DeviceStorage] Error saving devices: $e');
    }
  }

  /// Reset the service (for testing)
  void reset() {
    _devices.clear();
    _isInitialized = false;
    notifyListeners();
  }

  /// Sort devices by last connected (most recent first)
  List<StoredDevice> get devicesSortedByRecent {
    final sorted = List<StoredDevice>.from(_devices);
    sorted.sort((a, b) {
      final aTime = a.lastConnected ?? a.addedAt;
      final bTime = b.lastConnected ?? b.addedAt;
      return bTime.compareTo(aTime);
    });
    return sorted;
  }

  /// Sort devices by name
  List<StoredDevice> get devicesSortedByName {
    final sorted = List<StoredDevice>.from(_devices);
    sorted.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return sorted;
  }
}
