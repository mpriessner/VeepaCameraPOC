import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/camera_event_channel.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Map<String, dynamic>> sentEvents;

  setUp(() {
    sentEvents = [];
    VeepaConnectionManager().reset();
    VeepaPlayerService().reset();

    // Mock the method channel to capture sent events
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.veepapoc/camera_events_out'),
      (MethodCall call) async {
        if (call.method == 'sendEvent') {
          sentEvents.add(Map<String, dynamic>.from(call.arguments as Map));
        }
        return null;
      },
    );
  });

  tearDown(() {
    CameraEventChannel.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.veepapoc/camera_events_out'),
      null,
    );
    VeepaConnectionManager().reset();
    VeepaPlayerService().reset();
  });

  group('CameraEventChannel', () {
    test('setup completes without error', () {
      expect(() => CameraEventChannel.setup(), returnsNormally);
    });

    test('setup can be called multiple times safely', () {
      CameraEventChannel.setup();
      expect(() => CameraEventChannel.setup(), returnsNormally);
    });

    test('dispose cleans up resources', () {
      CameraEventChannel.setup();
      expect(() => CameraEventChannel.dispose(), returnsNormally);
    });

    test('sendFrameRate sends correct event', () async {
      CameraEventChannel.setup();
      CameraEventChannel.sendFrameRate(24.5);

      // Allow async operation to complete
      await Future.delayed(Duration.zero);

      expect(sentEvents.any((e) =>
          e['type'] == 'frameRate' && e['fps'] == 24.5), isTrue);
    });

    test('sendError sends correct event', () async {
      CameraEventChannel.setup();
      CameraEventChannel.sendError('Test error message');

      await Future.delayed(Duration.zero);

      expect(sentEvents.any((e) =>
          e['type'] == 'error' && e['message'] == 'Test error message'), isTrue);
    });

    test('sendPTZState sends correct event', () async {
      CameraEventChannel.setup();
      CameraEventChannel.sendPTZState('tiltUp', 50, true);

      await Future.delayed(Duration.zero);

      expect(sentEvents.any((e) =>
          e['type'] == 'ptzState' &&
          e['direction'] == 'tiltUp' &&
          e['speed'] == 50 &&
          e['isMoving'] == true), isTrue);
    });

    test('sendDeviceInfo sends correct event', () async {
      CameraEventChannel.setup();
      CameraEventChannel.sendDeviceInfo('device-123', 'Test Camera', '192.168.1.100');

      await Future.delayed(Duration.zero);

      expect(sentEvents.any((e) =>
          e['type'] == 'deviceInfo' &&
          e['deviceId'] == 'device-123' &&
          e['deviceName'] == 'Test Camera' &&
          e['ipAddress'] == '192.168.1.100'), isTrue);
    });

    test('events include timestamp', () async {
      CameraEventChannel.setup();
      final beforeTime = DateTime.now().millisecondsSinceEpoch;
      CameraEventChannel.sendFrameRate(30.0);
      final afterTime = DateTime.now().millisecondsSinceEpoch;

      await Future.delayed(Duration.zero);

      final event = sentEvents.firstWhere((e) => e['type'] == 'frameRate');
      expect(event['timestamp'], greaterThanOrEqualTo(beforeTime));
      expect(event['timestamp'], lessThanOrEqualTo(afterTime));
    });

    test('handles multiple rapid events', () async {
      CameraEventChannel.setup();

      for (int i = 0; i < 10; i++) {
        CameraEventChannel.sendFrameRate(15.0 + i);
      }

      await Future.delayed(Duration.zero);

      final frameRateEvents = sentEvents.where((e) => e['type'] == 'frameRate');
      expect(frameRateEvents.length, equals(10));
    });
  });
}
