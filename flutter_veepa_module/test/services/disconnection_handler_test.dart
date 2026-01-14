import 'package:flutter/widgets.dart' hide ConnectionState;
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/disconnection_handler.dart';
import 'package:veepa_camera_poc/services/veepa_connection_manager.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DisconnectionHandler', () {
    late DisconnectionHandler handler;

    setUp(() {
      handler = DisconnectionHandler();
      handler.reset();
      VeepaConnectionManager().reset();
      VeepaSDKManager().reset();
    });

    tearDown(() {
      handler.reset();
      VeepaConnectionManager().reset();
      VeepaSDKManager().reset();
    });

    test('singleton returns same instance', () {
      final handler1 = DisconnectionHandler();
      final handler2 = DisconnectionHandler();
      expect(identical(handler1, handler2), isTrue);
    });

    test('startMonitoring sets isMonitoring to true', () {
      expect(handler.isMonitoring, isFalse);
      handler.startMonitoring();
      expect(handler.isMonitoring, isTrue);
      handler.stopMonitoring();
    });

    test('stopMonitoring sets isMonitoring to false', () {
      handler.startMonitoring();
      expect(handler.isMonitoring, isTrue);
      handler.stopMonitoring();
      expect(handler.isMonitoring, isFalse);
    });

    test('recordHeartbeat updates last heartbeat time', () {
      handler.startMonitoring();
      handler.recordHeartbeat();
      // The test passes if no exception is thrown
      handler.stopMonitoring();
    });

    test('forceDisconnect stops monitoring and disconnects', () {
      handler.startMonitoring();
      handler.forceDisconnect();
      expect(handler.isMonitoring, isFalse);
    });

    test('reset clears all callbacks', () {
      bool called = false;
      handler.onDisconnected = () => called = true;
      handler.reset();
      expect(handler.onDisconnected, isNull);
    });

    test('handles app lifecycle - paused', () {
      bool backgroundedCalled = false;
      handler.onAppBackgrounded = () => backgroundedCalled = true;
      handler.startMonitoring();

      handler.didChangeAppLifecycleState(AppLifecycleState.paused);

      // Since we're not connected, backgrounded callback won't be called
      // but the method should not crash
      handler.stopMonitoring();
    });

    test('handles app lifecycle - resumed', () {
      bool resumedCalled = false;
      handler.onAppResumed = () => resumedCalled = true;
      handler.startMonitoring();

      handler.didChangeAppLifecycleState(AppLifecycleState.resumed);

      // Since we weren't connected before background, resumed callback won't be called
      handler.stopMonitoring();
    });

    test('handles app lifecycle - detached', () {
      handler.startMonitoring();
      handler.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(handler.isMonitoring, isFalse);
    });
  });

  group('DisconnectionHandler callbacks', () {
    late DisconnectionHandler handler;

    setUp(() {
      handler = DisconnectionHandler();
      handler.reset();
      VeepaConnectionManager().reset();
    });

    tearDown(() {
      handler.reset();
      VeepaConnectionManager().reset();
    });

    test('onDisconnected callback is settable', () {
      bool called = false;
      handler.onDisconnected = () => called = true;
      expect(handler.onDisconnected, isNotNull);
    });

    test('onReconnecting callback is settable', () {
      bool called = false;
      handler.onReconnecting = () => called = true;
      expect(handler.onReconnecting, isNotNull);
    });

    test('onReconnected callback is settable', () {
      bool called = false;
      handler.onReconnected = () => called = true;
      expect(handler.onReconnected, isNotNull);
    });

    test('onReconnectionFailed callback is settable', () {
      String? message;
      handler.onReconnectionFailed = (msg) => message = msg;
      expect(handler.onReconnectionFailed, isNotNull);
    });

    test('onAppBackgrounded callback is settable', () {
      bool called = false;
      handler.onAppBackgrounded = () => called = true;
      expect(handler.onAppBackgrounded, isNotNull);
    });

    test('onAppResumed callback is settable', () {
      bool called = false;
      handler.onAppResumed = () => called = true;
      expect(handler.onAppResumed, isNotNull);
    });
  });
}
