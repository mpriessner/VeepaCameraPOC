import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/camera_reconnection_service.dart';

void main() {
  group('CameraDiscoveryResult', () {
    test('success factory creates successful result', () {
      final result = CameraDiscoveryResult.success('192.168.1.100');

      expect(result.found, isTrue);
      expect(result.ip, equals('192.168.1.100'));
      expect(result.errorMessage, isNull);
    });

    test('success factory includes deviceId', () {
      final result = CameraDiscoveryResult.success(
        '192.168.1.100',
        deviceId: 'ABC123',
      );

      expect(result.found, isTrue);
      expect(result.deviceId, equals('ABC123'));
    });

    test('notFound factory creates not found result', () {
      final result = CameraDiscoveryResult.notFound();

      expect(result.found, isFalse);
      expect(result.ip, isNull);
      expect(result.errorMessage, isNull);
    });

    test('error factory creates error result', () {
      final result = CameraDiscoveryResult.error('Network error');

      expect(result.found, isFalse);
      expect(result.errorMessage, equals('Network error'));
    });
  });

  group('CameraReconnectionService', () {
    test('creates with default parameters', () {
      final service = CameraReconnectionService(deviceId: 'TEST123');

      expect(service, isNotNull);
      expect(service.isSearching, isFalse);
      expect(service.pollInterval, equals(const Duration(seconds: 3)));
      expect(service.timeout, equals(const Duration(minutes: 3)));

      service.dispose();
    });

    test('creates with custom parameters', () {
      final service = CameraReconnectionService(
        deviceId: 'TEST123',
        pollInterval: const Duration(seconds: 5),
        timeout: const Duration(minutes: 1),
        searchRanges: ['10.0.1'],
      );

      expect(service.pollInterval, equals(const Duration(seconds: 5)));
      expect(service.timeout, equals(const Duration(minutes: 1)));
      expect(service.searchRanges, contains('10.0.1'));

      service.dispose();
    });

    test('stopSearch cancels search', () {
      final service = CameraReconnectionService(deviceId: 'TEST123');

      service.stopSearch();

      expect(service.isSearching, isFalse);

      service.dispose();
    });

    test('searchAtIP returns notFound for non-existent IP', () async {
      final service = CameraReconnectionService(deviceId: 'TEST123');

      // Use a non-routable IP that will timeout quickly
      final result = await service.searchAtIP('192.0.2.1');

      expect(result.found, isFalse);

      service.dispose();
    });

    test('dispose cleans up resources', () {
      final service = CameraReconnectionService(deviceId: 'TEST123');

      // Should not throw
      service.dispose();
    });
  });
}
