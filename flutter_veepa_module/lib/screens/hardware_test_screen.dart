import 'package:flutter/material.dart';
import '../testing/hardware_test_runner.dart';
import '../testing/quality_gate_validator.dart';

/// Screen for running hardware integration tests
class HardwareTestScreen extends StatefulWidget {
  final String deviceId;
  final String password;
  final String? deviceName;

  const HardwareTestScreen({
    super.key,
    required this.deviceId,
    required this.password,
    this.deviceName,
  });

  @override
  State<HardwareTestScreen> createState() => _HardwareTestScreenState();
}

class _HardwareTestScreenState extends State<HardwareTestScreen> {
  late HardwareTestRunner _runner;
  TestSuiteResults? _results;
  QualityGateReport? _gateReport;
  bool _showGateReport = false;

  @override
  void initState() {
    super.initState();
    _runner = HardwareTestRunner(
      deviceId: widget.deviceId,
      password: widget.password,
      deviceName: widget.deviceName,
    );
    _runner.addListener(_onRunnerUpdate);
  }

  @override
  void dispose() {
    _runner.removeListener(_onRunnerUpdate);
    super.dispose();
  }

  void _onRunnerUpdate() {
    setState(() {});
  }

  Future<void> _runAllTests() async {
    setState(() {
      _results = null;
      _gateReport = null;
    });

    final results = await _runner.runAllTests();

    setState(() {
      _results = results;
      _gateReport = QualityGateValidator.validate(testResults: results);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware Tests'),
        actions: [
          if (_results != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _exportResults,
              tooltip: 'Export Results',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Device info
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  const Icon(Icons.videocam),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.deviceName ?? 'Camera',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.deviceId,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            if (_runner.isRunning) ...[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LinearProgressIndicator(value: _runner.progress),
                    const SizedBox(height: 8),
                    Text(
                      'Running: ${_runner.currentTest}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      '${_runner.completedTests}/${_runner.totalTests} tests',
                    ),
                  ],
                ),
              ),
            ],

            // Results
            Expanded(
              child: _results == null
                  ? _buildStartView()
                  : _showGateReport
                      ? _buildGateReport()
                      : _buildResults(),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_results != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _showGateReport = !_showGateReport);
                        },
                        child: Text(_showGateReport ? 'Show Results' : 'Quality Gates'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _runner.isRunning ? null : _runAllTests,
                      child: _runner.isRunning
                          ? const Text('Running...')
                          : const Text('Run All Tests'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Hardware Integration Tests',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Test connection, video streaming, and PTZ controls',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final results = _results!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStat('Passed', results.passed, Colors.green),
                _buildStat('Failed', results.failed, Colors.red),
                _buildStat('Total', results.total, Colors.blue),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${results.passRate.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Pass Rate'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Individual results
        ...results.results.map((result) => _buildResultItem(result)),
      ],
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildResultItem(TestResult result) {
    return Card(
      child: ListTile(
        leading: Icon(
          result.passed ? Icons.check_circle : Icons.cancel,
          color: result.passed ? Colors.green : Colors.red,
        ),
        title: Text(result.name),
        subtitle: Text('${result.category} - ${result.duration.inMilliseconds}ms'),
        trailing: result.message != null
            ? SizedBox(
                width: 100,
                child: Text(
                  result.message!,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildGateReport() {
    final report = _gateReport!;
    final recommendations = QualityGateValidator.getRecommendations(report);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        Card(
          color: report.allPassed ? Colors.green[50] : Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  report.allPassed ? Icons.verified : Icons.warning,
                  size: 48,
                  color: report.allPassed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 8),
                Text(
                  report.allPassed ? 'All Quality Gates Passed' : 'Quality Gates Failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: report.allPassed ? Colors.green : Colors.red,
                  ),
                ),
                Text('${report.passed}/${report.total} gates passed'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gate results
        ...report.results.map((result) => Card(
              child: ListTile(
                leading: Icon(
                  result.passed ? Icons.check : Icons.close,
                  color: result.passed ? Colors.green : Colors.red,
                ),
                title: Text(result.gate.name),
                subtitle: Text(
                  'Threshold: ${result.gate.passIfBelow ? '<' : '>'} ${result.gate.threshold}',
                ),
                trailing: Text(
                  result.actualValue.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.passed ? Colors.green : Colors.red,
                  ),
                ),
              ),
            )),

        // Recommendations
        if (recommendations.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Recommendations',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...recommendations.map((rec) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(child: Text(rec)),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  void _exportResults() {
    // In a real app, this would save to file or share
    final json = _results!.toJson();
    final gateJson = _gateReport!.toJson();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Test Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Pass rate: ${_results!.passRate.toStringAsFixed(1)}%'),
              Text('Duration: ${_results!.totalDuration.inSeconds}s'),
              const SizedBox(height: 16),
              const Text('Quality Gates:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Passed: ${_gateReport!.passed}/${_gateReport!.total}'),
              Text('All passed: ${_gateReport!.allPassed}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
