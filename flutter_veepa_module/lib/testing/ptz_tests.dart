import 'dart:async';
import 'package:flutter/foundation.dart';
import 'hardware_test_runner.dart';
import '../services/sdk_integration_service.dart';
import '../services/real_connection_adapter.dart';
import '../services/real_ptz_adapter.dart';

/// PTZ control test suite
class PTZTests {
  final String deviceId;
  final String password;

  static const int testCount = 4;

  PTZTests({
    required this.deviceId,
    required this.password,
  });

  /// Run all PTZ tests
  Future<List<TestResult>> runAll() async {
    final results = <TestResult>[];

    results.add(await testCommandResponse());
    results.add(await testAllDirections());
    results.add(await testStopCommand());
    results.add(await testZoomControls());

    return results;
  }

  /// Test command response time
  Future<TestResult> testCommandResponse() async {
    const name = 'Command Response Time';
    debugPrint('[PTZTest] Running: $name');

    final stopwatch = Stopwatch()..start();

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      final connection = RealConnectionAdapter(
        sdk: sdk,
        deviceId: deviceId,
        password: password,
      );

      await connection.connect();

      final ptz = RealPTZAdapter(connection: connection);

      // Measure command round-trip time
      final commandStart = DateTime.now();
      final success = await ptz.move(PTZDirection.up);
      final commandTime = DateTime.now().difference(commandStart);

      await ptz.stop();

      stopwatch.stop();

      await connection.disconnect();

      final passed = success && commandTime.inMilliseconds < 500; // 500ms threshold

      return TestResult(
        name: name,
        category: 'PTZ',
        passed: passed,
        duration: stopwatch.elapsed,
        message: 'Response in ${commandTime.inMilliseconds}ms',
        metrics: {
          'responseTimeMs': commandTime.inMilliseconds,
          'threshold': 500,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'PTZ',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test all directions work
  Future<TestResult> testAllDirections() async {
    const name = 'All Directions';
    debugPrint('[PTZTest] Running: $name');

    final stopwatch = Stopwatch()..start();

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      final connection = RealConnectionAdapter(
        sdk: sdk,
        deviceId: deviceId,
        password: password,
      );

      await connection.connect();

      final ptz = RealPTZAdapter(connection: connection);
      final directions = [
        PTZDirection.up,
        PTZDirection.down,
        PTZDirection.left,
        PTZDirection.right,
        PTZDirection.upLeft,
        PTZDirection.upRight,
        PTZDirection.downLeft,
        PTZDirection.downRight,
      ];

      int successCount = 0;
      for (final dir in directions) {
        if (await ptz.move(dir)) {
          successCount++;
        }
        await ptz.stop();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      stopwatch.stop();

      await connection.disconnect();

      final passed = successCount == directions.length;

      return TestResult(
        name: name,
        category: 'PTZ',
        passed: passed,
        duration: stopwatch.elapsed,
        message: '$successCount/${directions.length} directions working',
        metrics: {
          'successCount': successCount,
          'totalDirections': directions.length,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'PTZ',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test stop command effectiveness
  Future<TestResult> testStopCommand() async {
    const name = 'Stop Command';
    debugPrint('[PTZTest] Running: $name');

    final stopwatch = Stopwatch()..start();

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      final connection = RealConnectionAdapter(
        sdk: sdk,
        deviceId: deviceId,
        password: password,
      );

      await connection.connect();

      final ptz = RealPTZAdapter(connection: connection);

      // Start moving
      await ptz.move(PTZDirection.left);
      final wasMoving = ptz.isMoving;

      // Stop
      await ptz.stop();
      final stoppedMoving = !ptz.isMoving;

      stopwatch.stop();

      await connection.disconnect();

      final passed = wasMoving && stoppedMoving;

      return TestResult(
        name: name,
        category: 'PTZ',
        passed: passed,
        duration: stopwatch.elapsed,
        message: passed ? 'Stop command works correctly' : 'Stop command failed',
        metrics: {
          'wasMoving': wasMoving,
          'stoppedMoving': stoppedMoving,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'PTZ',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test zoom controls
  Future<TestResult> testZoomControls() async {
    const name = 'Zoom Controls';
    debugPrint('[PTZTest] Running: $name');

    final stopwatch = Stopwatch()..start();

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      final connection = RealConnectionAdapter(
        sdk: sdk,
        deviceId: deviceId,
        password: password,
      );

      await connection.connect();

      final ptz = RealPTZAdapter(connection: connection);

      // Test zoom in
      final zoomInSuccess = await ptz.zoom(ZoomDirection.zoomIn);
      await ptz.stopZoom();

      // Test zoom out
      final zoomOutSuccess = await ptz.zoom(ZoomDirection.zoomOut);
      await ptz.stopZoom();

      stopwatch.stop();

      await connection.disconnect();

      final passed = zoomInSuccess && zoomOutSuccess;

      return TestResult(
        name: name,
        category: 'PTZ',
        passed: passed,
        duration: stopwatch.elapsed,
        message: 'Zoom in: $zoomInSuccess, Zoom out: $zoomOutSuccess',
        metrics: {
          'zoomIn': zoomInSuccess,
          'zoomOut': zoomOutSuccess,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'PTZ',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }
}
