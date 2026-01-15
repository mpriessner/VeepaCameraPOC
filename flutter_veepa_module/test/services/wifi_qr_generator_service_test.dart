import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/wifi_qr_generator_service.dart';
import 'package:veepa_camera_poc/services/camera_config_service.dart';

void main() {
  late WifiQRGeneratorService service;

  setUp(() {
    service = WifiQRGeneratorService();
  });

  group('WifiQRGeneratorService', () {
    group('generateWifiQRData', () {
      test('generates correct format for WPA2 network', () {
        final result = service.generateWifiQRData(
          ssid: 'MyNetwork',
          password: 'mypassword123',
          encryption: WifiEncryption.wpa2,
        );

        expect(result, 'WIFI:T:WPA;S:MyNetwork;P:mypassword123;;');
      });

      test('generates correct format for WPA network', () {
        final result = service.generateWifiQRData(
          ssid: 'TestNetwork',
          password: 'testpass123',
          encryption: WifiEncryption.wpa,
        );

        expect(result, 'WIFI:T:WPA;S:TestNetwork;P:testpass123;;');
      });

      test('generates correct format for WPA3 network', () {
        final result = service.generateWifiQRData(
          ssid: 'SecureNetwork',
          password: 'securepass123',
          encryption: WifiEncryption.wpa3,
        );

        expect(result, 'WIFI:T:WPA;S:SecureNetwork;P:securepass123;;');
      });

      test('generates correct format for WEP network', () {
        final result = service.generateWifiQRData(
          ssid: 'OldNetwork',
          password: 'wepkey12345',
          encryption: WifiEncryption.wep,
        );

        expect(result, 'WIFI:T:WEP;S:OldNetwork;P:wepkey12345;;');
      });

      test('generates correct format for open network', () {
        final result = service.generateWifiQRData(
          ssid: 'OpenNetwork',
          password: '',
          encryption: WifiEncryption.none,
        );

        expect(result, 'WIFI:T:nopass;S:OpenNetwork;;');
      });

      test('includes hidden flag when specified', () {
        final result = service.generateWifiQRData(
          ssid: 'HiddenNetwork',
          password: 'hiddenpass123',
          encryption: WifiEncryption.wpa2,
          isHidden: true,
        );

        expect(result, 'WIFI:T:WPA;S:HiddenNetwork;P:hiddenpass123;H:true;;');
      });

      test('escapes special characters in SSID', () {
        final result = service.generateWifiQRData(
          ssid: 'My;Network:Test',
          password: 'password123',
          encryption: WifiEncryption.wpa2,
        );

        expect(result, contains('S:My\\;Network\\:Test;'));
      });

      test('escapes special characters in password', () {
        final result = service.generateWifiQRData(
          ssid: 'Network',
          password: 'pass;word:123',
          encryption: WifiEncryption.wpa2,
        );

        expect(result, contains('P:pass\\;word\\:123;'));
      });

      test('throws on empty SSID', () {
        expect(
          () => service.generateWifiQRData(ssid: '', password: 'password123'),
          throwsArgumentError,
        );
      });

      test('throws on SSID longer than 32 characters', () {
        expect(
          () => service.generateWifiQRData(
            ssid: 'A' * 33,
            password: 'password123',
          ),
          throwsArgumentError,
        );
      });

      test('throws on password shorter than 8 characters', () {
        expect(
          () => service.generateWifiQRData(
            ssid: 'Network',
            password: 'short',
          ),
          throwsArgumentError,
        );
      });

      test('throws on password longer than 63 characters', () {
        expect(
          () => service.generateWifiQRData(
            ssid: 'Network',
            password: 'A' * 64,
          ),
          throwsArgumentError,
        );
      });

      test('accepts maximum length SSID (32 chars)', () {
        final ssid = 'A' * 32;
        final result = service.generateWifiQRData(
          ssid: ssid,
          password: 'password123',
        );

        expect(result, contains('S:$ssid;'));
      });

      test('accepts maximum length password (63 chars)', () {
        final password = 'A' * 63;
        final result = service.generateWifiQRData(
          ssid: 'Network',
          password: password,
        );

        expect(result, contains('P:$password;'));
      });
    });

    group('generateVeepaQRData', () {
      test('generates valid JSON for WPA2 network', () {
        final result = service.generateVeepaQRData(
          ssid: 'MyNetwork',
          password: 'mypassword123',
          encryption: WifiEncryption.wpa2,
        );

        final decoded = jsonDecode(result);
        expect(decoded['ssid'], 'MyNetwork');
        expect(decoded['pwd'], 'mypassword123');
        expect(decoded['enc'], 'WPA2');
      });

      test('generates valid JSON for WPA network', () {
        final result = service.generateVeepaQRData(
          ssid: 'TestNetwork',
          password: 'testpass123',
          encryption: WifiEncryption.wpa,
        );

        final decoded = jsonDecode(result);
        expect(decoded['enc'], 'WPA');
      });

      test('generates valid JSON for WPA3 network', () {
        final result = service.generateVeepaQRData(
          ssid: 'SecureNetwork',
          password: 'securepass123',
          encryption: WifiEncryption.wpa3,
        );

        final decoded = jsonDecode(result);
        expect(decoded['enc'], 'WPA3');
      });

      test('generates valid JSON for WEP network', () {
        final result = service.generateVeepaQRData(
          ssid: 'OldNetwork',
          password: 'wepkey12345',
          encryption: WifiEncryption.wep,
        );

        final decoded = jsonDecode(result);
        expect(decoded['enc'], 'WEP');
      });

      test('generates valid JSON for open network', () {
        final result = service.generateVeepaQRData(
          ssid: 'OpenNetwork',
          password: '',
          encryption: WifiEncryption.none,
        );

        final decoded = jsonDecode(result);
        expect(decoded['enc'], 'NONE');
      });

      test('throws on invalid credentials', () {
        expect(
          () => service.generateVeepaQRData(ssid: '', password: 'password123'),
          throwsArgumentError,
        );
      });

      test('preserves special characters in JSON', () {
        final result = service.generateVeepaQRData(
          ssid: 'My;Network:Test',
          password: 'pass;word:123',
          encryption: WifiEncryption.wpa2,
        );

        final decoded = jsonDecode(result);
        expect(decoded['ssid'], 'My;Network:Test');
        expect(decoded['pwd'], 'pass;word:123');
      });
    });

    group('validateCredentials', () {
      test('returns valid for correct credentials', () {
        final result = service.validateCredentials('MyNetwork', 'password123');
        expect(result.isValid, true);
        expect(result.errorMessage, null);
      });

      test('returns invalid for empty SSID', () {
        final result = service.validateCredentials('', 'password123');
        expect(result.isValid, false);
        expect(result.errorMessage, 'SSID cannot be empty');
      });

      test('returns invalid for SSID too long', () {
        final result = service.validateCredentials('A' * 33, 'password123');
        expect(result.isValid, false);
        expect(result.errorMessage, 'SSID must be 32 characters or less');
      });

      test('returns invalid for password too short', () {
        final result = service.validateCredentials('Network', 'short');
        expect(result.isValid, false);
        expect(result.errorMessage, 'Password must be at least 8 characters');
      });

      test('returns invalid for password too long', () {
        final result = service.validateCredentials('Network', 'A' * 64);
        expect(result.isValid, false);
        expect(result.errorMessage, 'Password must be 63 characters or less');
      });

      test('accepts empty password for open networks', () {
        final result = service.validateCredentials('OpenNetwork', '');
        expect(result.isValid, true);
      });

      test('accepts exactly 8 character password', () {
        final result = service.validateCredentials('Network', '12345678');
        expect(result.isValid, true);
      });

      test('accepts exactly 63 character password', () {
        final result = service.validateCredentials('Network', 'A' * 63);
        expect(result.isValid, true);
      });
    });
  });
}
