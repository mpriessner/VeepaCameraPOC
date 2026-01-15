import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connection_tests.dart';
import 'video_tests.dart';
import 'ptz_tests.dart';

/// Result of a single test
class TestResult {
  final String name;
  final String category;
  final bool passed;
  final Duration duration;
  final String? message;
  final Map<String, dynamic>? metrics;

  const TestResult({
    required this.name,
    required this.category,
    required this.passed,
    required this.duration,
    this.message,
    this.metrics,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'passed': passed,
        'durationMs': duration.inMilliseconds,
        'message': message,
        'metrics': metrics,
      };
}

/// Overall test suite results
class TestSuiteResults {
  final DateTime timestamp;
  final String deviceId;
  final List<TestResult> results;
  final Duration totalDuration;

  TestSuiteResults({
    required this.timestamp,
    required this.deviceId,
    required this.results,
    required this.totalDuration,
  });

  int get passed => results.where((r) => r.passed).length;
  int get failed => results.where((r) => !r.passed).length;
  int get total => results.length;
  double get passRate => total > 0 ? passed / total * 100 : 0;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'totalDurationMs': totalDuration.inMilliseconds,
        'passed': passed,
        'failed': failed,
        'total': total,
        'passRate': passRate,
        'results': results.map((r) => r.toJson()).toList(),
      };
}

/// Callback for test progress updates
typedef TestProgressCallback = void Function(String testName, int current, int total);

/// Runner for hardware integration tests
class HardwareTestRunner extends ChangeNotifier {
  final String deviceId;
  final String password;
  final String? deviceName;

  bool _isRunning = false;
  String _currentTest = '';
  int _completedTests = 0;
  int _totalTests = 0;
  final List<TestResult> _results = [];
  TestProgressCallback? onProgress;

  HardwareTestRunner({
    required this.deviceId,
    required this.password,
    this.deviceName,
    this.onProgress,
  });

  /// Whether tests are currently running
  bool get isRunning => _isRunning;

  /// Current test being run
  String get currentTest => _currentTest;

  /// Progress information
  int get completedTests => _completedTests;
  int get totalTests => _totalTests;
  double get progress => _totalTests > 0 ? _completedTests / _totalTests : 0;

  /// Results collected so far
  List<TestResult> get results => List.unmodifiable(_results);

  /// Run all tests
  Future<TestSuiteResults> runAllTests() async {
    if (_isRunning) {
      throw StateError('Tests already running');
    }

    _isRunning = true;
    _results.clear();
    _completedTests = 0;
    notifyListeners();

    final startTime = DateTime.now();
    debugPrint('[TestRunner] Starting hardware tests for $deviceId');

    try {
      // Count total tests
      _totalTests = ConnectionTests.testCount +
          VideoTests.testCount +
          PTZTests.testCount;
      notifyListeners();

      // Run connection tests
      await _runCategory(
        'Connection',
        ConnectionTests(
          deviceId: deviceId,
          password: password,
        ).runAll,
      );

      // Run video tests
      await _runCategory(
        'Video',
        VideoTests(
          deviceId: deviceId,
          password: password,
        ).runAll,
      );

      // Run PTZ tests
      await _runCategory(
        'PTZ',
        PTZTests(
          deviceId: deviceId,
          password: password,
        ).runAll,
      );
    } catch (e) {
      debugPrint('[TestRunner] Error running tests: $e');
    }

    _isRunning = false;
    _currentTest = '';
    notifyListeners();

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);

    debugPrint('[TestRunner] Completed ${_results.length} tests in ${totalDuration.inSeconds}s');

    return TestSuiteResults(
      timestamp: startTime,
      deviceId: deviceId,
      results: List.from(_results),
      totalDuration: totalDuration,
    );
  }

  Future<void> _runCategory(
    String category,
    Future<List<TestResult>> Function() testRunner,
  ) async {
    debugPrint('[TestRunner] Running $category tests');

    final results = await testRunner();
    for (final result in results) {
      _results.add(result);
      _completedTests++;
      _currentTest = result.name;
      onProgress?.call(result.name, _completedTests, _totalTests);
      notifyListeners();
    }
  }

  /// Run a single category of tests
  Future<List<TestResult>> runConnectionTests() async {
    return await ConnectionTests(
      deviceId: deviceId,
      password: password,
    ).runAll();
  }

  Future<List<TestResult>> runVideoTests() async {
    return await VideoTests(
      deviceId: deviceId,
      password: password,
    ).runAll();
  }

  Future<List<TestResult>> runPTZTests() async {
    return await PTZTests(
      deviceId: deviceId,
      password: password,
    ).runAll();
  }

  /// Cancel running tests
  void cancel() {
    _isRunning = false;
    _currentTest = 'Cancelled';
    notifyListeners();
  }

  /// Clear results
  void clearResults() {
    _results.clear();
    _completedTests = 0;
    _totalTests = 0;
    notifyListeners();
  }
}
