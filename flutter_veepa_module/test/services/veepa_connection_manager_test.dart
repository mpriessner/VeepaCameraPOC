import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectionState', () {
    test('displayName returns correct strings', () {
      expect(ConnectionState.disconnected.displayName, 'Disconnected');
      expect(ConnectionState.connecting.displayName, 'Connecting...');
      expect(ConnectionState.connected.displayName, 'Connected');
      expect(ConnectionState.reconnecting.displayName, 'Reconnecting...');
      expect(ConnectionState.error.displayName, 'Connection Failed');
    });

    test('isConnected is true only for connected state', () {
      expect(ConnectionState.disconnected.isConnected, isFalse);
      expect(ConnectionState.connecting.isConnected, isFalse);
      expect(ConnectionState.connected.isConnected, isTrue);
      expect(ConnectionState.reconnecting.isConnected, isFalse);
      expect(ConnectionState.error.isConnected, isFalse);
    });

    test('isConnecting is true for connecting and reconnecting', () {
      expect(ConnectionState.disconnected.isConnecting, isFalse);
      expect(ConnectionState.connecting.isConnecting, isTrue);
      expect(ConnectionState.connected.isConnecting, isFalse);
      expect(ConnectionState.reconnecting.isConnecting, isTrue);
      expect(ConnectionState.error.isConnecting, isFalse);
    });

    test('canConnect is true for disconnected and error', () {
      expect(ConnectionState.disconnected.canConnect, isTrue);
      expect(ConnectionState.connecting.canConnect, isFalse);
      expect(ConnectionState.connected.canConnect, isFalse);
      expect(ConnectionState.reconnecting.canConnect, isFalse);
      expect(ConnectionState.error.canConnect, isTrue);
    });
  });

  group('VeepaConnectionManager', () {
    late VeepaConnectionManager manager;

    setUp(() async {
      manager = VeepaConnectionManager();
      manager.reset();
      // Initialize SDK for tests
      VeepaSDKManager().reset();
      await VeepaSDKManager().initialize();
    });

    tearDown(() {
      manager.reset();
    });

    test('initial state is disconnected', () {
      expect(manager.state, ConnectionState.disconnected);
      expect(manager.connectedDevice, isNull);
      expect(manager.errorMessage, isNull);
      expect(manager.reconnectAttempts, 0);
    });

    test('configuration constants are correct', () {
      expect(VeepaConnectionManager.connectionTimeout,
          const Duration(seconds: 10));
      expect(VeepaConnectionManager.maxReconnectAttempts, 3);
      expect(
          VeepaConnectionManager.reconnectDelay, const Duration(seconds: 2));
    });

    test('connect transitions to connecting state', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      final states = <ConnectionState>[];
      manager.stateStream.listen(states.add);

      // Start connection without waiting
      manager.connect(device);

      // Should immediately transition to connecting
      expect(manager.state, ConnectionState.connecting);
      expect(manager.connectedDevice, isNotNull);
      expect(manager.connectedDevice!.ipAddress, '192.168.1.100');
    });

    test('successful connection transitions to connected', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      final result = await manager.connect(device);

      expect(result, isTrue);
      expect(manager.state, ConnectionState.connected);
      expect(manager.connectedDevice, isNotNull);
      expect(manager.errorMessage, isNull);
    });

    test('disconnect clears all state', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      await manager.connect(device);
      expect(manager.state, ConnectionState.connected);

      await manager.disconnect();

      expect(manager.state, ConnectionState.disconnected);
      expect(manager.connectedDevice, isNull);
      expect(manager.errorMessage, isNull);
      expect(manager.reconnectAttempts, 0);
    });

    test('ignores connect while already connecting', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      final future1 = manager.connect(device);
      final result2 = await manager.connect(device);

      expect(result2, isFalse);
      await future1;
    });

    test('returns true if already connected to same device', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      await manager.connect(device);
      final result = await manager.connect(device);

      expect(result, isTrue);
      expect(manager.state, ConnectionState.connected);
    });

    test('disconnects old device when connecting to new', () async {
      final device1 = DiscoveredDevice.manual('192.168.1.100', name: 'Test 1');
      final device2 = DiscoveredDevice.manual('192.168.1.101', name: 'Test 2');

      await manager.connect(device1);
      expect(manager.connectedDevice!.ipAddress, '192.168.1.100');

      await manager.connect(device2);
      expect(manager.connectedDevice!.ipAddress, '192.168.1.101');
    });

    test('stateStream emits state changes', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      final states = <ConnectionState>[];
      final subscription = manager.stateStream.listen(states.add);

      await manager.connect(device);
      await manager.disconnect();

      // Allow stream events to process
      await Future.delayed(const Duration(milliseconds: 50));
      await subscription.cancel();

      expect(states, contains(ConnectionState.connecting));
      expect(states, contains(ConnectionState.connected));
      expect(states, contains(ConnectionState.disconnected));
    });

    test('notifies listeners on state change', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      await manager.connect(device);
      await manager.disconnect();

      expect(notificationCount, greaterThanOrEqualTo(3));
    });

    test('connection error sets error message', () async {
      // Reset SDK so connection fails
      VeepaSDKManager().reset();

      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');
      final result = await manager.connect(device);

      expect(result, isFalse);
      expect(manager.state, ConnectionState.error);
      expect(manager.errorMessage, isNotNull);
    });

    test('retry resets reconnect attempts and tries again', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      await manager.connect(device);

      // Reinitialize SDK
      await VeepaSDKManager().initialize();

      final result = await manager.retry();

      expect(result, isTrue);
      expect(manager.reconnectAttempts, 0);
    });

    test('retry returns false with no device', () async {
      final result = await manager.retry();

      expect(result, isFalse);
    });

    test('onConnectionLost triggers reconnection', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      await manager.connect(device);
      expect(manager.state, ConnectionState.connected);

      manager.onConnectionLost();

      expect(manager.state, ConnectionState.reconnecting);
      expect(manager.reconnectAttempts, greaterThan(0));
    });

    test('onConnectionLost does nothing if not connected', () {
      manager.onConnectionLost();

      expect(manager.state, ConnectionState.disconnected);
      expect(manager.reconnectAttempts, 0);
    });

    test('reset clears all state', () async {
      final device = DiscoveredDevice.manual('192.168.1.100', name: 'Test');

      await manager.connect(device);
      manager.reset();

      expect(manager.state, ConnectionState.disconnected);
      expect(manager.connectedDevice, isNull);
      expect(manager.errorMessage, isNull);
      expect(manager.reconnectAttempts, 0);
    });
  });
}
