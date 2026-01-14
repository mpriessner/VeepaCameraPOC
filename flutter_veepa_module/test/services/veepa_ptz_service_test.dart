import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/ptz_direction.dart';
import 'package:veepa_camera_poc/services/veepa_ptz_service.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VeepaPTZService service;
  late VeepaConnectionManager connectionManager;

  DiscoveredDevice createTestDevice() {
    return DiscoveredDevice(
      deviceId: 'PTZ_TEST',
      name: 'PTZ Test Camera',
      ipAddress: '192.168.1.100',
      port: 80,
      discoveryMethod: DiscoveryMethod.lanScan,
      discoveredAt: DateTime.now(),
    );
  }

  Future<void> setupConnectedState() async {
    await VeepaSDKManager().initialize();
    await connectionManager.connect(createTestDevice());
  }

  setUp(() {
    service = VeepaPTZService();
    service.reset();
    connectionManager = VeepaConnectionManager();
    connectionManager.reset();
    VeepaSDKManager().reset();
  });

  tearDown(() async {
    service.reset();
    await connectionManager.disconnect();
    connectionManager.reset();
  });

  group('VeepaPTZService', () {
    group('initial state', () {
      test('current direction is stop', () {
        expect(service.currentDirection, PTZDirection.stop);
      });

      test('current zoom is stop', () {
        expect(service.currentZoom, ZoomDirection.stop);
      });

      test('speed is default value', () {
        expect(service.speed, VeepaPTZService.defaultSpeed);
      });

      test('isMoving is false', () {
        expect(service.isMoving, isFalse);
      });

      test('isZooming is false', () {
        expect(service.isZooming, isFalse);
      });

      test('average latency is 0', () {
        expect(service.averageLatency, 0);
      });

      test('latency sample count is 0', () {
        expect(service.latencySampleCount, 0);
      });
    });

    group('speed', () {
      test('sets valid speed', () {
        service.speed = 75;
        expect(service.speed, 75);
      });

      test('clamps speed to max 100', () {
        service.speed = 150;
        expect(service.speed, 100);
      });

      test('clamps speed to min 0', () {
        service.speed = -10;
        expect(service.speed, 0);
      });

      test('notifies listeners on speed change', () {
        int notificationCount = 0;
        service.addListener(() => notificationCount++);

        service.speed = 80;
        expect(notificationCount, 1);
      });
    });

    group('movement when not connected', () {
      test('startMovement returns false', () async {
        final result = await service.startMovement(PTZDirection.panLeft);
        expect(result, isFalse);
      });

      test('startZoom returns false', () async {
        final result = await service.startZoom(ZoomDirection.zoomIn);
        expect(result, isFalse);
      });

      test('direction remains stop after failed movement', () async {
        await service.startMovement(PTZDirection.panLeft);
        expect(service.currentDirection, PTZDirection.stop);
      });
    });

    group('movement when connected', () {
      test('startMovement updates current direction', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panLeft);
        expect(service.currentDirection, PTZDirection.panLeft);
      });

      test('stopMovement sets direction to stop', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panRight);
        await service.stopMovement();
        expect(service.currentDirection, PTZDirection.stop);
      });

      test('startMovement returns true when connected', () async {
        await setupConnectedState();

        final result = await service.startMovement(PTZDirection.tiltUp);
        expect(result, isTrue);
      });

      test('isMoving is true when moving', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.tiltDown);
        expect(service.isMoving, isTrue);
      });

      test('isMoving is false after stop', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panLeft);
        await service.stopMovement();
        expect(service.isMoving, isFalse);
      });

      test('notifies listeners on movement change', () async {
        await setupConnectedState();

        int notificationCount = 0;
        service.addListener(() => notificationCount++);

        await service.startMovement(PTZDirection.panLeft);
        expect(notificationCount, greaterThanOrEqualTo(1));
      });

      test('same direction command returns true without resending', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panLeft);
        final result = await service.startMovement(PTZDirection.panLeft);
        expect(result, isTrue);
        expect(service.currentDirection, PTZDirection.panLeft);
      });
    });

    group('zoom when connected', () {
      test('startZoom updates current zoom', () async {
        await setupConnectedState();

        await service.startZoom(ZoomDirection.zoomIn);
        expect(service.currentZoom, ZoomDirection.zoomIn);
      });

      test('stopZoom sets zoom to stop', () async {
        await setupConnectedState();

        await service.startZoom(ZoomDirection.zoomOut);
        await service.stopZoom();
        expect(service.currentZoom, ZoomDirection.stop);
      });

      test('isZooming is true when zooming', () async {
        await setupConnectedState();

        await service.startZoom(ZoomDirection.zoomIn);
        expect(service.isZooming, isTrue);
      });
    });

    group('convenience methods', () {
      test('panLeft starts pan left movement', () async {
        await setupConnectedState();

        await service.panLeft();
        expect(service.currentDirection, PTZDirection.panLeft);
      });

      test('panRight starts pan right movement', () async {
        await setupConnectedState();

        await service.panRight();
        expect(service.currentDirection, PTZDirection.panRight);
      });

      test('tiltUp starts tilt up movement', () async {
        await setupConnectedState();

        await service.tiltUp();
        expect(service.currentDirection, PTZDirection.tiltUp);
      });

      test('tiltDown starts tilt down movement', () async {
        await setupConnectedState();

        await service.tiltDown();
        expect(service.currentDirection, PTZDirection.tiltDown);
      });

      test('zoomIn starts zoom in', () async {
        await setupConnectedState();

        await service.zoomIn();
        expect(service.currentZoom, ZoomDirection.zoomIn);
      });

      test('zoomOut starts zoom out', () async {
        await setupConnectedState();

        await service.zoomOut();
        expect(service.currentZoom, ZoomDirection.zoomOut);
      });
    });

    group('stopAll', () {
      test('stops both movement and zoom', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panLeft);
        await service.startZoom(ZoomDirection.zoomIn);

        await service.stopAll();

        expect(service.currentDirection, PTZDirection.stop);
        expect(service.currentZoom, ZoomDirection.stop);
        expect(service.isMoving, isFalse);
        expect(service.isZooming, isFalse);
      });
    });

    group('latency tracking', () {
      test('records latency after command', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panLeft);
        expect(service.latencySampleCount, greaterThan(0));
      });

      test('averageLatency calculated correctly', () async {
        await setupConnectedState();

        // Send multiple commands to gather latency samples
        await service.panLeft();
        await service.panRight();
        await service.tiltUp();

        expect(service.averageLatency, greaterThan(0));
      });

      test('resetLatencyHistory clears history', () async {
        await setupConnectedState();

        await service.panLeft();
        expect(service.latencySampleCount, greaterThan(0));

        service.resetLatencyHistory();
        expect(service.latencySampleCount, 0);
        expect(service.averageLatency, 0);
      });

      test('lastLatency returns most recent latency', () async {
        await setupConnectedState();

        await service.panLeft();
        expect(service.lastLatency, isNotNull);
        expect(service.lastLatency, greaterThanOrEqualTo(0));
      });
    });

    group('presets', () {
      test('goToPreset fails when not connected', () async {
        final result = await service.goToPreset(1);
        expect(result, isFalse);
      });

      test('goToPreset succeeds when connected', () async {
        await setupConnectedState();

        final result = await service.goToPreset(1);
        expect(result, isTrue);
      });

      test('goToPreset rejects invalid preset number', () async {
        await setupConnectedState();

        expect(await service.goToPreset(0), isFalse);
        expect(await service.goToPreset(256), isFalse);
        expect(await service.goToPreset(-1), isFalse);
      });

      test('savePreset fails when not connected', () async {
        final result = await service.savePreset(1);
        expect(result, isFalse);
      });

      test('savePreset succeeds when connected', () async {
        await setupConnectedState();

        final result = await service.savePreset(5);
        expect(result, isTrue);
      });
    });

    group('getStatistics', () {
      test('returns statistics map', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panLeft);
        service.speed = 75;

        final stats = service.getStatistics();

        expect(stats['currentDirection'], 'Pan Left');
        expect(stats['speed'], 75);
        expect(stats['isMoving'], isTrue);
        expect(stats.containsKey('averageLatency'), isTrue);
        expect(stats.containsKey('latencySamples'), isTrue);
      });
    });

    group('reset', () {
      test('clears all state', () async {
        await setupConnectedState();

        await service.startMovement(PTZDirection.panLeft);
        await service.startZoom(ZoomDirection.zoomIn);
        service.speed = 80;

        service.reset();

        expect(service.currentDirection, PTZDirection.stop);
        expect(service.currentZoom, ZoomDirection.stop);
        expect(service.speed, VeepaPTZService.defaultSpeed);
        expect(service.latencySampleCount, 0);
      });
    });
  });
}
