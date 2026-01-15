import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/camera_config_service.dart';

void main() {
  group('ConfigResult', () {
    test('success factory creates successful result', () {
      final result = ConfigResult.success('Test message', {'key': 'value'});

      expect(result.success, isTrue);
      expect(result.message, equals('Test message'));
      expect(result.data?['key'], equals('value'));
    });

    test('failure factory creates failed result', () {
      final result = ConfigResult.failure('Error message');

      expect(result.success, isFalse);
      expect(result.message, equals('Error message'));
      expect(result.data, isNull);
    });

    test('success without message', () {
      final result = ConfigResult.success();

      expect(result.success, isTrue);
      expect(result.message, isNull);
    });
  });

  group('WifiEncryption', () {
    test('has all expected values', () {
      expect(WifiEncryption.values, contains(WifiEncryption.none));
      expect(WifiEncryption.values, contains(WifiEncryption.wep));
      expect(WifiEncryption.values, contains(WifiEncryption.wpa));
      expect(WifiEncryption.values, contains(WifiEncryption.wpa2));
      expect(WifiEncryption.values, contains(WifiEncryption.wpa3));
    });
  });

  group('CameraConfigService', () {
    test('creates with default port', () {
      final service = CameraConfigService(
        cameraIP: '192.168.1.1',
      );

      expect(service, isNotNull);
      service.dispose();
    });

    test('creates with custom credentials', () {
      final service = CameraConfigService(
        cameraIP: '10.0.0.1',
        username: 'user',
        password: 'pass',
        port: 8080,
      );

      expect(service, isNotNull);
      service.dispose();
    });
  });

  group('CameraConfigServiceFactory', () {
    test('forAPMode creates service with default IP', () {
      final service = CameraConfigServiceFactory.forAPMode();

      expect(service, isNotNull);
      service.dispose();
    });

    test('forAPMode accepts custom parameters', () {
      final service = CameraConfigServiceFactory.forAPMode(
        ip: '192.168.0.1',
        username: 'test',
        password: 'test123',
      );

      expect(service, isNotNull);
      service.dispose();
    });

    test('forLAN creates service with provided IP', () {
      final service = CameraConfigServiceFactory.forLAN(
        ip: '192.168.1.100',
      );

      expect(service, isNotNull);
      service.dispose();
    });
  });
}
