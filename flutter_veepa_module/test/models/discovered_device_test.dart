import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';

void main() {
  group('DiscoveredDevice', () {
    test('creates from SDK data', () {
      final device = DiscoveredDevice.fromSDK({
        'id': 'ABC123',
        'name': 'Living Room Camera',
        'ip': '192.168.1.50',
        'model': 'IPC-200',
        'online': true,
      });

      expect(device.deviceId, 'ABC123');
      expect(device.name, 'Living Room Camera');
      expect(device.ipAddress, '192.168.1.50');
      expect(device.model, 'IPC-200');
      expect(device.isOnline, true);
      expect(device.discoveryMethod, DiscoveryMethod.lanScan);
    });

    test('creates from SDK data with alternate keys', () {
      final device = DiscoveredDevice.fromSDK({
        'deviceId': 'DEF456',
        'deviceName': 'Kitchen Camera',
        'ipAddress': '192.168.1.51',
      });

      expect(device.deviceId, 'DEF456');
      expect(device.name, 'Kitchen Camera');
      expect(device.ipAddress, '192.168.1.51');
    });

    test('creates from SDK data with defaults', () {
      final device = DiscoveredDevice.fromSDK({});

      expect(device.deviceId, '');
      expect(device.name, 'Unknown Camera');
      expect(device.ipAddress, isNull);
      expect(device.isOnline, true);
    });

    test('creates manual device', () {
      final device = DiscoveredDevice.manual('10.0.0.5', name: 'Office Cam');

      expect(device.deviceId, 'manual_10_0_0_5_80');
      expect(device.name, 'Office Cam');
      expect(device.ipAddress, '10.0.0.5');
      expect(device.port, 80);
      expect(device.discoveryMethod, DiscoveryMethod.manual);
    });

    test('creates manual device with custom port', () {
      final device = DiscoveredDevice.manual('10.0.0.5', port: 8080);

      expect(device.deviceId, 'manual_10_0_0_5_8080');
      expect(device.port, 8080);
    });

    test('creates manual device with default name', () {
      final device = DiscoveredDevice.manual('192.168.1.100');

      expect(device.name, 'Camera at 192.168.1.100');
    });

    test('equality based on deviceId', () {
      final device1 = DiscoveredDevice.manual('192.168.1.1');
      final device2 = DiscoveredDevice.manual('192.168.1.1');
      final device3 = DiscoveredDevice.manual('192.168.1.2');

      expect(device1, equals(device2));
      expect(device1, isNot(equals(device3)));
    });

    test('hashCode based on deviceId', () {
      final device1 = DiscoveredDevice.manual('192.168.1.1');
      final device2 = DiscoveredDevice.manual('192.168.1.1');

      expect(device1.hashCode, equals(device2.hashCode));
    });

    test('toString returns formatted string', () {
      final device = DiscoveredDevice.manual('192.168.1.1', name: 'Test');

      expect(
          device.toString(),
          contains('DiscoveredDevice'));
      expect(device.toString(), contains('192.168.1.1'));
      expect(device.toString(), contains('Test'));
    });

    test('fullAddress returns IP only for port 80', () {
      final device = DiscoveredDevice.manual('192.168.1.1', port: 80);
      expect(device.fullAddress, '192.168.1.1');
    });

    test('fullAddress includes port for non-standard ports', () {
      final device = DiscoveredDevice.manual('192.168.1.1', port: 8080);
      expect(device.fullAddress, '192.168.1.1:8080');
    });

    test('fullAddress returns empty string for null IP', () {
      final device = DiscoveredDevice(
        deviceId: 'test',
        name: 'Test',
        discoveryMethod: DiscoveryMethod.cloudLookup,
        discoveredAt: DateTime.now(),
      );
      expect(device.fullAddress, '');
    });

    test('default port is 80', () {
      final device = DiscoveredDevice.fromSDK({
        'id': 'test',
        'ip': '192.168.1.1',
      });
      expect(device.port, 80);
    });
  });

  group('DiscoveryMethod', () {
    test('has all expected values', () {
      expect(DiscoveryMethod.values, contains(DiscoveryMethod.lanScan));
      expect(DiscoveryMethod.values, contains(DiscoveryMethod.cloudLookup));
      expect(DiscoveryMethod.values, contains(DiscoveryMethod.manual));
    });
  });
}
