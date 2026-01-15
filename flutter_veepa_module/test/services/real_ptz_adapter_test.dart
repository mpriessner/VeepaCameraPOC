import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/sdk_integration_service.dart';
import 'package:veepa_camera_poc/services/real_connection_adapter.dart';
import 'package:veepa_camera_poc/services/real_ptz_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PTZCodes', () {
    test('fromDirection returns correct codes', () {
      expect(PTZCodes.fromDirection(PTZDirection.stop), equals(0));
      expect(PTZCodes.fromDirection(PTZDirection.up), equals(1));
      expect(PTZCodes.fromDirection(PTZDirection.down), equals(2));
      expect(PTZCodes.fromDirection(PTZDirection.left), equals(4));
      expect(PTZCodes.fromDirection(PTZDirection.right), equals(8));
    });

    test('fromZoom returns correct codes', () {
      expect(PTZCodes.fromZoom(ZoomDirection.stop), equals(0));
      expect(PTZCodes.fromZoom(ZoomDirection.zoomIn), equals(16));
      expect(PTZCodes.fromZoom(ZoomDirection.zoomOut), equals(32));
    });
  });

  group('RealPTZAdapter', () {
    late MockVeepaSDK sdk;
    late RealConnectionAdapter connection;
    late RealPTZAdapter ptz;

    setUp(() async {
      sdk = MockVeepaSDK();
      await sdk.initialize();
      connection = RealConnectionAdapter(
        sdk: sdk,
        deviceId: 'TEST123',
        password: 'password',
      );
      ptz = RealPTZAdapter(connection: connection);
    });

    tearDown(() {
      ptz.dispose();
      connection.dispose();
    });

    test('starts with default values', () {
      expect(ptz.currentDirection, equals(PTZDirection.stop));
      expect(ptz.currentZoom, equals(ZoomDirection.stop));
      expect(ptz.isMoving, isFalse);
      expect(ptz.speed, equals(50));
    });

    test('setSpeed clamps value', () {
      ptz.setSpeed(150);
      expect(ptz.speed, equals(100));

      ptz.setSpeed(-10);
      expect(ptz.speed, equals(0));
    });

    test('move fails when not connected', () async {
      final result = await ptz.move(PTZDirection.up);

      expect(result, isFalse);
    });

    test('move succeeds when connected', () async {
      await connection.connect();

      final result = await ptz.move(PTZDirection.up);

      expect(result, isTrue);
      expect(ptz.currentDirection, equals(PTZDirection.up));
      expect(ptz.isMoving, isTrue);
    });

    test('stop sets direction to stop', () async {
      await connection.connect();
      await ptz.move(PTZDirection.left);

      await ptz.stop();

      expect(ptz.currentDirection, equals(PTZDirection.stop));
      expect(ptz.isMoving, isFalse);
    });

    test('zoom fails when not connected', () async {
      final result = await ptz.zoom(ZoomDirection.zoomIn);

      expect(result, isFalse);
    });

    test('zoom succeeds when connected', () async {
      await connection.connect();

      final result = await ptz.zoom(ZoomDirection.zoomIn);

      expect(result, isTrue);
      expect(ptz.currentZoom, equals(ZoomDirection.zoomIn));
    });

    test('goToPreset fails when not connected', () async {
      final result = await ptz.goToPreset(1);

      expect(result, isFalse);
    });

    test('goToPreset succeeds when connected', () async {
      await connection.connect();

      final result = await ptz.goToPreset(1);

      expect(result, isTrue);
    });

    test('savePreset fails when not connected', () async {
      final result = await ptz.savePreset(1);

      expect(result, isFalse);
    });

    test('savePreset succeeds when connected', () async {
      await connection.connect();

      final result = await ptz.savePreset(1);

      expect(result, isTrue);
    });

    test('getStatistics returns expected data', () async {
      await connection.connect();
      await ptz.move(PTZDirection.up);

      final stats = ptz.getStatistics();

      expect(stats['commandsSent'], equals(1));
      expect(stats['currentDirection'], equals('up'));
      expect(stats['speed'], equals(50));
      expect(stats['isMoving'], isTrue);
    });

    test('resetStatistics clears counters', () async {
      await connection.connect();
      await ptz.move(PTZDirection.up);

      ptz.resetStatistics();

      expect(ptz.commandsSent, equals(0));
    });
  });
}
