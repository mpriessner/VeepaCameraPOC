import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/veepa_discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DiscoveryState', () {
    test('displayName returns correct strings', () {
      expect(DiscoveryState.idle.displayName, 'Ready to scan');
      expect(DiscoveryState.scanning.displayName, 'Scanning...');
      expect(DiscoveryState.completed.displayName, 'Scan complete');
      expect(DiscoveryState.noDevicesFound.displayName, 'No cameras found');
      expect(DiscoveryState.error.displayName, 'Scan failed');
    });

    test('isScanning is true only for scanning state', () {
      expect(DiscoveryState.idle.isScanning, isFalse);
      expect(DiscoveryState.scanning.isScanning, isTrue);
      expect(DiscoveryState.completed.isScanning, isFalse);
      expect(DiscoveryState.noDevicesFound.isScanning, isFalse);
      expect(DiscoveryState.error.isScanning, isFalse);
    });

    test('hasDevices is true only for completed state', () {
      expect(DiscoveryState.idle.hasDevices, isFalse);
      expect(DiscoveryState.scanning.hasDevices, isFalse);
      expect(DiscoveryState.completed.hasDevices, isTrue);
      expect(DiscoveryState.noDevicesFound.hasDevices, isFalse);
      expect(DiscoveryState.error.hasDevices, isFalse);
    });

    test('isEmpty is true only for noDevicesFound state', () {
      expect(DiscoveryState.idle.isEmpty, isFalse);
      expect(DiscoveryState.scanning.isEmpty, isFalse);
      expect(DiscoveryState.completed.isEmpty, isFalse);
      expect(DiscoveryState.noDevicesFound.isEmpty, isTrue);
      expect(DiscoveryState.error.isEmpty, isFalse);
    });

    test('isError is true only for error state', () {
      expect(DiscoveryState.idle.isError, isFalse);
      expect(DiscoveryState.scanning.isError, isFalse);
      expect(DiscoveryState.completed.isError, isFalse);
      expect(DiscoveryState.noDevicesFound.isError, isFalse);
      expect(DiscoveryState.error.isError, isTrue);
    });
  });

  group('VeepaDiscoveryService', () {
    late VeepaDiscoveryService service;

    setUp(() {
      service = VeepaDiscoveryService();
    });

    tearDown(() {
      service.dispose();
    });

    test('initial state is idle with empty device list', () {
      expect(service.state, DiscoveryState.idle);
      expect(service.devices, isEmpty);
      expect(service.errorMessage, isNull);
    });

    test('default timeout is 5 seconds', () {
      expect(service.discoveryTimeout, const Duration(seconds: 5));
    });

    test('custom timeout can be set', () {
      final customService = VeepaDiscoveryService(
        discoveryTimeout: const Duration(seconds: 10),
      );
      expect(customService.discoveryTimeout, const Duration(seconds: 10));
      customService.dispose();
    });

    group('IP validation', () {
      test('accepts valid IP addresses', () async {
        final valid1 = await service.addManualDevice('192.168.1.1');
        expect(valid1, isNotNull);

        service.clearDevices();

        final valid2 = await service.addManualDevice('10.0.0.1');
        expect(valid2, isNotNull);

        service.clearDevices();

        final valid3 = await service.addManualDevice('0.0.0.0');
        expect(valid3, isNotNull);

        service.clearDevices();

        final valid4 = await service.addManualDevice('255.255.255.255');
        expect(valid4, isNotNull);
      });

      test('rejects invalid IP addresses', () async {
        final invalid1 = await service.addManualDevice('256.1.1.1');
        expect(invalid1, isNull);
        expect(service.errorMessage, 'Invalid IP address format');

        service.clearDevices();

        final invalid2 = await service.addManualDevice('192.168.1');
        expect(invalid2, isNull);

        service.clearDevices();

        final invalid3 = await service.addManualDevice('not.an.ip.address');
        expect(invalid3, isNull);

        service.clearDevices();

        final invalid4 = await service.addManualDevice('192.168.1.1.1');
        expect(invalid4, isNull);

        service.clearDevices();

        final invalid5 = await service.addManualDevice('-1.168.1.1');
        expect(invalid5, isNull);
      });
    });

    test('addManualDevice creates device correctly', () async {
      final device =
          await service.addManualDevice('192.168.1.100', name: 'Test Camera');

      expect(device, isNotNull);
      expect(device!.deviceId, 'manual_192_168_1_100_80');
      expect(device.name, 'Test Camera');
      expect(device.ipAddress, '192.168.1.100');
      expect(device.port, 80);
      expect(device.discoveryMethod, DiscoveryMethod.manual);
    });

    test('device stream emits when device added', () async {
      final devices = <DiscoveredDevice>[];
      service.deviceStream.listen((device) {
        devices.add(device);
      });

      await service.addManualDevice('192.168.1.100', name: 'Test Camera');

      await Future.delayed(const Duration(milliseconds: 50));

      expect(devices.length, 1);
      expect(devices.first.ipAddress, '192.168.1.100');
    });

    test('does not add duplicate devices', () async {
      await service.addManualDevice('192.168.1.100');
      await service.addManualDevice('192.168.1.100');
      await service.addManualDevice('192.168.1.100');

      expect(service.devices.length, 1);
    });

    test('adds different devices', () async {
      await service.addManualDevice('192.168.1.100');
      await service.addManualDevice('192.168.1.101');
      await service.addManualDevice('192.168.1.102');

      expect(service.devices.length, 3);
    });

    test('clearDevices resets state and list', () async {
      await service.addManualDevice('192.168.1.100');
      expect(service.devices.length, 1);

      service.clearDevices();

      expect(service.devices, isEmpty);
      expect(service.state, DiscoveryState.idle);
      expect(service.errorMessage, isNull);
    });

    test('notifies listeners on device added', () async {
      int notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      await service.addManualDevice('192.168.1.100');

      expect(notificationCount, greaterThanOrEqualTo(1));
    });

    test('notifies listeners on clear', () async {
      await service.addManualDevice('192.168.1.100');

      int notificationCount = 0;
      service.addListener(() {
        notificationCount++;
      });

      service.clearDevices();

      expect(notificationCount, 1);
    });

    test('devices list is unmodifiable', () {
      expect(
        () => service.devices.add(DiscoveredDevice.manual('1.1.1.1')),
        throwsUnsupportedError,
      );
    });

    test('startDiscovery returns error when SDK not ready', () async {
      final result = await service.startDiscovery();

      expect(result, isEmpty);
      expect(service.state, DiscoveryState.error);
      expect(service.errorMessage, 'SDK not initialized');
    });

    test('stopDiscovery does nothing when not scanning', () {
      service.stopDiscovery();
      expect(service.state, DiscoveryState.idle);
    });
  });
}
