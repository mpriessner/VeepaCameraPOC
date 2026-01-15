import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/sdk_integration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SDKMode', () {
    test('has mock and real modes', () {
      expect(SDKMode.values, contains(SDKMode.mock));
      expect(SDKMode.values, contains(SDKMode.real));
    });
  });

  group('MockVeepaSDK', () {
    late MockVeepaSDK sdk;

    setUp(() {
      sdk = MockVeepaSDK();
    });

    test('starts not ready', () {
      expect(sdk.isReady, isFalse);
    });

    test('initialize returns true', () async {
      final result = await sdk.initialize();
      expect(result, isTrue);
      expect(sdk.isReady, isTrue);
    });

    test('connect returns valid handle', () async {
      await sdk.initialize();

      final handle = await sdk.connect('TEST123', 'password');

      expect(handle, greaterThan(0));
    });

    test('connect throws when not initialized', () async {
      expect(
        () => sdk.connect('TEST123', 'password'),
        throwsA(isA<Exception>()),
      );
    });

    test('disconnect removes connection', () async {
      await sdk.initialize();
      final handle = await sdk.connect('TEST123', 'password');

      await sdk.disconnect(handle);

      // Should not throw
    });

    test('sendPTZCommand returns true when connected', () async {
      await sdk.initialize();
      final handle = await sdk.connect('TEST123', 'password');

      final result = await sdk.sendPTZCommand(handle, 4, 50);

      expect(result, isTrue);
    });

    test('sendPTZCommand returns false when not connected', () async {
      await sdk.initialize();

      final result = await sdk.sendPTZCommand(999, 4, 50);

      expect(result, isFalse);
    });

    test('startStream returns true when connected', () async {
      await sdk.initialize();
      final handle = await sdk.connect('TEST123', 'password');

      final result = await sdk.startStream(handle, 0);

      expect(result, isTrue);
    });

    test('startStream returns false when not connected', () async {
      await sdk.initialize();

      final result = await sdk.startStream(999, 0);

      expect(result, isFalse);
    });

    test('stopStream completes without error', () async {
      await sdk.initialize();
      final handle = await sdk.connect('TEST123', 'password');

      await sdk.stopStream(handle);

      // Should not throw
    });
  });

  group('RealVeepaSDK', () {
    late RealVeepaSDK sdk;

    setUp(() {
      sdk = RealVeepaSDK();
    });

    test('starts not ready', () {
      expect(sdk.isReady, isFalse);
    });

    test('initialize returns true', () async {
      final result = await sdk.initialize();
      expect(result, isTrue);
      expect(sdk.isReady, isTrue);
    });

    test('connect throws UnimplementedError', () async {
      await sdk.initialize();

      expect(
        () => sdk.connect('TEST123', 'password'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('sendPTZCommand throws UnimplementedError', () async {
      await sdk.initialize();

      expect(
        () => sdk.sendPTZCommand(1, 4, 50),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('startStream throws UnimplementedError', () async {
      await sdk.initialize();

      expect(
        () => sdk.startStream(1, 0),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('SDKIntegrationService', () {
    late SDKIntegrationService service;

    setUp(() {
      service = SDKIntegrationService();
      service.reset();
    });

    test('is a singleton', () {
      final service1 = SDKIntegrationService();
      final service2 = SDKIntegrationService();
      expect(identical(service1, service2), isTrue);
    });

    test('defaults to mock mode', () {
      expect(service.mode, equals(SDKMode.mock));
    });

    test('starts not ready', () {
      expect(service.isReady, isFalse);
    });

    test('setMode changes mode', () {
      service.setMode(SDKMode.real);
      expect(service.mode, equals(SDKMode.real));
    });

    test('setMode resets SDK', () async {
      // Start in mock mode
      service.setMode(SDKMode.mock);
      await service.initialize();
      expect(service.isReady, isTrue);
      expect(service.sdk, isA<MockVeepaSDK>());

      // Change mode - this should reset
      service.setMode(SDKMode.real);
      // SDK is reset, so it's not ready until re-initialized
      expect(service.sdk, isNull);
      expect(service.isReady, isFalse);
    });

    test('initialize creates mock SDK in mock mode', () async {
      service.setMode(SDKMode.mock);

      await service.initialize();

      expect(service.isReady, isTrue);
      expect(service.sdk, isA<MockVeepaSDK>());
    });

    test('initialize creates real SDK in real mode', () async {
      service.setMode(SDKMode.real);

      await service.initialize();

      expect(service.sdk, isA<RealVeepaSDK>());
    });

    test('reset clears SDK', () async {
      await service.initialize();

      service.reset();

      expect(service.isReady, isFalse);
      expect(service.sdk, isNull);
    });
  });
}
