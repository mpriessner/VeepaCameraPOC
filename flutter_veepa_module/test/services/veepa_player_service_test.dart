import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/player_state.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/veepa_player_service.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late VeepaPlayerService service;
  late VeepaConnectionManager connectionManager;
  late VeepaSDKManager sdkManager;

  DiscoveredDevice createTestDevice({String name = 'Test Camera', String id = 'test-123'}) {
    return DiscoveredDevice(
      name: name,
      ipAddress: '192.168.1.100',
      deviceId: id,
      model: 'Test Model',
      discoveryMethod: DiscoveryMethod.manual,
      discoveredAt: DateTime.now(),
    );
  }

  /// Setup SDK and connection for tests that need them
  Future<void> setupConnectedState() async {
    await sdkManager.initialize();
    await connectionManager.connect(createTestDevice());
    await Future.delayed(const Duration(milliseconds: 600));
  }

  setUp(() {
    service = VeepaPlayerService();
    service.reset();
    connectionManager = VeepaConnectionManager();
    connectionManager.reset();
    sdkManager = VeepaSDKManager();
  });

  tearDown(() {
    service.reset();
    connectionManager.reset();
  });

  group('VeepaPlayerService', () {
    test('is singleton', () {
      final instance1 = VeepaPlayerService();
      final instance2 = VeepaPlayerService();
      expect(identical(instance1, instance2), true);
    });

    test('initial state is stopped', () {
      expect(service.state, PlayerState.stopped);
    });

    test('initial errorMessage is null', () {
      expect(service.errorMessage, null);
    });

    test('initial device is null', () {
      expect(service.device, null);
    });

    test('initial currentFPS is 0', () {
      expect(service.currentFPS, 0);
    });

    group('start', () {
      test('fails when not connected', () async {
        // Ensure disconnected state explicitly (handle singleton interference)
        await connectionManager.disconnect();
        service.reset();

        final device = createTestDevice();

        final result = await service.start(device);

        expect(result, false);
        expect(service.state, PlayerState.error);
        expect(service.errorMessage, contains('Not connected'));
      });

      test('transitions to buffering when connected', () async {
        await setupConnectedState();

        final device = createTestDevice();

        // Start should initiate buffering
        service.start(device);

        // Check buffering state immediately
        await Future.delayed(const Duration(milliseconds: 50));
        expect(service.state, PlayerState.buffering);
        expect(service.device, device);
      });

      test('sets device when starting', () async {
        await setupConnectedState();

        final device = createTestDevice(name: 'Test Camera 2', id: 'test-456');

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(service.device?.name, 'Test Camera 2');
        expect(service.device?.deviceId, 'test-456');
      });
    });

    group('stop', () {
      test('transitions to stopped state', () async {
        await setupConnectedState();

        final device = createTestDevice();

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 50));

        await service.stop();

        expect(service.state, PlayerState.stopped);
        expect(service.device, null);
        expect(service.currentFPS, 0);
      });
    });

    group('pause', () {
      test('does nothing when not playing', () {
        service.pause();
        expect(service.state, PlayerState.stopped);
      });
    });

    group('resume', () {
      test('does nothing when not paused', () {
        service.resume();
        expect(service.state, PlayerState.stopped);
      });
    });

    group('handleFrameReceived', () {
      test('transitions from buffering to playing', () async {
        await setupConnectedState();

        final device = createTestDevice();

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(service.state, PlayerState.buffering);

        // Simulate frame received
        service.handleFrameReceived(
          Uint8List.fromList([1, 2, 3]),
          640,
          480,
        );

        expect(service.state, PlayerState.playing);
      });

      test('calls onFrameReceived callback', () async {
        await setupConnectedState();

        Uint8List? receivedData;
        int? receivedWidth;
        int? receivedHeight;

        service.onFrameReceived = (data, width, height) {
          receivedData = data;
          receivedWidth = width;
          receivedHeight = height;
        };

        final device = createTestDevice();

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 50));

        service.handleFrameReceived(
          Uint8List.fromList([1, 2, 3]),
          640,
          480,
        );

        expect(receivedData, Uint8List.fromList([1, 2, 3]));
        expect(receivedWidth, 640);
        expect(receivedHeight, 480);
      });
    });

    group('handleStreamError', () {
      test('transitions to error state', () async {
        await setupConnectedState();

        final device = createTestDevice();

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 50));

        service.handleStreamError('Connection lost');

        expect(service.state, PlayerState.error);
        expect(service.errorMessage, 'Connection lost');
      });
    });

    group('stateStream', () {
      test('emits state changes', () async {
        await setupConnectedState();

        final states = <PlayerState>[];
        final subscription = service.stateStream.listen((state) {
          states.add(state);
        });

        final device = createTestDevice();

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 100));

        service.handleFrameReceived(
          Uint8List.fromList([1, 2, 3]),
          640,
          480,
        );
        await Future.delayed(const Duration(milliseconds: 50));

        await subscription.cancel();

        expect(states, contains(PlayerState.buffering));
        expect(states, contains(PlayerState.playing));
      });
    });

    group('notifyListeners', () {
      test('notifies on state change', () async {
        await setupConnectedState();

        var notifyCount = 0;
        service.addListener(() {
          notifyCount++;
        });

        final device = createTestDevice();

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifyCount, greaterThan(0));
      });
    });

    group('reset', () {
      test('resets all state', () async {
        await setupConnectedState();

        final device = createTestDevice();

        service.start(device);
        await Future.delayed(const Duration(milliseconds: 100));

        service.reset();

        expect(service.state, PlayerState.stopped);
        expect(service.errorMessage, null);
        expect(service.device, null);
        expect(service.currentFPS, 0);
        expect(service.onFrameReceived, null);
      });
    });
  });
}
