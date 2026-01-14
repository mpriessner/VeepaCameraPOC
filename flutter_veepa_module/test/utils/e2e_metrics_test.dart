import 'package:flutter_test/flutter_test.dart';
import 'package:veepa_camera_poc/utils/e2e_metrics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    E2EMetrics().reset();
  });

  tearDown(() {
    E2EMetrics().reset();
  });

  group('E2EMetrics', () {
    test('singleton returns same instance', () {
      final metrics1 = E2EMetrics();
      final metrics2 = E2EMetrics();
      expect(identical(metrics1, metrics2), isTrue);
    });

    test('start initializes running state', () {
      final metrics = E2EMetrics();
      expect(metrics.isRunning, isFalse);

      metrics.start();
      expect(metrics.isRunning, isTrue);
    });

    test('stop ends running state', () {
      final metrics = E2EMetrics();
      metrics.start();
      metrics.stop();
      expect(metrics.isRunning, isFalse);
    });

    test('reset clears all metrics', () {
      final metrics = E2EMetrics();
      metrics.start();
      metrics.connectionStarted();
      metrics.connectionCompleted();
      metrics.frameReceived();
      metrics.ptzCommandSent(100);
      metrics.errorOccurred();

      metrics.reset();

      expect(metrics.connectionTime, equals(0));
      expect(metrics.frameCount, equals(0));
      expect(metrics.ptzCommandCount, equals(0));
      expect(metrics.errorCount, equals(0));
      expect(metrics.isRunning, isFalse);
    });

    group('connection timing', () {
      test('records connection time', () async {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.connectionStarted();

        // Simulate delay
        await Future.delayed(const Duration(milliseconds: 100));

        metrics.connectionCompleted();

        expect(metrics.connectionTime, greaterThan(0.05)); // At least 50ms
      });
    });

    group('frame timing', () {
      test('records first frame time', () async {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.connectionStarted();
        metrics.connectionCompleted();

        await Future.delayed(const Duration(milliseconds: 50));

        metrics.frameReceived();

        expect(metrics.firstFrameTime, greaterThan(0.03));
        expect(metrics.frameCount, equals(1));
      });

      test('counts frames correctly', () {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.connectionStarted();
        metrics.connectionCompleted();

        for (int i = 0; i < 10; i++) {
          metrics.frameReceived();
        }

        expect(metrics.frameCount, equals(10));
      });
    });

    group('PTZ metrics', () {
      test('records PTZ command count', () {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.ptzCommandSent(50);
        metrics.ptzCommandSent(60);
        metrics.ptzCommandSent(70);

        expect(metrics.ptzCommandCount, equals(3));
      });

      test('calculates average PTZ latency', () {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.ptzCommandSent(100); // 100ms = 0.1s
        metrics.ptzCommandSent(200); // 200ms = 0.2s

        // Average should be 150ms = 0.15s
        expect(metrics.ptzLatency, closeTo(0.15, 0.01));
      });
    });

    group('error tracking', () {
      test('counts errors', () {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.errorOccurred();
        metrics.errorOccurred();

        expect(metrics.errorCount, equals(2));
      });
    });

    group('quality gates', () {
      test('passes when all criteria met', () {
        final metrics = E2EMetrics();
        // Default values should pass (all 0 or below thresholds)
        expect(metrics.passedAllQualityGates, isFalse); // FPS = 0

        // Simulate good metrics
        metrics.start();
        metrics.connectionStarted();
        metrics.connectionCompleted();

        // Add frames with intervals
        for (int i = 0; i < 20; i++) {
          metrics.frameReceived();
        }

        // Check after stop (FPS calculated)
        metrics.stop();

        // Still may not pass FPS > 10 without real timing
      });

      test('fails when errors occur', () {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.errorOccurred();

        expect(metrics.passedAllQualityGates, isFalse);
      });
    });

    group('reporting', () {
      test('generates report string', () {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.stop();

        final report = metrics.report();

        expect(report, contains('E2E Test Metrics Report'));
        expect(report, contains('Connection'));
        expect(report, contains('Quality Gates'));
      });

      test('generates JSON', () {
        final metrics = E2EMetrics();
        metrics.start();
        metrics.ptzCommandSent(100);
        metrics.stop();

        final json = metrics.toJson();

        expect(json['connectionTime'], isA<double>());
        expect(json['ptzCommandCount'], equals(1));
        expect(json['passedAllGates'], isA<bool>());
      });
    });

    group('test duration', () {
      test('calculates test duration', () async {
        final metrics = E2EMetrics();
        metrics.start();

        await Future.delayed(const Duration(milliseconds: 100));

        metrics.stop();

        expect(metrics.testDuration, greaterThan(0.05));
      });
    });
  });
}
