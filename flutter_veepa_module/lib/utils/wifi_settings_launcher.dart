import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Utility for launching device WiFi settings
/// NOTE: url_launcher temporarily removed - uses platform channel only
class WifiSettingsLauncher {
  static const _channel = MethodChannel('veepa_camera/wifi_settings');

  /// Open the device WiFi settings
  /// Returns true if settings were opened successfully
  static Future<bool> openWifiSettings() async {
    try {
      // Try platform channel (for iOS)
      final result = await _channel.invokeMethod<bool>('openWifiSettings');
      if (result == true) {
        return true;
      }
    } on PlatformException catch (e) {
      debugPrint('[WifiSettings] Platform channel failed: $e');
    } on MissingPluginException {
      debugPrint('[WifiSettings] Platform channel not implemented');
    }

    debugPrint('[WifiSettings] Could not open WiFi settings');
    return false;
  }

  /// Check if we can open WiFi settings
  static Future<bool> canOpenWifiSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('canOpenWifiSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
