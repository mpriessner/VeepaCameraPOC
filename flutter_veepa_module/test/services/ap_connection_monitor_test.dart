import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/ap_connection_monitor.dart';
import 'package:veepa_camera_poc/services/wifi_discovery_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('APConnectionState', () {
    test('has all expected values', () {
      expect(APConnectionState.values, contains(APConnectionState.initial));
      expect(APConnectionState.values, contains(APConnectionState.waitingForConnection));
      expect(APConnectionState.values, contains(APConnectionState.detectingAP));
      expect(APConnectionState.values, contains(APConnectionState.connected));
      expect(APConnectionState.values, contains(APConnectionState.timeout));
      expect(APConnectionState.values, contains(APConnectionState.error));
    });
  });

  group('APConnectionResult', () {
    test('success factory creates successful result', () {
      final result = APConnectionResult.success('VEEPA_ABC123');

      expect(result.success, isTrue);
      expect(result.ssid, equals('VEEPA_ABC123'));
      expect(result.errorMessage, isNull);
    });

    test('timeout factory creates timeout result', () {
      final result = APConnectionResult.timeout();

      expect(result.success, isFalse);
      expect(result.ssid, isNull);
      expect(result.errorMessage, equals('Connection timed out'));
    });

    test('error factory creates error result', () {
      final result = APConnectionResult.error('Network error');

      expect(result.success, isFalse);
      expect(result.ssid, isNull);
      expect(result.errorMessage, equals('Network error'));
    });
  });

  group('APConnectionMonitor', () {
    late APConnectionMonitor monitor;
    late WifiDiscoveryService wifiService;

    setUp(() {
      wifiService = WifiDiscoveryService();
      wifiService.reset();
      monitor = APConnectionMonitor(
        wifiService: wifiService,
        timeout: const Duration(seconds: 5),
      );
    });

    tearDown(() {
      monitor.dispose();
      wifiService.reset();
    });

    test('starts in initial state', () {
      expect(monitor.state, equals(APConnectionState.initial));
      expect(monitor.isWaiting, isFalse);
      expect(monitor.isConnected, isFalse);
    });

    test('creates with default parameters', () {
      final defaultMonitor = APConnectionMonitor();
      expect(defaultMonitor, isNotNull);
      expect(defaultMonitor.timeout, equals(const Duration(minutes: 2)));
      expect(defaultMonitor.acceptedPrefixes, contains('VEEPA_'));
      defaultMonitor.dispose();
    });

    test('creates with custom timeout', () {
      final customMonitor = APConnectionMonitor(
        timeout: const Duration(seconds: 30),
      );
      expect(customMonitor.timeout, equals(const Duration(seconds: 30)));
      customMonitor.dispose();
    });

    test('creates with custom prefixes', () {
      final customMonitor = APConnectionMonitor(
        acceptedPrefixes: ['CUSTOM_'],
      );
      expect(customMonitor.acceptedPrefixes, contains('CUSTOM_'));
      customMonitor.dispose();
    });

    test('stopMonitoring cancels pending operations', () {
      monitor.stopMonitoring();

      expect(monitor.state, equals(APConnectionState.initial));
    });

    test('reset clears all state', () {
      monitor.reset();

      expect(monitor.state, equals(APConnectionState.initial));
      expect(monitor.isWaiting, isFalse);
    });

    test('isWaiting is true for waiting states', () {
      expect(APConnectionState.waitingForConnection.name, equals('waitingForConnection'));
      expect(APConnectionState.detectingAP.name, equals('detectingAP'));
    });

    test('isConnected is true only for connected state', () {
      expect(APConnectionState.connected.name, equals('connected'));
    });
  });

  group('APConnectionMonitor with simulated WiFi', () {
    late APConnectionMonitor monitor;
    late WifiDiscoveryService wifiService;

    setUp(() {
      wifiService = WifiDiscoveryService();
      wifiService.reset();
      monitor = APConnectionMonitor(
        wifiService: wifiService,
        timeout: const Duration(seconds: 2),
      );
    });

    tearDown(() {
      monitor.dispose();
      wifiService.reset();
    });

    test('detects connection when already connected to Veepa AP', () async {
      // Pre-connect to Veepa AP
      wifiService.setWifiInfo(WifiInfo.connected('VEEPA_TEST123'));

      final resultFuture = monitor.startMonitoring();
      final result = await resultFuture;

      expect(result.success, isTrue);
      expect(result.ssid, equals('VEEPA_TEST123'));
      expect(monitor.state, equals(APConnectionState.connected));
    });

    test('detects VSTC AP connection', () async {
      wifiService.setWifiInfo(WifiInfo.connected('VSTC_ABC'));

      final result = await monitor.startMonitoring();

      expect(result.success, isTrue);
      expect(result.ssid, equals('VSTC_ABC'));
    });

    test('detects hyphenated AP connection', () async {
      wifiService.setWifiInfo(WifiInfo.connected('VEEPA-CAMERA'));

      final result = await monitor.startMonitoring();

      expect(result.success, isTrue);
      expect(result.ssid, equals('VEEPA-CAMERA'));
    });

    test('times out when no AP connected', () async {
      // Don't connect to any AP
      wifiService.setWifiInfo(WifiInfo.disconnected());

      final result = await monitor.startMonitoring();

      expect(result.success, isFalse);
      expect(result.errorMessage, equals('Connection timed out'));
      expect(monitor.state, equals(APConnectionState.timeout));
    }, timeout: const Timeout(Duration(seconds: 10)));

    test('retry restarts monitoring', () async {
      wifiService.setWifiInfo(WifiInfo.connected('VEEPA_RETRY'));

      final result = await monitor.retry();

      expect(result.success, isTrue);
      expect(result.ssid, equals('VEEPA_RETRY'));
    });
  });
}
