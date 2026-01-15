import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/wifi_discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WifiDiscoveryService service;

  setUp(() {
    service = WifiDiscoveryService();
    service.reset();
  });

  tearDown(() {
    service.reset();
  });

  group('WifiDiscoveryService', () {
    test('is a singleton', () {
      final service1 = WifiDiscoveryService();
      final service2 = WifiDiscoveryService();
      expect(identical(service1, service2), isTrue);
    });

    test('starts with disconnected state', () {
      expect(service.currentWifi.isConnected, isFalse);
      expect(service.currentWifi.isVeepaAP, isFalse);
      expect(service.isMonitoring, isFalse);
    });

    test('setWifiInfo updates state', () {
      final info = WifiInfo.connected('TestNetwork');
      service.setWifiInfo(info);

      expect(service.currentWifi.isConnected, isTrue);
      expect(service.currentWifi.ssid, equals('TestNetwork'));
    });

    test('detects Veepa AP from SSID', () {
      final veepaInfo = WifiInfo.connected('VEEPA_ABC123');
      service.setWifiInfo(veepaInfo);

      expect(service.isConnectedToVeepaAP, isTrue);
    });

    test('detects VSTC AP from SSID', () {
      final vstcInfo = WifiInfo.connected('VSTC_XYZ789');
      service.setWifiInfo(vstcInfo);

      expect(service.isConnectedToVeepaAP, isTrue);
    });

    test('does not detect regular WiFi as Veepa AP', () {
      final regularInfo = WifiInfo.connected('HomeNetwork');
      service.setWifiInfo(regularInfo);

      expect(service.isConnectedToVeepaAP, isFalse);
    });

    test('triggers onVeepaAPDetected callback', () {
      bool callbackTriggered = false;
      service.onVeepaAPDetected = () => callbackTriggered = true;

      service.setWifiInfo(WifiInfo.connected('VEEPA_TEST'));

      expect(callbackTriggered, isTrue);
    });

    test('triggers onVeepaAPLost callback', () {
      // First connect to Veepa AP
      service.setWifiInfo(WifiInfo.connected('VEEPA_TEST'));

      bool callbackTriggered = false;
      service.onVeepaAPLost = () => callbackTriggered = true;

      // Then switch to regular network
      service.setWifiInfo(WifiInfo.connected('HomeNetwork'));

      expect(callbackTriggered, isTrue);
    });

    test('triggers onWifiChanged callback', () {
      WifiInfo? receivedInfo;
      service.onWifiChanged = (info) => receivedInfo = info;

      service.setWifiInfo(WifiInfo.connected('TestNet'));

      expect(receivedInfo, isNotNull);
      expect(receivedInfo?.ssid, equals('TestNet'));
    });

    test('reset clears all state', () {
      service.setWifiInfo(WifiInfo.connected('VEEPA_TEST'));
      service.onVeepaAPDetected = () {};

      service.reset();

      expect(service.currentWifi.isConnected, isFalse);
      expect(service.isMonitoring, isFalse);
    });
  });

  group('WifiInfo', () {
    test('disconnected factory creates disconnected state', () {
      final info = WifiInfo.disconnected();

      expect(info.isConnected, isFalse);
      expect(info.isVeepaAP, isFalse);
      expect(info.ssid, isNull);
    });

    test('connected factory sets connected state', () {
      final info = WifiInfo.connected('TestSSID');

      expect(info.isConnected, isTrue);
      expect(info.ssid, equals('TestSSID'));
    });

    test('detects VEEPA_ prefix as Veepa AP', () {
      expect(WifiInfo.connected('VEEPA_12345').isVeepaAP, isTrue);
      expect(WifiInfo.connected('veepa_test').isVeepaAP, isTrue);
    });

    test('detects VSTC_ prefix as Veepa AP', () {
      expect(WifiInfo.connected('VSTC_ABC').isVeepaAP, isTrue);
      expect(WifiInfo.connected('vstc_xyz').isVeepaAP, isTrue);
    });

    test('detects hyphen variants as Veepa AP', () {
      expect(WifiInfo.connected('VEEPA-123').isVeepaAP, isTrue);
      expect(WifiInfo.connected('VSTC-456').isVeepaAP, isTrue);
    });

    test('regular SSIDs not detected as Veepa AP', () {
      expect(WifiInfo.connected('MyHomeWifi').isVeepaAP, isFalse);
      expect(WifiInfo.connected('OfficeNetwork').isVeepaAP, isFalse);
      expect(WifiInfo.connected('VEEPACAM').isVeepaAP, isFalse); // No underscore
    });
  });

  group('isVeepaSSID static method', () {
    test('identifies Veepa SSIDs correctly', () {
      expect(WifiDiscoveryService.isVeepaSSID('VEEPA_123'), isTrue);
      expect(WifiDiscoveryService.isVeepaSSID('VSTC_ABC'), isTrue);
      expect(WifiDiscoveryService.isVeepaSSID('HomeNetwork'), isFalse);
    });
  });
}
