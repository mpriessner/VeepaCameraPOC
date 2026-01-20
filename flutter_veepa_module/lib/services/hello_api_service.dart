import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for interacting with the Veepa Hello API.
/// Used during QR code provisioning to detect when a camera registers with the cloud.
///
/// Based on official SDK: app_web_api.dart (lines 411-429)
class HelloApiService {
  static const _baseUrl = 'https://api.eye4.cn/hello';

  // User ID for cloud binding - can be unique per session to avoid stale data
  String _userId;

  // Session ID to track this provisioning attempt
  String _sessionId = '';

  HelloApiService({String? userId}) : _userId = userId ?? '15463733-OEM';

  /// Generate a unique session ID to avoid stale cloud data
  void startNewSession() {
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    debugPrint('[HelloApi] Started new session: $_sessionId');
  }

  /// Get the current user ID (for QR code generation)
  String get userId => _userId;

  /// Clear any previous device binding intent.
  /// Call this before showing the QR code.
  /// Clears BOTH old and new format bindings to avoid stale data.
  Future<bool> confirmHello() async {
    try {
      // Clear old format binding
      final response1 = await http.post(
        Uri.parse('$_baseUrl/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': _userId}),
      );
      debugPrint('[HelloApi] confirm($_userId): ${response1.statusCode} ${response1.body}');

      // Clear new format binding
      final response2 = await http.post(
        Uri.parse('$_baseUrl/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': '${_userId}_binding'}),
      );
      debugPrint('[HelloApi] confirm(${_userId}_binding): ${response2.statusCode} ${response2.body}');

      // Small delay to ensure cloud processes the confirm
      await Future.delayed(const Duration(milliseconds: 500));

      return response1.statusCode == 200 || response2.statusCode == 200;
    } catch (e) {
      debugPrint('[HelloApi] confirm error: $e');
      return false;
    }
  }

  /// Query for camera registration using old device format.
  /// Returns camera UID if found, null otherwise.
  Future<String?> queryHelloOld() async {
    return _queryHello(_userId);
  }

  /// Query for camera registration using new device format.
  /// Returns camera UID if found, null otherwise.
  Future<String?> queryHelloNew() async {
    return _queryHello('${_userId}_binding');
  }

  /// Query with alternating format (like SDK does).
  /// Pass the poll count - odd numbers use new format, even use old.
  Future<String?> queryAlternating(int pollCount) async {
    if (pollCount % 2 == 0) {
      return queryHelloOld();
    } else {
      return queryHelloNew();
    }
  }

  /// Internal query method
  Future<String?> _queryHello(String key) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'key': key}),
      );

      debugPrint('[HelloApi] query($key): ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[HelloApi] response data: $data');

        if (data['value'] != null && data['value'].toString().isNotEmpty) {
          // Camera registered! Extract UID
          // Response may be URL-encoded JSON
          String value = data['value'].toString();
          try {
            final decoded = Uri.decodeComponent(value);
            final json = jsonDecode(decoded);
            final uid = json['vuid'] ?? json['did'] ?? json['uid'];
            if (uid != null) {
              debugPrint('[HelloApi] Camera found! UID: $uid');
              return uid.toString();
            }
          } catch (e) {
            // If not JSON, might be direct UID
            debugPrint('[HelloApi] Value is not JSON, returning as UID: $value');
            return value;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[HelloApi] query error: $e');
      return null;
    }
  }
}
