import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/services/veepa_sdk_manager.dart';

void main() {
  // Initialize Flutter binding for tests that need platform channels
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SDKInitState', () {
    test('displayName returns correct strings', () {
      expect(SDKInitState.uninitialized.displayName, 'Not Started');
      expect(SDKInitState.initializing.displayName, 'Initializing...');
      expect(SDKInitState.initialized.displayName, 'Ready');
      expect(SDKInitState.failed.displayName, 'Failed');
    });

    test('isLoading is true only for initializing state', () {
      expect(SDKInitState.uninitialized.isLoading, isFalse);
      expect(SDKInitState.initializing.isLoading, isTrue);
      expect(SDKInitState.initialized.isLoading, isFalse);
      expect(SDKInitState.failed.isLoading, isFalse);
    });

    test('isReady is true only for initialized state', () {
      expect(SDKInitState.uninitialized.isReady, isFalse);
      expect(SDKInitState.initializing.isReady, isFalse);
      expect(SDKInitState.initialized.isReady, isTrue);
      expect(SDKInitState.failed.isReady, isFalse);
    });

    test('isFailed is true only for failed state', () {
      expect(SDKInitState.uninitialized.isFailed, isFalse);
      expect(SDKInitState.initializing.isFailed, isFalse);
      expect(SDKInitState.initialized.isFailed, isFalse);
      expect(SDKInitState.failed.isFailed, isTrue);
    });
  });

  group('VeepaSDKManager', () {
    late VeepaSDKManager manager;

    setUp(() {
      manager = VeepaSDKManager();
      manager.reset();
    });

    test('manager starts in uninitialized state', () {
      expect(manager.initState, SDKInitState.uninitialized);
      expect(manager.isReady, isFalse);
      expect(manager.errorMessage, isNull);
    });

    test('SDK initializes successfully', () async {
      expect(manager.initState, SDKInitState.uninitialized);

      final result = await manager.initialize();

      expect(result, isTrue);
      expect(manager.initState, SDKInitState.initialized);
      expect(manager.isReady, isTrue);
      expect(manager.errorMessage, isNull);
    });

    test('SDK manager notifies listeners on state change', () async {
      int notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      await manager.initialize();

      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    test('reset clears SDK state', () async {
      await manager.initialize();
      expect(manager.initState, SDKInitState.initialized);

      manager.reset();

      expect(manager.initState, SDKInitState.uninitialized);
      expect(manager.errorMessage, isNull);
      expect(manager.p2pApi, isNull);
    });

    test('double initialization returns early', () async {
      await manager.initialize();
      expect(manager.initState, SDKInitState.initialized);

      final result = await manager.initialize();
      expect(result, isTrue);
      expect(manager.initState, SDKInitState.initialized);
    });

    test('isReady returns correct value', () async {
      expect(manager.isReady, isFalse);

      await manager.initialize();

      expect(manager.isReady, isTrue);
    });
  });
}
