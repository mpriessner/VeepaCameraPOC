import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/stored_device.dart';

void main() {
  group('StoredDevice', () {
    test('creates from constructor', () {
      final device = StoredDevice(
        deviceId: 'ABC123',
        name: 'Kitchen Camera',
        password: 'secret',
        model: 'VeepaPro',
        addedAt: DateTime(2024, 1, 1),
      );

      expect(device.deviceId, equals('ABC123'));
      expect(device.name, equals('Kitchen Camera'));
      expect(device.password, equals('secret'));
      expect(device.model, equals('VeepaPro'));
      expect(device.lastConnected, isNull);
    });

    test('creates from QR data', () {
      final device = StoredDevice.fromQRData(
        deviceId: 'DEF456',
        password: 'pass',
        name: 'Garage',
        model: 'Basic',
      );

      expect(device.deviceId, equals('DEF456'));
      expect(device.name, equals('Garage'));
      expect(device.addedAt.difference(DateTime.now()).inSeconds.abs(), lessThan(2));
    });

    test('serializes to JSON', () {
      final device = StoredDevice(
        deviceId: 'ABC123',
        name: 'Test',
        password: 'pass',
        addedAt: DateTime(2024, 1, 15, 10, 30),
      );

      final json = device.toJson();

      expect(json['deviceId'], equals('ABC123'));
      expect(json['name'], equals('Test'));
      expect(json['password'], equals('pass'));
      expect(json['addedAt'], contains('2024-01-15'));
    });

    test('deserializes from JSON', () {
      final json = {
        'deviceId': 'XYZ789',
        'name': 'Office',
        'password': 'secret123',
        'model': 'Pro',
        'addedAt': '2024-02-20T14:30:00.000',
        'lastConnected': '2024-02-21T09:00:00.000',
      };

      final device = StoredDevice.fromJson(json);

      expect(device.deviceId, equals('XYZ789'));
      expect(device.name, equals('Office'));
      expect(device.model, equals('Pro'));
      expect(device.lastConnected, isNotNull);
    });

    test('copyWithLastConnected preserves other fields', () {
      final original = StoredDevice(
        deviceId: 'ABC',
        name: 'Test',
        password: 'pass',
        model: 'Model',
        addedAt: DateTime(2024, 1, 1),
      );

      final newTime = DateTime(2024, 6, 15);
      final updated = original.copyWithLastConnected(newTime);

      expect(updated.deviceId, equals(original.deviceId));
      expect(updated.name, equals(original.name));
      expect(updated.password, equals(original.password));
      expect(updated.lastConnected, equals(newTime));
    });

    test('copyWithName preserves other fields', () {
      final original = StoredDevice(
        deviceId: 'ABC',
        name: 'Old Name',
        password: 'pass',
        addedAt: DateTime(2024, 1, 1),
        lastConnected: DateTime(2024, 2, 1),
      );

      final updated = original.copyWithName('New Name');

      expect(updated.deviceId, equals(original.deviceId));
      expect(updated.name, equals('New Name'));
      expect(updated.lastConnected, equals(original.lastConnected));
    });

    test('equality based on deviceId', () {
      final device1 = StoredDevice(
        deviceId: 'ABC',
        name: 'Name 1',
        password: 'pass1',
        addedAt: DateTime(2024, 1, 1),
      );

      final device2 = StoredDevice(
        deviceId: 'ABC',
        name: 'Name 2',
        password: 'pass2',
        addedAt: DateTime(2024, 2, 2),
      );

      final device3 = StoredDevice(
        deviceId: 'XYZ',
        name: 'Name 1',
        password: 'pass1',
        addedAt: DateTime(2024, 1, 1),
      );

      expect(device1, equals(device2)); // Same deviceId
      expect(device1, isNot(equals(device3))); // Different deviceId
    });

    group('list serialization', () {
      test('serializes empty list', () {
        final json = StoredDevice.serializeList([]);
        expect(json, equals('[]'));
      });

      test('serializes and deserializes list', () {
        final devices = [
          StoredDevice(
            deviceId: 'A',
            name: 'Device A',
            password: 'passA',
            addedAt: DateTime(2024, 1, 1),
          ),
          StoredDevice(
            deviceId: 'B',
            name: 'Device B',
            password: 'passB',
            addedAt: DateTime(2024, 2, 2),
          ),
        ];

        final json = StoredDevice.serializeList(devices);
        final restored = StoredDevice.deserializeList(json);

        expect(restored.length, equals(2));
        expect(restored[0].deviceId, equals('A'));
        expect(restored[1].deviceId, equals('B'));
      });

      test('deserializes empty string to empty list', () {
        final devices = StoredDevice.deserializeList('');
        expect(devices, isEmpty);
      });
    });
  });
}
