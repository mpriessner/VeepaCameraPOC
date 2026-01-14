import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veepa_camera_poc/models/stored_device.dart';
import 'package:veepa_camera_poc/services/device_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DeviceStorageService service;

  setUp(() async {
    // Set up mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    service = DeviceStorageService();
    service.reset();
  });

  tearDown(() {
    service.reset();
  });

  group('DeviceStorageService', () {
    test('is a singleton', () {
      final service1 = DeviceStorageService();
      final service2 = DeviceStorageService();
      expect(identical(service1, service2), isTrue);
    });

    test('initializes with empty list', () async {
      await service.initialize();
      expect(service.isInitialized, isTrue);
      expect(service.devices, isEmpty);
    });

    test('loads devices from storage on initialize', () async {
      final devices = [
        StoredDevice(
          deviceId: 'ABC',
          name: 'Test',
          password: 'pass',
          addedAt: DateTime(2024, 1, 1),
        ),
      ];

      SharedPreferences.setMockInitialValues({
        'veepa_stored_devices': StoredDevice.serializeList(devices),
      });

      service.reset();
      await service.initialize();

      expect(service.devices.length, equals(1));
      expect(service.devices[0].deviceId, equals('ABC'));
    });

    group('saveDevice', () {
      test('saves a new device', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'NEW123',
          password: 'pass',
          name: 'New Camera',
        );

        final result = await service.saveDevice(device);

        expect(result, isTrue);
        expect(service.deviceCount, equals(1));
        expect(service.hasDevice('NEW123'), isTrue);
      });

      test('rejects duplicate device', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'DUP',
          password: 'pass',
          name: 'First',
        );

        await service.saveDevice(device);

        final duplicate = StoredDevice.fromQRData(
          deviceId: 'DUP',
          password: 'other',
          name: 'Second',
        );

        final result = await service.saveDevice(duplicate);

        expect(result, isFalse);
        expect(service.deviceCount, equals(1));
      });
    });

    group('updateDevice', () {
      test('updates existing device', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'UPD',
          password: 'pass',
          name: 'Original',
        );
        await service.saveDevice(device);

        final updated = device.copyWithName('Updated');
        final result = await service.updateDevice(updated);

        expect(result, isTrue);
        expect(service.getDevice('UPD')?.name, equals('Updated'));
      });

      test('returns false for non-existent device', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'MISSING',
          password: 'pass',
          name: 'Test',
        );

        final result = await service.updateDevice(device);
        expect(result, isFalse);
      });
    });

    group('deleteDevice', () {
      test('deletes existing device', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'DEL',
          password: 'pass',
          name: 'To Delete',
        );
        await service.saveDevice(device);

        expect(service.deviceCount, equals(1));

        final result = await service.deleteDevice('DEL');

        expect(result, isTrue);
        expect(service.deviceCount, equals(0));
      });

      test('returns false for non-existent device', () async {
        await service.initialize();

        final result = await service.deleteDevice('MISSING');
        expect(result, isFalse);
      });
    });

    group('getDevice', () {
      test('returns device if exists', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'GET',
          password: 'pass',
          name: 'Test',
        );
        await service.saveDevice(device);

        final found = service.getDevice('GET');
        expect(found, isNotNull);
        expect(found?.name, equals('Test'));
      });

      test('returns null if not exists', () async {
        await service.initialize();

        final found = service.getDevice('MISSING');
        expect(found, isNull);
      });
    });

    group('updateLastConnected', () {
      test('updates last connected time', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'CONN',
          password: 'pass',
          name: 'Test',
        );
        await service.saveDevice(device);

        expect(service.getDevice('CONN')?.lastConnected, isNull);

        await service.updateLastConnected('CONN');

        expect(service.getDevice('CONN')?.lastConnected, isNotNull);
      });
    });

    group('renameDevice', () {
      test('renames existing device', () async {
        await service.initialize();

        final device = StoredDevice.fromQRData(
          deviceId: 'RENAME',
          password: 'pass',
          name: 'Old Name',
        );
        await service.saveDevice(device);

        final result = await service.renameDevice('RENAME', 'New Name');

        expect(result, isTrue);
        expect(service.getDevice('RENAME')?.name, equals('New Name'));
      });
    });

    group('sorting', () {
      test('devicesSortedByRecent returns most recent first', () async {
        await service.initialize();

        final device1 = StoredDevice(
          deviceId: 'A',
          name: 'Older',
          password: 'pass',
          addedAt: DateTime(2024, 1, 1),
          lastConnected: DateTime(2024, 1, 5),
        );

        final device2 = StoredDevice(
          deviceId: 'B',
          name: 'Newer',
          password: 'pass',
          addedAt: DateTime(2024, 2, 1),
          lastConnected: DateTime(2024, 2, 10),
        );

        await service.saveDevice(device1);
        await service.saveDevice(device2);

        final sorted = service.devicesSortedByRecent;
        expect(sorted[0].deviceId, equals('B')); // More recent
        expect(sorted[1].deviceId, equals('A'));
      });

      test('devicesSortedByName returns alphabetical', () async {
        await service.initialize();

        final device1 = StoredDevice.fromQRData(
          deviceId: 'A',
          password: 'pass',
          name: 'Zebra',
        );

        final device2 = StoredDevice.fromQRData(
          deviceId: 'B',
          password: 'pass',
          name: 'Apple',
        );

        await service.saveDevice(device1);
        await service.saveDevice(device2);

        final sorted = service.devicesSortedByName;
        expect(sorted[0].name, equals('Apple'));
        expect(sorted[1].name, equals('Zebra'));
      });
    });

    group('clearAll', () {
      test('removes all devices', () async {
        await service.initialize();

        await service.saveDevice(StoredDevice.fromQRData(
          deviceId: 'A',
          password: 'pass',
          name: 'A',
        ));
        await service.saveDevice(StoredDevice.fromQRData(
          deviceId: 'B',
          password: 'pass',
          name: 'B',
        ));

        expect(service.deviceCount, equals(2));

        await service.clearAll();

        expect(service.deviceCount, equals(0));
      });
    });
  });
}
