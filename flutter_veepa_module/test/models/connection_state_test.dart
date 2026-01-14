import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';

void main() {
  group('ConnectionState', () {
    test('has all expected values', () {
      expect(ConnectionState.values.length, 5);
      expect(ConnectionState.values, contains(ConnectionState.disconnected));
      expect(ConnectionState.values, contains(ConnectionState.connecting));
      expect(ConnectionState.values, contains(ConnectionState.connected));
      expect(ConnectionState.values, contains(ConnectionState.reconnecting));
      expect(ConnectionState.values, contains(ConnectionState.error));
    });

    test('displayName returns correct strings', () {
      expect(ConnectionState.disconnected.displayName, 'Disconnected');
      expect(ConnectionState.connecting.displayName, 'Connecting...');
      expect(ConnectionState.connected.displayName, 'Connected');
      expect(ConnectionState.reconnecting.displayName, 'Reconnecting...');
      expect(ConnectionState.error.displayName, 'Connection Failed');
    });
  });

  group('ConnectionStateExtension', () {
    test('isConnected returns correct values', () {
      expect(ConnectionState.disconnected.isConnected, isFalse);
      expect(ConnectionState.connecting.isConnected, isFalse);
      expect(ConnectionState.connected.isConnected, isTrue);
      expect(ConnectionState.reconnecting.isConnected, isFalse);
      expect(ConnectionState.error.isConnected, isFalse);
    });

    test('isConnecting returns correct values', () {
      expect(ConnectionState.disconnected.isConnecting, isFalse);
      expect(ConnectionState.connecting.isConnecting, isTrue);
      expect(ConnectionState.connected.isConnecting, isFalse);
      expect(ConnectionState.reconnecting.isConnecting, isTrue);
      expect(ConnectionState.error.isConnecting, isFalse);
    });

    test('canConnect returns correct values', () {
      expect(ConnectionState.disconnected.canConnect, isTrue);
      expect(ConnectionState.connecting.canConnect, isFalse);
      expect(ConnectionState.connected.canConnect, isFalse);
      expect(ConnectionState.reconnecting.canConnect, isFalse);
      expect(ConnectionState.error.canConnect, isTrue);
    });
  });
}
