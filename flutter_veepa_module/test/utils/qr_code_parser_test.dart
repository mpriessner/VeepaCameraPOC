import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/utils/qr_code_parser.dart';

void main() {
  group('QRCodeParser', () {
    group('parse - JSON format', () {
      test('parses standard JSON format', () {
        final data = '{"id":"VSTC123456789ABC","pwd":"admin123","model":"VeepaCam"}';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('VSTC123456789ABC'));
        expect(result.password, equals('admin123'));
        expect(result.model, equals('VeepaCam'));
      });

      test('parses JSON with alternative field names', () {
        final data = '{"deviceId":"ABC123","password":"secret","name":"My Camera"}';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('ABC123'));
        expect(result.password, equals('secret'));
        expect(result.name, equals('My Camera'));
      });

      test('uses default password when not provided', () {
        final data = '{"id":"VSTC123456"}';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('VSTC123456'));
        expect(result.password, equals('admin'));
      });

      test('throws on missing device ID in JSON', () {
        final data = '{"pwd":"admin","model":"Camera"}';

        expect(
          () => QRCodeParser.parse(data),
          throwsA(isA<QRParseException>()),
        );
      });

      test('throws on invalid JSON', () {
        final data = '{invalid json}';

        expect(
          () => QRCodeParser.parse(data),
          throwsA(isA<QRParseException>()),
        );
      });
    });

    group('parse - VSTC format', () {
      test('parses full VSTC format', () {
        final data = 'VSTC:DEVICE123:password:ModelX';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('DEVICE123'));
        expect(result.password, equals('password'));
        expect(result.model, equals('ModelX'));
      });

      test('parses VSTC with only device and password', () {
        final data = 'VSTC:DEVICE456:mypass';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('DEVICE456'));
        expect(result.password, equals('mypass'));
        expect(result.model, isNull);
      });

      test('parses case-insensitive VSTC prefix', () {
        final data = 'vstc:device789:pass';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('device789'));
      });

      test('uses default password when not provided', () {
        final data = 'VSTC:ONLYDEVICE';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('ONLYDEVICE'));
        expect(result.password, equals('admin'));
      });
    });

    group('parse - URL format', () {
      test('parses URL format with query params', () {
        final data = 'vstc://DEVICE123?pwd=secret&model=ProCam';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('DEVICE123'));
        expect(result.password, equals('secret'));
        expect(result.model, equals('ProCam'));
      });

      test('parses URL format with alternative param names', () {
        final data = 'vstc://ABC456?password=test&name=Kitchen';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('ABC456'));
        expect(result.password, equals('test'));
        expect(result.name, equals('Kitchen'));
      });
    });

    group('parse - simple format', () {
      test('parses deviceId:password format', () {
        final data = 'VSTC123456:mypassword';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('VSTC123456'));
        expect(result.password, equals('mypassword'));
      });

      test('parses deviceId:password:model format', () {
        final data = 'ABCD1234:pass:Model1';
        final result = QRCodeParser.parse(data);

        expect(result.deviceId, equals('ABCD1234'));
        expect(result.password, equals('pass'));
        expect(result.model, equals('Model1'));
      });
    });

    group('parse - error cases', () {
      test('throws on empty string', () {
        expect(
          () => QRCodeParser.parse(''),
          throwsA(isA<QRParseException>()),
        );
      });

      test('throws on whitespace only', () {
        expect(
          () => QRCodeParser.parse('   '),
          throwsA(isA<QRParseException>()),
        );
      });

      test('throws on unrecognized format', () {
        expect(
          () => QRCodeParser.parse('random text here'),
          throwsA(isA<QRParseException>()),
        );
      });
    });

    group('isVeepaQRCode', () {
      test('recognizes VSTC prefix', () {
        expect(QRCodeParser.isVeepaQRCode('VSTC:device:pass'), isTrue);
        expect(QRCodeParser.isVeepaQRCode('vstc:device:pass'), isTrue);
      });

      test('recognizes JSON format with id field', () {
        expect(QRCodeParser.isVeepaQRCode('{"id":"device"}'), isTrue);
      });

      test('recognizes URL format', () {
        expect(QRCodeParser.isVeepaQRCode('vstc://device?pwd=pass'), isTrue);
      });

      test('recognizes device ID pattern', () {
        expect(QRCodeParser.isVeepaQRCode('VSTC123456789:admin'), isTrue);
      });

      test('rejects random text', () {
        expect(QRCodeParser.isVeepaQRCode('hello world'), isFalse);
      });

      test('rejects URLs to other domains', () {
        expect(QRCodeParser.isVeepaQRCode('https://google.com'), isFalse);
      });
    });
  });

  group('VeepaQRData', () {
    test('equality works correctly', () {
      final data1 = VeepaQRData(deviceId: 'ABC', password: 'pass');
      final data2 = VeepaQRData(deviceId: 'ABC', password: 'pass');
      final data3 = VeepaQRData(deviceId: 'XYZ', password: 'pass');

      expect(data1, equals(data2));
      expect(data1, isNot(equals(data3)));
    });

    test('toString provides useful output', () {
      final data = VeepaQRData(
        deviceId: 'ABC123',
        password: 'pass',
        model: 'Pro',
      );

      expect(data.toString(), contains('ABC123'));
      expect(data.toString(), contains('Pro'));
    });
  });

  group('QRParseException', () {
    test('toString includes message', () {
      final exception = QRParseException('Test error', 'raw data');

      expect(exception.toString(), contains('Test error'));
    });

    test('stores raw data', () {
      final exception = QRParseException('Error', 'original qr data');

      expect(exception.rawData, equals('original qr data'));
    });
  });
}
