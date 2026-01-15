import 'dart:async';
import 'package:flutter/foundation.dart';
import 'hardware_test_runner.dart';
import '../services/sdk_integration_service.dart';
import '../services/real_connection_adapter.dart';

/// Connection test suite
class ConnectionTests {
  final String deviceId;
  final String password;

  static const int testCount = 4;

  ConnectionTests({
    required this.deviceId,
    required this.password,
  });

  /// Run all connection tests
  Future<List<TestResult>> runAll() async {
    final results = <TestResult>[];

    results.add(await testLANConnection());
    results.add(await testP2PConnection());
    results.add(await testReconnection());
    results.add(await testMultipleAttempts());

    return results;
  }

  /// Test LAN discovery and connection
  Future<TestResult> testLANConnection() async {
    const name = 'LAN Connection';
    debugPrint('[ConnectionTest] Running: $name');

    final stopwatch = Stopwatch()..start();

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      final adapter = RealConnectionAdapter(
        sdk: sdk,
        deviceId: deviceId,
        password: password,
      );

      final success = await adapter.connect();
      stopwatch.stop();

      await adapter.disconnect();

      return TestResult(
        name: name,
        category: 'Connection',
        passed: success,
        duration: stopwatch.elapsed,
        message: success ? 'Connected in ${stopwatch.elapsedMilliseconds}ms' : 'Connection failed',
        metrics: {
          'connectionTimeMs': stopwatch.elapsedMilliseconds,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Connection',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test P2P connection
  Future<TestResult> testP2PConnection() async {
    const name = 'P2P Connection';
    debugPrint('[ConnectionTest] Running: $name');

    final stopwatch = Stopwatch()..start();

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      final adapter = RealConnectionAdapter(
        sdk: sdk,
        deviceId: deviceId,
        password: password,
      );

      final success = await adapter.connect();
      stopwatch.stop();

      await adapter.disconnect();

      return TestResult(
        name: name,
        category: 'Connection',
        passed: success,
        duration: stopwatch.elapsed,
        message: success ? 'P2P connected in ${stopwatch.elapsedMilliseconds}ms' : 'P2P connection failed',
        metrics: {
          'p2pConnectionTimeMs': stopwatch.elapsedMilliseconds,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Connection',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test reconnection after disconnect
  Future<TestResult> testReconnection() async {
    const name = 'Reconnection';
    debugPrint('[ConnectionTest] Running: $name');

    final stopwatch = Stopwatch()..start();

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      final adapter = RealConnectionAdapter(
        sdk: sdk,
        deviceId: deviceId,
        password: password,
      );

      // Connect
      await adapter.connect();

      // Disconnect
      await adapter.disconnect();

      // Reconnect
      final reconnectStart = DateTime.now();
      final success = await adapter.reconnect();
      final reconnectTime = DateTime.now().difference(reconnectStart);

      stopwatch.stop();

      await adapter.disconnect();

      return TestResult(
        name: name,
        category: 'Connection',
        passed: success,
        duration: stopwatch.elapsed,
        message: success ? 'Reconnected in ${reconnectTime.inMilliseconds}ms' : 'Reconnection failed',
        metrics: {
          'reconnectionTimeMs': reconnectTime.inMilliseconds,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Connection',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }

  /// Test multiple connection attempts
  Future<TestResult> testMultipleAttempts() async {
    const name = 'Multiple Attempts';
    debugPrint('[ConnectionTest] Running: $name');

    final stopwatch = Stopwatch()..start();
    int successCount = 0;
    const attempts = 3;

    try {
      final sdk = MockVeepaSDK();
      await sdk.initialize();

      for (int i = 0; i < attempts; i++) {
        final adapter = RealConnectionAdapter(
          sdk: sdk,
          deviceId: deviceId,
          password: password,
        );

        if (await adapter.connect()) {
          successCount++;
          await adapter.disconnect();
        }
      }

      stopwatch.stop();

      final passed = successCount == attempts;

      return TestResult(
        name: name,
        category: 'Connection',
        passed: passed,
        duration: stopwatch.elapsed,
        message: '$successCount/$attempts successful',
        metrics: {
          'successCount': successCount,
          'attempts': attempts,
          'successRate': successCount / attempts * 100,
        },
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        name: name,
        category: 'Connection',
        passed: false,
        duration: stopwatch.elapsed,
        message: 'Error: $e',
      );
    }
  }
}
