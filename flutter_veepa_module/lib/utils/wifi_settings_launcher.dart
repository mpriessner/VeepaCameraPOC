import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Utility for launching device WiFi settings
class WifiSettingsLauncher {
  static const _channel = MethodChannel('veepa_camera/wifi_settings');

  /// Open the device WiFi settings
  /// Returns true if settings were opened successfully
  static Future<bool> openWifiSettings() async {
    try {
      // Try platform channel first (for iOS)
      final result = await _channel.invokeMethod<bool>('openWifiSettings');
      if (result == true) {
        return true;
      }
    } on PlatformException catch (e) {
      debugPrint('[WifiSettings] Platform channel failed: $e');
    } on MissingPluginException {
      debugPrint('[WifiSettings] Platform channel not implemented');
    }

    // Fallback: Try URL scheme
    return await _tryUrlScheme();
  }

  /// Try opening WiFi settings via URL scheme
  static Future<bool> _tryUrlScheme() async {
    // iOS Settings URLs (may or may not work depending on iOS version)
    final schemes = [
      'App-Prefs:root=WIFI',
      'prefs:root=WIFI',
      'app-settings:',
    ];

    for (final scheme in schemes) {
      try {
        final uri = Uri.parse(scheme);
        if (await canLaunchUrl(uri)) {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) {
            debugPrint('[WifiSettings] Opened via: $scheme');
            return true;
          }
        }
      } catch (e) {
        debugPrint('[WifiSettings] Failed scheme $scheme: $e');
      }
    }

    debugPrint('[WifiSettings] All schemes failed');
    return false;
  }

  /// Check if we can open WiFi settings
  static Future<bool> canOpenWifiSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('canOpenWifiSettings');
      return result ?? false;
    } catch (_) {
      // Check URL schemes
      final schemes = ['App-Prefs:root=WIFI', 'app-settings:'];
      for (final scheme in schemes) {
        try {
          if (await canLaunchUrl(Uri.parse(scheme))) {
            return true;
          }
        } catch (_) {}
      }
      return false;
    }
  }
}
