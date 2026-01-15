import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/testing/hardware_test_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TestResult', () {
    test('creates with all fields', () {
      final result = TestResult(
        name: 'Test Name',
        category: 'Connection',
        passed: true,
        duration: const Duration(milliseconds: 100),
        message: 'Success',
        metrics: {'latency': 50},
      );

      expect(result.name, equals('Test Name'));
      expect(result.category, equals('Connection'));
      expect(result.passed, isTrue);
      expect(result.duration, equals(const Duration(milliseconds: 100)));
      expect(result.message, equals('Success'));
      expect(result.metrics?['latency'], equals(50));
    });

    test('toJson returns correct structure', () {
      final result = TestResult(
        name: 'Test',
        category: 'Video',
        passed: false,
        duration: const Duration(seconds: 1),
      );

      final json = result.toJson();

      expect(json['name'], equals('Test'));
      expect(json['category'], equals('Video'));
      expect(json['passed'], isFalse);
      expect(json['durationMs'], equals(1000));
    });
  });

  group('TestSuiteResults', () {
    test('calculates passed and failed correctly', () {
      final results = TestSuiteResults(
        timestamp: DateTime.now(),
        deviceId: 'TEST123',
        results: [
          const TestResult(
            name: 'Test1',
            category: 'A',
            passed: true,
            duration: Duration.zero,
          ),
          const TestResult(
            name: 'Test2',
            category: 'A',
            passed: true,
            duration: Duration.zero,
          ),
          const TestResult(
            name: 'Test3',
            category: 'B',
            passed: false,
            duration: Duration.zero,
          ),
        ],
        totalDuration: const Duration(seconds: 5),
      );

      expect(results.passed, equals(2));
      expect(results.failed, equals(1));
      expect(results.total, equals(3));
      expect(results.passRate, closeTo(66.67, 0.01));
    });

    test('toJson returns correct structure', () {
      final results = TestSuiteResults(
        timestamp: DateTime(2024, 1, 15),
        deviceId: 'TEST123',
        results: [],
        totalDuration: const Duration(seconds: 10),
      );

      final json = results.toJson();

      expect(json['deviceId'], equals('TEST123'));
      expect(json['totalDurationMs'], equals(10000));
      expect(json['passed'], equals(0));
      expect(json['failed'], equals(0));
    });
  });

  group('HardwareTestRunner', () {
    test('creates with device info', () {
      final runner = HardwareTestRunner(
        deviceId: 'ABC123',
        password: 'password',
        deviceName: 'Test Camera',
      );

      expect(runner.deviceId, equals('ABC123'));
      expect(runner.deviceName, equals('Test Camera'));
      expect(runner.isRunning, isFalse);
    });

    test('starts not running', () {
      final runner = HardwareTestRunner(
        deviceId: 'ABC123',
        password: 'password',
      );

      expect(runner.isRunning, isFalse);
      expect(runner.completedTests, equals(0));
      expect(runner.totalTests, equals(0));
    });

    test('clearResults empties results', () {
      final runner = HardwareTestRunner(
        deviceId: 'ABC123',
        password: 'password',
      );

      runner.clearResults();

      expect(runner.results, isEmpty);
      expect(runner.completedTests, equals(0));
    });
  });
}
