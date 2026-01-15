import 'dart:convert';
import 'hardware_test_runner.dart';

/// Quality gate definition
class QualityGate {
  final String name;
  final String metric;
  final double threshold;
  final bool passIfBelow; // true if passing requires value < threshold

  const QualityGate({
    required this.name,
    required this.metric,
    required this.threshold,
    required this.passIfBelow,
  });

  bool evaluate(double value) {
    return passIfBelow ? value < threshold : value >= threshold;
  }
}

/// Result of quality gate validation
class QualityGateResult {
  final QualityGate gate;
  final double actualValue;
  final bool passed;

  QualityGateResult({
    required this.gate,
    required this.actualValue,
    required this.passed,
  });

  Map<String, dynamic> toJson() => {
        'name': gate.name,
        'metric': gate.metric,
        'threshold': gate.threshold,
        'actualValue': actualValue,
        'passed': passed,
        'passCondition': gate.passIfBelow ? 'below threshold' : 'above threshold',
      };
}

/// Quality gate validation results
class QualityGateReport {
  final DateTime timestamp;
  final String deviceId;
  final List<QualityGateResult> results;

  QualityGateReport({
    required this.timestamp,
    required this.deviceId,
    required this.results,
  });

  int get passed => results.where((r) => r.passed).length;
  int get failed => results.where((r) => !r.passed).length;
  int get total => results.length;
  bool get allPassed => failed == 0;

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'deviceId': deviceId,
        'passed': passed,
        'failed': failed,
        'total': total,
        'allPassed': allPassed,
        'results': results.map((r) => r.toJson()).toList(),
      };

  String toJsonString() => const JsonEncoder.withIndent('  ').convert(toJson());

  String toCSV() {
    final buffer = StringBuffer();
    buffer.writeln('Gate Name,Metric,Threshold,Actual Value,Passed');
    for (final result in results) {
      buffer.writeln(
        '${result.gate.name},${result.gate.metric},${result.gate.threshold},${result.actualValue},${result.passed}',
      );
    }
    return buffer.toString();
  }
}

/// Validator for quality gates
class QualityGateValidator {
  /// Standard quality gates
  static const List<QualityGate> standardGates = [
    QualityGate(
      name: 'Connection Time',
      metric: 'connectionTimeMs',
      threshold: 10000, // 10 seconds
      passIfBelow: true,
    ),
    QualityGate(
      name: 'Time to First Frame',
      metric: 'timeToFirstFrameMs',
      threshold: 5000, // 5 seconds
      passIfBelow: true,
    ),
    QualityGate(
      name: 'Frame Rate',
      metric: 'averageFps',
      threshold: 10, // 10 FPS minimum
      passIfBelow: false,
    ),
    QualityGate(
      name: 'PTZ Latency',
      metric: 'responseTimeMs',
      threshold: 500, // 500ms max
      passIfBelow: true,
    ),
    QualityGate(
      name: 'Error Rate',
      metric: 'errors',
      threshold: 1, // 0 errors (must be below 1)
      passIfBelow: true,
    ),
  ];

  /// Validate test results against quality gates
  static QualityGateReport validate({
    required TestSuiteResults testResults,
    List<QualityGate>? customGates,
  }) {
    final gates = customGates ?? standardGates;
    final gateResults = <QualityGateResult>[];

    // Extract metrics from test results
    final metrics = _extractMetrics(testResults);

    for (final gate in gates) {
      final value = metrics[gate.metric] ?? 0.0;
      final passed = gate.evaluate(value);

      gateResults.add(QualityGateResult(
        gate: gate,
        actualValue: value,
        passed: passed,
      ));
    }

    return QualityGateReport(
      timestamp: DateTime.now(),
      deviceId: testResults.deviceId,
      results: gateResults,
    );
  }

  /// Extract metrics from test results
  static Map<String, double> _extractMetrics(TestSuiteResults results) {
    final metrics = <String, double>{};

    for (final result in results.results) {
      if (result.metrics != null) {
        result.metrics!.forEach((key, value) {
          if (value is num) {
            // Keep first value or worst value depending on metric
            if (!metrics.containsKey(key)) {
              metrics[key] = value.toDouble();
            } else {
              // For time metrics, keep the worst (highest) value
              if (key.contains('Time') || key.contains('Ms')) {
                metrics[key] = value > metrics[key]! ? value.toDouble() : metrics[key]!;
              }
              // For rate metrics, keep average
              else if (key.contains('Rate') || key.contains('Fps')) {
                metrics[key] = (metrics[key]! + value.toDouble()) / 2;
              }
              // For error counts, sum
              else if (key.contains('error') || key.contains('Error')) {
                metrics[key] = metrics[key]! + value.toDouble();
              }
            }
          }
        });
      }
    }

    return metrics;
  }

  /// Generate recommendations for failed gates
  static List<String> getRecommendations(QualityGateReport report) {
    final recommendations = <String>[];

    for (final result in report.results) {
      if (!result.passed) {
        final gate = result.gate;

        switch (gate.name) {
          case 'Connection Time':
            recommendations.add(
              'Connection is slow (${result.actualValue.toInt()}ms). '
              'Consider using LAN mode instead of P2P for faster connections.',
            );
            break;

          case 'Time to First Frame':
            recommendations.add(
              'Video takes too long to start (${result.actualValue.toInt()}ms). '
              'Check network bandwidth and camera quality settings.',
            );
            break;

          case 'Frame Rate':
            recommendations.add(
              'Frame rate is low (${result.actualValue.toStringAsFixed(1)} FPS). '
              'Reduce video resolution or improve network conditions.',
            );
            break;

          case 'PTZ Latency':
            recommendations.add(
              'PTZ response is slow (${result.actualValue.toInt()}ms). '
              'This may affect user experience with manual camera control.',
            );
            break;

          case 'Error Rate':
            recommendations.add(
              'Errors occurred during testing (${result.actualValue.toInt()}). '
              'Check camera firmware and network stability.',
            );
            break;

          default:
            recommendations.add(
              '${gate.name} failed: ${result.actualValue} vs threshold ${gate.threshold}',
            );
        }
      }
    }

    return recommendations;
  }
}
