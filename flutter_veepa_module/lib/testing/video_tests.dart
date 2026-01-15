import 'dart:async';
import 'package:flutter/foundation.dart';
import 'hardware_test_runner.dart';
import '../services/sdk_integration_service.dart';
import '../services/real_connection_adapter.dart';
import '../services/real_video_adapter.dart';

/// Video streaming test suite
class VideoTests {
  final String deviceId;
  final String password;

  static const int testCount = 4;

  VideoTests({
    required this.deviceId,
    required this.password,
  });

  /// Run all video tests
  Future<List<TestResult>> runAll() async {
    final results = <TestResult>[];

    results.add(await testTimeToFirstFrame());
    results.add(await testFrameRateStability());
    results.add(await testResolutionVerification());
    results.add(await testStreamDuration());

    return results;
  }

  /// Test time to first frame
  Future<TestResult> testTimeToFirstFrame() async {
    const name = 'Time to First Frame';
    debugPrint('[VideoTest] Running: $name');

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

      final video = RealVideoAdapter(connection: connection);
      final playStart = DateTime.now();

      final completer = Completer<Duration>();
      video.onFrameUpdate = (metrics) {
        if (!completer.isCompleted && metrics.frameCount > 0) {
          completer.complete(DateTime.now().difference(playStart));
        }
      };

      await video.play();

      // Wait for first frame or timeout
      final firstFrameTime = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => const Duration(seconds: 10),
      );

      stopwatch.stop();

      await video.stop();
      await connection.disconnect();

      final passed = firstFrameTime.inMilliseconds < 5000; // 5s threshold

      return TestResult(
        name: name,
        category: 'Video',
        passed: passed,
        duration: stopwatch.elapsed,
        message: 'First frame in ${firstFrameTime.inMilliseconds}ms',
        metrics: {
          'timeToFirstFrameMs': firstFrameTime.inMilliseconds,
          'threshold': 5000,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Video',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test frame rate stability
  Future<TestResult> testFrameRateStability() async {
    const name = 'Frame Rate Stability';
    debugPrint('[VideoTest] Running: $name');

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

      final video = RealVideoAdapter(connection: connection);
      final fpsReadings = <double>[];

      video.onFrameUpdate = (metrics) {
        if (metrics.fps > 0) {
          fpsReadings.add(metrics.fps);
        }
      };

      await video.play();

      // Collect FPS readings for 3 seconds
      await Future.delayed(const Duration(seconds: 3));

      stopwatch.stop();

      await video.stop();
      await connection.disconnect();

      double avgFps = 0;
      if (fpsReadings.isNotEmpty) {
        avgFps = fpsReadings.reduce((a, b) => a + b) / fpsReadings.length;
      }

      final passed = avgFps >= 10; // 10 FPS threshold

      return TestResult(
        name: name,
        category: 'Video',
        passed: passed,
        duration: stopwatch.elapsed,
        message: 'Average FPS: ${avgFps.toStringAsFixed(1)}',
        metrics: {
          'averageFps': avgFps,
          'readings': fpsReadings.length,
          'threshold': 10,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Video',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test resolution verification
  Future<TestResult> testResolutionVerification() async {
    const name = 'Resolution Verification';
    debugPrint('[VideoTest] Running: $name');

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

      final video = RealVideoAdapter(connection: connection);
      int detectedWidth = 0;
      int detectedHeight = 0;

      video.onFrameUpdate = (metrics) {
        if (metrics.width > 0 && metrics.height > 0) {
          detectedWidth = metrics.width;
          detectedHeight = metrics.height;
        }
      };

      await video.play();
      await Future.delayed(const Duration(seconds: 1));

      stopwatch.stop();

      await video.stop();
      await connection.disconnect();

      final passed = detectedWidth > 0 && detectedHeight > 0;

      return TestResult(
        name: name,
        category: 'Video',
        passed: passed,
        duration: stopwatch.elapsed,
        message: 'Resolution: ${detectedWidth}x$detectedHeight',
        metrics: {
          'width': detectedWidth,
          'height': detectedHeight,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Video',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test stream duration (stability test)
  Future<TestResult> testStreamDuration() async {
    const name = 'Stream Duration';
    debugPrint('[VideoTest] Running: $name');

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

      final video = RealVideoAdapter(connection: connection);
      int frameCount = 0;
      int errors = 0;

      video.onFrameUpdate = (metrics) {
        frameCount = metrics.frameCount;
      };

      await video.play();

      // Stream for 5 seconds
      await Future.delayed(const Duration(seconds: 5));

      final finalState = video.state;
      if (finalState == VideoPlaybackState.error) {
        errors++;
      }

      stopwatch.stop();

      await video.stop();
      await connection.disconnect();

      final passed = errors == 0 && frameCount > 0;

      return TestResult(
        name: name,
        category: 'Video',
        passed: passed,
        duration: stopwatch.elapsed,
        message: 'Streamed $frameCount frames, $errors errors',
        metrics: {
          'frameCount': frameCount,
          'errors': errors,
          'durationSeconds': 5,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Video',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }
}
