import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/models/connection_state.dart';
import 'package:veepa_camera_poc/models/discovered_device.dart';
import 'package:veepa_camera_poc/services/camera_connection_detector.dart';

/// Mock connection manager for testing
class MockConnectionManager implements IConnectionManager {
  bool shouldSucceed = false;
  int connectAttempts = 0;
  int successAfterAttempts = 0; // Succeed after this many attempts
  bool _isConnected = false;

  @override
  ConnectionState get state =>
      _isConnected ? ConnectionState.connected : ConnectionState.disconnected;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect(DiscoveredDevice device) async {
    connectAttempts++;
    await Future.delayed(const Duration(milliseconds: 10));

    if (successAfterAttempts > 0 && connectAttempts >= successAfterAttempts) {
      shouldSucceed = true;
    }

    if (shouldSucceed) {
      _isConnected = true;
    }

    return shouldSucceed;
  }

  @override
  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 5));
    _isConnected = false;
  }

  void reset() {
    shouldSucceed = false;
    _isConnected = false;
    connectAttempts = 0;
    successAfterAttempts = 0;
  }
}

void main() {
  late CameraConnectionDetector detector;
  late MockConnectionManager mockConnectionManager;

  setUp(() {
    mockConnectionManager = MockConnectionManager();
    detector = CameraConnectionDetector(
      connectionManager: mockConnectionManager,
    );
  });

  tearDown(() {
    detector.dispose();
    mockConnectionManager.reset();
  });

  group('CameraConnectionDetector', () {
    group('initial state', () {
      test('starts in idle state', () {
        expect(detector.state, DetectionState.idle);
      });

      test('starts with zero attempts', () {
        expect(detector.attemptCount, 0);
      });

      test('isDetecting is false initially', () {
        expect(detector.isDetecting, false);
      });

      test('progress is 0 initially', () {
        expect(detector.progress, 0.0);
      });
    });

    group('startDetection', () {
      test('transitions to detecting state', () async {
        mockConnectionManager.shouldSucceed = true;

        // Don't await, just start detection
        detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 10),
          pollInterval: const Duration(milliseconds: 50),
        );

        // Give time for state to update
        await Future.delayed(const Duration(milliseconds: 20));

        expect(detector.state, DetectionState.detecting);
        expect(detector.isDetecting, true);
      });

      test('returns success when camera is found immediately', () async {
        mockConnectionManager.shouldSucceed = true;

        final result = await detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 50),
        );

        expect(result.success, true);
        expect(detector.state, DetectionState.found);
      });

      test('returns success after multiple attempts', () async {
        mockConnectionManager.successAfterAttempts = 3;

        final result = await detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 50),
        );

        expect(result.success, true);
        expect(result.attemptCount, greaterThanOrEqualTo(3));
      });

      test('returns timeout when camera not found', () async {
        mockConnectionManager.shouldSucceed = false;

        final result = await detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(milliseconds: 150),
          pollInterval: const Duration(milliseconds: 50),
        );

        expect(result.success, false);
        expect(result.errorMessage, 'Detection timed out');
        expect(detector.state, DetectionState.timeout);
      });

      test('increments attempt count', () async {
        mockConnectionManager.shouldSucceed = false;

        detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 1),
          pollInterval: const Duration(milliseconds: 100),
        );

        // Wait for some attempts
        await Future.delayed(const Duration(milliseconds: 350));

        expect(detector.attemptCount, greaterThanOrEqualTo(2));
      });

      test('calculates progress correctly', () async {
        mockConnectionManager.shouldSucceed = false;

        detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(milliseconds: 200),
          pollInterval: const Duration(milliseconds: 50),
        );

        await Future.delayed(const Duration(milliseconds: 110));

        // Progress should be approximately half
        expect(detector.progress, greaterThan(0.3));
        expect(detector.progress, lessThan(0.8));
      });

      test('includes connection time in result', () async {
        mockConnectionManager.successAfterAttempts = 2;

        final result = await detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 50),
        );

        expect(result.connectionTime, isNotNull);
        expect(result.connectionTime!.inMilliseconds, greaterThan(0));
      });

      test('fails if detection already in progress', () async {
        mockConnectionManager.shouldSucceed = false;

        // Start first detection
        detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 100),
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Try to start another
        final result = await detector.startDetection(
          deviceId: 'TEST456',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 100),
        );

        expect(result.success, false);
        expect(result.errorMessage, 'Detection already in progress');
      });
    });

    group('cancelDetection', () {
      test('cancels ongoing detection', () async {
        mockConnectionManager.shouldSucceed = false;

        final future = detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 100),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        detector.cancelDetection();

        final result = await future;

        expect(result.success, false);
        expect(result.errorMessage, 'Detection cancelled');
        expect(detector.state, DetectionState.idle);
      });

      test('does nothing if not detecting', () {
        detector.cancelDetection();
        expect(detector.state, DetectionState.idle);
      });
    });

    group('reset', () {
      test('resets to initial state', () async {
        mockConnectionManager.shouldSucceed = true;

        await detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 1),
          pollInterval: const Duration(milliseconds: 50),
        );

        detector.reset();

        expect(detector.state, DetectionState.idle);
        expect(detector.attemptCount, 0);
        expect(detector.progress, 0.0);
      });

      test('cancels ongoing detection before reset', () async {
        mockConnectionManager.shouldSucceed = false;

        detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 100),
        );

        await Future.delayed(const Duration(milliseconds: 50));
        detector.reset();

        expect(detector.state, DetectionState.idle);
        expect(detector.isDetecting, false);
      });
    });

    group('notifications', () {
      test('notifies listeners on state changes', () async {
        mockConnectionManager.shouldSucceed = true;

        int notificationCount = 0;
        detector.addListener(() => notificationCount++);

        await detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 1),
          pollInterval: const Duration(milliseconds: 50),
        );

        // Should notify at least for: detecting start, attempt, found
        expect(notificationCount, greaterThanOrEqualTo(2));
      });

      test('notifies listeners on attempt count changes', () async {
        mockConnectionManager.successAfterAttempts = 3;

        int notificationCount = 0;
        detector.addListener(() => notificationCount++);

        await detector.startDetection(
          deviceId: 'TEST123',
          password: 'password',
          timeout: const Duration(seconds: 5),
          pollInterval: const Duration(milliseconds: 50),
        );

        // Should notify for each attempt plus state changes
        expect(notificationCount, greaterThanOrEqualTo(3));
      });
    });

    group('DetectionResult', () {
      test('success factory creates successful result', () {
        final result = DetectionResult.success(
          ipAddress: '192.168.1.100',
          connectionTime: const Duration(seconds: 5),
          attemptCount: 3,
        );

        expect(result.success, true);
        expect(result.ipAddress, '192.168.1.100');
        expect(result.connectionTime, const Duration(seconds: 5));
        expect(result.attemptCount, 3);
        expect(result.errorMessage, isNull);
      });

      test('failure factory creates failed result', () {
        final result = DetectionResult.failure(
          errorMessage: 'Connection refused',
          attemptCount: 5,
        );

        expect(result.success, false);
        expect(result.errorMessage, 'Connection refused');
        expect(result.attemptCount, 5);
      });

      test('timeout factory creates timeout result', () {
        final result = DetectionResult.timeout(attemptCount: 20);

        expect(result.success, false);
        expect(result.errorMessage, 'Detection timed out');
        expect(result.attemptCount, 20);
      });
    });
  });
}
