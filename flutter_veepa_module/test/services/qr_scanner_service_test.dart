import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/qr_scanner_service.dart';
import 'package:veepa_camera_poc/utils/qr_code_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QRScannerService service;

  setUp(() {
    service = QRScannerService();
    service.reset();
  });

  tearDown(() {
    service.reset();
  });

  group('QRScannerService', () {
    test('is a singleton', () {
      final service1 = QRScannerService();
      final service2 = QRScannerService();
      expect(identical(service1, service2), isTrue);
    });

    group('scanning state', () {
      test('starts not scanning', () {
        expect(service.isScanning, isFalse);
      });

      test('startScanning sets isScanning true', () {
        service.startScanning();
        expect(service.isScanning, isTrue);
      });

      test('stopScanning sets isScanning false', () {
        service.startScanning();
        service.stopScanning();
        expect(service.isScanning, isFalse);
      });
    });

    group('processQRCode', () {
      test('processes valid VSTC QR code', () {
        final result = service.processQRCode('VSTC:DEVICE123:password:Model');

        expect(result.isSuccess, isTrue);
        expect(result.parsedData!.deviceId, equals('DEVICE123'));
        expect(result.parsedData!.password, equals('password'));
      });

      test('processes valid JSON QR code', () {
        final result = service.processQRCode('{"id":"ABC123","pwd":"secret"}');

        expect(result.isSuccess, isTrue);
        expect(result.parsedData!.deviceId, equals('ABC123'));
      });

      test('returns failure for invalid QR code', () {
        final result = service.processQRCode('not a valid qr code');

        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
      });

      test('returns failure for empty QR code', () {
        final result = service.processQRCode('');

        expect(result.isSuccess, isFalse);
      });

      test('updates lastResult', () {
        service.processQRCode('VSTC:DEVICE1:pass');
        expect(service.lastResult, isNotNull);
        expect(service.lastResult!.parsedData!.deviceId, equals('DEVICE1'));

        service.processQRCode('VSTC:DEVICE2:pass');
        expect(service.lastResult!.parsedData!.deviceId, equals('DEVICE2'));
      });

      test('adds to scan history', () {
        expect(service.scanHistory.length, equals(0));

        service.processQRCode('VSTC:DEVICE1:pass');
        expect(service.scanHistory.length, equals(1));

        service.processQRCode('VSTC:DEVICE2:pass');
        expect(service.scanHistory.length, equals(2));
      });
    });

    group('callbacks', () {
      test('calls onScanComplete for successful scan', () {
        QRScanResult? capturedResult;
        service.onScanComplete = (result) => capturedResult = result;

        service.processQRCode('VSTC:DEVICE123:pass');

        expect(capturedResult, isNotNull);
        expect(capturedResult!.isSuccess, isTrue);
      });

      test('calls onError for failed scan', () {
        String? capturedError;
        service.onError = (error) => capturedError = error;

        service.processQRCode('invalid qr');

        expect(capturedError, isNotNull);
      });

      test('does not call onScanComplete for failed scan', () {
        bool wasCalled = false;
        service.onScanComplete = (result) => wasCalled = true;

        service.processQRCode('invalid qr');

        expect(wasCalled, isFalse);
      });
    });

    group('isValidDeviceId', () {
      test('accepts valid device IDs', () {
        expect(service.isValidDeviceId('VSTC12345678'), isTrue);
        expect(service.isValidDeviceId('ABC123456789'), isTrue);
        expect(service.isValidDeviceId('abcd1234'), isTrue);
      });

      test('rejects empty string', () {
        expect(service.isValidDeviceId(''), isFalse);
      });

      test('rejects too short IDs', () {
        expect(service.isValidDeviceId('ABC'), isFalse);
      });

      test('rejects IDs with special characters', () {
        expect(service.isValidDeviceId('ABC-123-456'), isFalse);
        expect(service.isValidDeviceId('ABC_123'), isFalse);
      });
    });

    group('scan counts', () {
      test('counts successful scans', () {
        service.processQRCode('VSTC:DEVICE1:pass');
        service.processQRCode('VSTC:DEVICE2:pass');
        service.processQRCode('invalid');

        expect(service.successfulScanCount, equals(2));
      });

      test('counts failed scans', () {
        service.processQRCode('invalid1');
        service.processQRCode('invalid2');
        service.processQRCode('VSTC:DEVICE:pass');

        expect(service.failedScanCount, equals(2));
      });
    });

    group('clearHistory', () {
      test('clears scan history', () {
        service.processQRCode('VSTC:DEVICE:pass');
        expect(service.scanHistory.length, equals(1));

        service.clearHistory();
        expect(service.scanHistory.length, equals(0));
      });

      test('clears last result', () {
        service.processQRCode('VSTC:DEVICE:pass');
        expect(service.lastResult, isNotNull);

        service.clearHistory();
        expect(service.lastResult, isNull);
      });
    });

    group('reset', () {
      test('resets all state', () {
        service.startScanning();
        service.processQRCode('VSTC:DEVICE:pass');
        service.onScanComplete = (r) {};
        service.onError = (e) {};

        service.reset();

        expect(service.isScanning, isFalse);
        expect(service.scanHistory.length, equals(0));
        expect(service.lastResult, isNull);
      });
    });
  });

  group('QRScanResult', () {
    test('success factory creates successful result', () {
      final data = VeepaQRData(deviceId: 'ABC', password: 'pass');
      final result = QRScanResult.success('raw', data);

      expect(result.isSuccess, isTrue);
      expect(result.parsedData, equals(data));
      expect(result.error, isNull);
    });

    test('failure factory creates failed result', () {
      final result = QRScanResult.failure('raw', 'error message');

      expect(result.isSuccess, isFalse);
      expect(result.error, equals('error message'));
      expect(result.parsedData, isNull);
    });

    test('includes timestamp', () {
      final before = DateTime.now();
      final result = QRScanResult.success(
        'raw',
        VeepaQRData(deviceId: 'ABC', password: 'pass'),
      );
      final after = DateTime.now();

      expect(result.timestamp.isAfter(before.subtract(Duration(seconds: 1))), isTrue);
      expect(result.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
    });
  });
}
