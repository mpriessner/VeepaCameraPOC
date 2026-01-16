import 'package:shared_preferences/shared_preferences.dart';
import '../models/p2p_credentials.dart';

class P2PCredentialCache {
  static const String _keyPrefix = 'p2p_credentials_';

  Future<bool> saveCredentials(P2PCredentials credentials) async {
    final validationError = credentials.validate();
    if (validationError != null) {
      throw ArgumentError('Invalid credentials: $validationError');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + credentials.cameraUid;
      return await prefs.setString(key, credentials.toJsonString());
    } catch (e) {
      return false;
    }
  }

  Future<P2PCredentials?> loadCredentials(String cameraUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + cameraUid;
      final jsonString = prefs.getString(key);

      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      return P2PCredentials.fromJsonString(jsonString);
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasCredentials(String cameraUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + cameraUid;
      return prefs.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearCredentials(String cameraUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _keyPrefix + cameraUid;
      return await prefs.remove(key);
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getCacheTimestamp(String cameraUid) async {
    final credentials = await loadCredentials(cameraUid);
    return credentials?.cachedAt;
  }

  Future<List<String>> getAllCachedCameraUids() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      return allKeys
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) => key.substring(_keyPrefix.length))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> clearAllCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys().toList();
      for (final key in allKeys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
