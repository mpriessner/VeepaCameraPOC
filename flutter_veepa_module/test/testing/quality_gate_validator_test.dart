import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/testing/hardware_test_runner.dart';
import 'package:veepa_camera_poc/testing/quality_gate_validator.dart';

void main() {
  group('QualityGate', () {
    test('evaluates passIfBelow correctly', () {
      const gate = QualityGate(
        name: 'Connection Time',
        metric: 'connectionTimeMs',
        threshold: 10000,
        passIfBelow: true,
      );

      expect(gate.evaluate(5000), isTrue);
      expect(gate.evaluate(15000), isFalse);
    });

    test('evaluates passIfAbove correctly', () {
      const gate = QualityGate(
        name: 'Frame Rate',
        metric: 'fps',
        threshold: 10,
        passIfBelow: false,
      );

      expect(gate.evaluate(15), isTrue);
      expect(gate.evaluate(5), isFalse);
    });
  });

  group('QualityGateResult', () {
    test('toJson returns correct structure', () {
      final result = QualityGateResult(
        gate: const QualityGate(
          name: 'Test Gate',
          metric: 'testMetric',
          threshold: 100,
          passIfBelow: true,
        ),
        actualValue: 50,
        passed: true,
      );

      final json = result.toJson();

      expect(json['name'], equals('Test Gate'));
      expect(json['threshold'], equals(100));
      expect(json['actualValue'], equals(50));
      expect(json['passed'], isTrue);
    });
  });

  group('QualityGateReport', () {
    test('calculates passed and failed', () {
      final report = QualityGateReport(
        timestamp: DateTime.now(),
        deviceId: 'TEST123',
        results: [
          QualityGateResult(
            gate: const QualityGate(
              name: 'Gate1',
              metric: 'm1',
              threshold: 100,
              passIfBelow: true,
            ),
            actualValue: 50,
            passed: true,
          ),
          QualityGateResult(
            gate: const QualityGate(
              name: 'Gate2',
              metric: 'm2',
              threshold: 100,
              passIfBelow: true,
            ),
            actualValue: 150,
            passed: false,
          ),
        ],
      );

      expect(report.passed, equals(1));
      expect(report.failed, equals(1));
      expect(report.total, equals(2));
      expect(report.allPassed, isFalse);
    });

    test('allPassed is true when no failures', () {
      final report = QualityGateReport(
        timestamp: DateTime.now(),
        deviceId: 'TEST123',
        results: [
          QualityGateResult(
            gate: const QualityGate(
              name: 'Gate1',
              metric: 'm1',
              threshold: 100,
              passIfBelow: true,
            ),
            actualValue: 50,
            passed: true,
          ),
        ],
      );

      expect(report.allPassed, isTrue);
    });

    test('toCSV generates valid CSV', () {
      final report = QualityGateReport(
        timestamp: DateTime.now(),
        deviceId: 'TEST123',
        results: [
          QualityGateResult(
            gate: const QualityGate(
              name: 'Test Gate',
              metric: 'metric',
              threshold: 100,
              passIfBelow: true,
            ),
            actualValue: 50,
            passed: true,
          ),
        ],
      );

      final csv = report.toCSV();

      expect(csv, contains('Gate Name,Metric,Threshold,Actual Value,Passed'));
      expect(csv, contains('Test Gate,metric,100.0,50.0,true'));
    });
  });

  group('QualityGateValidator', () {
    test('standardGates has expected gates', () {
      final gates = QualityGateValidator.standardGates;

      expect(gates.any((g) => g.name == 'Connection Time'), isTrue);
      expect(gates.any((g) => g.name == 'Frame Rate'), isTrue);
      expect(gates.any((g) => g.name == 'PTZ Latency'), isTrue);
    });

    test('validate returns report', () {
      final testResults = TestSuiteResults(
        timestamp: DateTime.now(),
        deviceId: 'TEST123',
        results: [
          const TestResult(
            name: 'Connection',
            category: 'Connection',
            passed: true,
            duration: Duration(milliseconds: 500),
            metrics: {'connectionTimeMs': 500},
          ),
        ],
        totalDuration: const Duration(seconds: 1),
      );

      final report = QualityGateValidator.validate(testResults: testResults);

      expect(report.deviceId, equals('TEST123'));
      expect(report.results, isNotEmpty);
    });

    test('getRecommendations returns recommendations for failures', () {
      final report = QualityGateReport(
        timestamp: DateTime.now(),
        deviceId: 'TEST123',
        results: [
          QualityGateResult(
            gate: const QualityGate(
              name: 'Connection Time',
              metric: 'connectionTimeMs',
              threshold: 10000,
              passIfBelow: true,
            ),
            actualValue: 15000,
            passed: false,
          ),
        ],
      );

      final recommendations = QualityGateValidator.getRecommendations(report);

      expect(recommendations, isNotEmpty);
      expect(recommendations.first, contains('Connection'));
    });

    test('getRecommendations returns empty for all passed', () {
      final report = QualityGateReport(
        timestamp: DateTime.now(),
        deviceId: 'TEST123',
        results: [
          QualityGateResult(
            gate: const QualityGate(
              name: 'Frame Rate',
              metric: 'fps',
              threshold: 10,
              passIfBelow: false,
            ),
            actualValue: 30,
            passed: true,
          ),
        ],
      );

      final recommendations = QualityGateValidator.getRecommendations(report);

      expect(recommendations, isEmpty);
    });
  });
}
