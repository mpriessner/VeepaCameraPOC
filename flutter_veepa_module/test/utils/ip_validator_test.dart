import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/utils/ip_validator.dart';

void main() {
  group('IPValidator.validate', () {
    test('accepts valid private IPs', () {
      expect(IPValidator.validate('192.168.1.1'), isNull);
      expect(IPValidator.validate('192.168.0.100'), isNull);
      expect(IPValidator.validate('10.0.0.1'), isNull);
      expect(IPValidator.validate('172.16.0.1'), isNull);
    });

    test('accepts valid public IPs', () {
      expect(IPValidator.validate('8.8.8.8'), isNull);
      expect(IPValidator.validate('1.1.1.1'), isNull);
      expect(IPValidator.validate('74.125.224.72'), isNull);
    });

    test('accepts edge case valid IPs', () {
      expect(IPValidator.validate('0.0.0.1'), isNull);
      expect(IPValidator.validate('255.255.255.254'), isNull);
      expect(IPValidator.validate('192.168.1.0'), isNull);
    });

    test('rejects empty input', () {
      expect(IPValidator.validate(''), isNotNull);
      expect(IPValidator.validate('   '), isNotNull);
      expect(IPValidator.validate(null), isNotNull);
    });

    test('rejects invalid format', () {
      expect(IPValidator.validate('192.168.1'), isNotNull);
      expect(IPValidator.validate('192.168.1.1.1'), isNotNull);
      expect(IPValidator.validate('192.168.1.'), isNotNull);
      expect(IPValidator.validate('.192.168.1.1'), isNotNull);
    });

    test('rejects out of range octets', () {
      expect(IPValidator.validate('256.1.1.1'), isNotNull);
      expect(IPValidator.validate('192.168.1.256'), isNotNull);
    });

    test('rejects reserved addresses', () {
      expect(IPValidator.validate('0.0.0.0'), isNotNull);
      expect(IPValidator.validate('255.255.255.255'), isNotNull);
      expect(IPValidator.validate('127.0.0.1'), isNotNull);
    });

    test('rejects non-numeric input', () {
      expect(IPValidator.validate('abc.def.ghi.jkl'), isNotNull);
      expect(IPValidator.validate('192.168.one.1'), isNotNull);
    });
  });

  group('IPValidator.isPrivateIP', () {
    test('detects 10.x.x.x range', () {
      expect(IPValidator.isPrivateIP('10.0.0.1'), isTrue);
      expect(IPValidator.isPrivateIP('10.255.255.255'), isTrue);
    });

    test('detects 172.16-31.x.x range', () {
      expect(IPValidator.isPrivateIP('172.16.0.1'), isTrue);
      expect(IPValidator.isPrivateIP('172.31.255.255'), isTrue);
      expect(IPValidator.isPrivateIP('172.15.0.1'), isFalse);
      expect(IPValidator.isPrivateIP('172.32.0.1'), isFalse);
    });

    test('detects 192.168.x.x range', () {
      expect(IPValidator.isPrivateIP('192.168.0.1'), isTrue);
      expect(IPValidator.isPrivateIP('192.168.255.255'), isTrue);
      expect(IPValidator.isPrivateIP('192.169.0.1'), isFalse);
    });

    test('rejects public IPs', () {
      expect(IPValidator.isPrivateIP('8.8.8.8'), isFalse);
      expect(IPValidator.isPrivateIP('1.1.1.1'), isFalse);
    });
  });

  group('IPValidator.formatWithPort', () {
    test('returns IP only for port 80', () {
      expect(IPValidator.formatWithPort('192.168.1.1', 80), '192.168.1.1');
    });

    test('returns IP only for port 0', () {
      expect(IPValidator.formatWithPort('192.168.1.1', 0), '192.168.1.1');
    });

    test('includes port for non-standard ports', () {
      expect(IPValidator.formatWithPort('192.168.1.1', 8080), '192.168.1.1:8080');
      expect(IPValidator.formatWithPort('192.168.1.1', 554), '192.168.1.1:554');
    });
  });
}
