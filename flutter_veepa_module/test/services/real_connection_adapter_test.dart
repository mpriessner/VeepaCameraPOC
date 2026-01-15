import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/sdk_integration_service.dart';
import 'package:veepa_camera_poc/services/real_connection_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealConnectionState', () {
    test('has all expected values', () {
      expect(RealConnectionState.values, contains(RealConnectionState.disconnected));
      expect(RealConnectionState.values, contains(RealConnectionState.connecting));
      expect(RealConnectionState.values, contains(RealConnectionState.connected));
      expect(RealConnectionState.values, contains(RealConnectionState.failed));
      expect(RealConnectionState.values, contains(RealConnectionState.timeout));
    });

    test('isActive is true for connecting and connected', () {
      expect(RealConnectionState.connecting.isActive, isTrue);
      expect(RealConnectionState.connected.isActive, isTrue);
      expect(RealConnectionState.disconnected.isActive, isFalse);
      expect(RealConnectionState.failed.isActive, isFalse);
    });

    test('displayName returns readable names', () {
      expect(RealConnectionState.disconnected.displayName, equals('Disconnected'));
      expect(RealConnectionState.connecting.displayName, equals('Connecting...'));
      expect(RealConnectionState.connected.displayName, equals('Connected'));
    });
  });

  group('RealConnectionAdapter', () {
    late MockVeepaSDK sdk;
    late RealConnectionAdapter adapter;

    setUp(() async {
      sdk = MockVeepaSDK();
      await sdk.initialize();
      adapter = RealConnectionAdapter(
        sdk: sdk,
        deviceId: 'TEST123',
        password: 'password',
        deviceName: 'Test Camera',
      );
    });

    tearDown(() {
      adapter.dispose();
    });

    test('starts disconnected', () {
      expect(adapter.state, equals(RealConnectionState.disconnected));
      expect(adapter.isConnected, isFalse);
      expect(adapter.isConnecting, isFalse);
    });

    test('connect transitions to connected', () async {
      final result = await adapter.connect();

      expect(result, isTrue);
      expect(adapter.state, equals(RealConnectionState.connected));
      expect(adapter.isConnected, isTrue);
      expect(adapter.handle, isNotNull);
    });

    test('connect returns true if already connected', () async {
      await adapter.connect();

      final result = await adapter.connect();

      expect(result, isTrue);
    });

    test('disconnect transitions to disconnected', () async {
      await adapter.connect();

      await adapter.disconnect();

      expect(adapter.state, equals(RealConnectionState.disconnected));
      expect(adapter.isConnected, isFalse);
      expect(adapter.handle, isNull);
    });

    test('connectionDuration is null when disconnected', () {
      expect(adapter.connectionDuration, isNull);
    });

    test('connectionDuration is set when connected', () async {
      await adapter.connect();

      expect(adapter.connectionDuration, isNotNull);
    });

    test('sendPTZCommand returns false when not connected', () async {
      final result = await adapter.sendPTZCommand(4, 50);

      expect(result, isFalse);
    });

    test('sendPTZCommand returns true when connected', () async {
      await adapter.connect();

      final result = await adapter.sendPTZCommand(4, 50);

      expect(result, isTrue);
    });

    test('startStream returns false when not connected', () async {
      final result = await adapter.startStream();

      expect(result, isFalse);
    });

    test('startStream returns true when connected', () async {
      await adapter.connect();

      final result = await adapter.startStream();

      expect(result, isTrue);
    });

    test('reconnect disconnects and reconnects', () async {
      await adapter.connect();
      final originalHandle = adapter.handle;

      final result = await adapter.reconnect();

      expect(result, isTrue);
      expect(adapter.isConnected, isTrue);
      // Handle may be different after reconnect
    });

    test('notifies listeners on state change', () async {
      int notifyCount = 0;
      adapter.addListener(() => notifyCount++);

      await adapter.connect();
      await adapter.disconnect();

      expect(notifyCount, greaterThanOrEqualTo(2));
    });
  });
}
