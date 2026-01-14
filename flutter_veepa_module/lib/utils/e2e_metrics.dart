import 'package:flutter/foundation.dart';

/// E2E Metrics collector for POC validation
class E2EMetrics extends ChangeNotifier {
  static final E2EMetrics _instance = E2EMetrics._internal();
  factory E2EMetrics() => _instance;
  E2EMetrics._internal();

  // Timing metrics
  double _connectionTime = 0;
  double _firstFrameTime = 0;
  double _averageFPS = 0;
  double _ptzLatency = 0;

  // Counters
  int _frameCount = 0;
  int _ptzCommandCount = 0;
  int _errorCount = 0;

  // Timestamps
  DateTime? _connectionStartTime;
  DateTime? _frameStartTime;
  DateTime? _lastFrameTime;
  DateTime? _testStartTime;
  DateTime? _testEndTime;

  // Frame intervals for FPS calculation
  final List<double> _frameIntervals = [];

  // Running state
  bool _isRunning = false;

  // Getters
  double get connectionTime => _connectionTime;
  double get firstFrameTime => _firstFrameTime;
  double get averageFPS => _averageFPS;
  double get ptzLatency => _ptzLatency;
  int get frameCount => _frameCount;
  int get ptzCommandCount => _ptzCommandCount;
  int get errorCount => _errorCount;
  bool get isRunning => _isRunning;

  double get testDuration {
    if (_testStartTime == null) return 0;
    final endTime = _testEndTime ?? DateTime.now();
    return endTime.difference(_testStartTime!).inMilliseconds / 1000.0;
  }

  /// Start metrics collection
  void start() {
    reset();
    _testStartTime = DateTime.now();
    _isRunning = true;
    debugPrint('[E2EMetrics] Collection started');
    notifyListeners();
  }

  /// Stop metrics collection
  void stop() {
    _testEndTime = DateTime.now();
    _calculateAverageFPS();
    _isRunning = false;
    debugPrint('[E2EMetrics] Collection stopped');
    debugPrint(report());
    notifyListeners();
  }

  /// Record connection start
  void connectionStarted() {
    _connectionStartTime = DateTime.now();
  }

  /// Record connection complete
  void connectionCompleted() {
    if (_connectionStartTime != null) {
      _connectionTime = DateTime.now()
          .difference(_connectionStartTime!)
          .inMilliseconds / 1000.0;
      _frameStartTime = DateTime.now();
      debugPrint('[E2EMetrics] Connection: ${_connectionTime.toStringAsFixed(2)}s');
      notifyListeners();
    }
  }

  /// Record frame received
  void frameReceived() {
    final now = DateTime.now();

    // First frame timing
    if (_frameCount == 0 && _frameStartTime != null) {
      _firstFrameTime = now.difference(_frameStartTime!).inMilliseconds / 1000.0;
      debugPrint('[E2EMetrics] First frame: ${_firstFrameTime.toStringAsFixed(2)}s');
    }

    // Calculate frame interval
    if (_lastFrameTime != null) {
      final interval = now.difference(_lastFrameTime!).inMilliseconds / 1000.0;
      _frameIntervals.add(interval);
    }

    _lastFrameTime = now;
    _frameCount++;
    notifyListeners();
  }

  /// Record PTZ command sent
  void ptzCommandSent(double latencyMs) {
    _ptzCommandCount++;
    final latencySeconds = latencyMs / 1000.0;
    // Calculate running average
    final totalLatency = _ptzLatency * (_ptzCommandCount - 1) + latencySeconds;
    _ptzLatency = totalLatency / _ptzCommandCount;
    notifyListeners();
  }

  /// Record error
  void errorOccurred() {
    _errorCount++;
    notifyListeners();
  }

  /// Calculate average FPS from frame intervals
  void _calculateAverageFPS() {
    if (_frameIntervals.isEmpty) {
      _averageFPS = 0;
      return;
    }

    final averageInterval = _frameIntervals.reduce((a, b) => a + b) / _frameIntervals.length;
    _averageFPS = averageInterval > 0 ? 1.0 / averageInterval : 0;
  }

  /// Reset all metrics
  void reset() {
    _connectionTime = 0;
    _firstFrameTime = 0;
    _averageFPS = 0;
    _ptzLatency = 0;
    _frameCount = 0;
    _ptzCommandCount = 0;
    _errorCount = 0;
    _connectionStartTime = null;
    _frameStartTime = null;
    _lastFrameTime = null;
    _testStartTime = null;
    _testEndTime = null;
    _frameIntervals.clear();
    _isRunning = false;
    notifyListeners();
  }

  /// Check if all quality gates passed
  bool get passedAllQualityGates {
    return _connectionTime < 10 &&
        _firstFrameTime < 5 &&
        _averageFPS > 10 &&
        _ptzLatency < 0.5 &&
        _errorCount == 0;
  }

  /// Generate human-readable report
  String report() {
    _calculateAverageFPS();
    return '''
═══════════════════════════════════════
E2E Test Metrics Report (Flutter)
═══════════════════════════════════════

Performance Metrics:
─────────────────────────────────────────
• Connection:     ${_connectionTime.toStringAsFixed(2)}s
• First Frame:    ${_firstFrameTime.toStringAsFixed(2)}s
• Average FPS:    ${_averageFPS.toStringAsFixed(1)}
• PTZ Latency:    ${(_ptzLatency * 1000).toStringAsFixed(0)}ms

Statistics:
─────────────────────────────────────────
• Total Frames:   $_frameCount
• PTZ Commands:   $_ptzCommandCount
• Errors:         $_errorCount
• Test Duration:  ${testDuration.toStringAsFixed(1)}s

Quality Gates:
─────────────────────────────────────────
[${_connectionTime < 10 ? "✓" : "✗"}] Connection < 10s
[${_firstFrameTime < 5 ? "✓" : "✗"}] First Frame < 5s
[${_averageFPS > 10 ? "✓" : "✗"}] FPS > 10
[${_ptzLatency < 0.5 ? "✓" : "✗"}] PTZ Latency < 500ms
[${_errorCount == 0 ? "✓" : "✗"}] No Errors

═══════════════════════════════════════
''';
  }

  /// Convert to JSON for reporting
  Map<String, dynamic> toJson() {
    _calculateAverageFPS();
    return {
      'connectionTime': _connectionTime,
      'firstFrameTime': _firstFrameTime,
      'averageFPS': _averageFPS,
      'ptzLatency': _ptzLatency,
      'frameCount': _frameCount,
      'ptzCommandCount': _ptzCommandCount,
      'errorCount': _errorCount,
      'testDuration': testDuration,
      'passedAllGates': passedAllQualityGates,
    };
  }
}
