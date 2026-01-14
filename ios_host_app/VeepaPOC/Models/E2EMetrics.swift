import Foundation

/// Metrics collected during E2E testing
struct E2EMetrics {
    /// Time to initialize Flutter engine
    var engineInitTime: TimeInterval = 0

    /// Time to establish camera connection
    var connectionTime: TimeInterval = 0

    /// Time from connection to first video frame
    var firstFrameTime: TimeInterval = 0

    /// Average frames per second during streaming
    var averageFPS: Double = 0

    /// Average PTZ command latency
    var ptzLatency: TimeInterval = 0

    /// Number of frames received
    var frameCount: Int = 0

    /// Number of PTZ commands sent
    var ptzCommandCount: Int = 0

    /// Number of errors encountered
    var errorCount: Int = 0

    /// Test start time
    var startTime: Date = Date()

    /// Test end time
    var endTime: Date?

    /// Total test duration
    var testDuration: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    /// Generate human-readable report
    func report() -> String {
        """
        ═══════════════════════════════════════
        E2E Test Metrics Report
        ═══════════════════════════════════════

        Performance Metrics:
        ─────────────────────────────────────────
        • Engine Init:    \(String(format: "%.2f", engineInitTime))s
        • Connection:     \(String(format: "%.2f", connectionTime))s
        • First Frame:    \(String(format: "%.2f", firstFrameTime))s
        • Average FPS:    \(String(format: "%.1f", averageFPS))
        • PTZ Latency:    \(String(format: "%.0f", ptzLatency * 1000))ms

        Statistics:
        ─────────────────────────────────────────
        • Total Frames:   \(frameCount)
        • PTZ Commands:   \(ptzCommandCount)
        • Errors:         \(errorCount)
        • Test Duration:  \(String(format: "%.1f", testDuration))s

        Quality Gates:
        ─────────────────────────────────────────
        [\(connectionTime < 10 ? "✓" : "✗")] Connection < 10s
        [\(firstFrameTime < 5 ? "✓" : "✗")] First Frame < 5s
        [\(averageFPS > 10 ? "✓" : "✗")] FPS > 10
        [\(ptzLatency < 0.5 ? "✓" : "✗")] PTZ Latency < 500ms
        [\(errorCount == 0 ? "✓" : "✗")] No Errors

        ═══════════════════════════════════════
        """
    }

    /// Generate JSON report
    func toJSON() -> [String: Any] {
        return [
            "engineInitTime": engineInitTime,
            "connectionTime": connectionTime,
            "firstFrameTime": firstFrameTime,
            "averageFPS": averageFPS,
            "ptzLatency": ptzLatency,
            "frameCount": frameCount,
            "ptzCommandCount": ptzCommandCount,
            "errorCount": errorCount,
            "testDuration": testDuration,
            "passedAllGates": passedAllQualityGates
        ]
    }

    /// Check if all quality gates passed
    var passedAllQualityGates: Bool {
        connectionTime < 10 &&
        firstFrameTime < 5 &&
        averageFPS > 10 &&
        ptzLatency < 0.5 &&
        errorCount == 0
    }
}

/// Observer pattern for metrics collection
class E2EMetricsCollector: ObservableObject {
    static let shared = E2EMetricsCollector()

    @Published var metrics = E2EMetrics()
    @Published var isRunning = false

    private var connectionStartTime: Date?
    private var frameStartTime: Date?
    private var lastFrameTime: Date?
    private var frameIntervals: [TimeInterval] = []

    private init() {}

    /// Start metrics collection
    func start() {
        metrics = E2EMetrics()
        metrics.startTime = Date()
        isRunning = true
        print("[E2EMetrics] Collection started")
    }

    /// Stop metrics collection
    func stop() {
        metrics.endTime = Date()
        calculateAverageFPS()
        isRunning = false
        print("[E2EMetrics] Collection stopped")
        print(metrics.report())
    }

    /// Record engine initialization time
    func recordEngineInit(duration: TimeInterval) {
        metrics.engineInitTime = duration
        print("[E2EMetrics] Engine init: \(String(format: "%.2f", duration))s")
    }

    /// Record connection start
    func connectionStarted() {
        connectionStartTime = Date()
    }

    /// Record connection complete
    func connectionCompleted() {
        if let start = connectionStartTime {
            metrics.connectionTime = Date().timeIntervalSince(start)
            frameStartTime = Date() // Start timing for first frame
            print("[E2EMetrics] Connection: \(String(format: "%.2f", metrics.connectionTime))s")
        }
    }

    /// Record frame received
    func frameReceived() {
        let now = Date()

        // First frame
        if metrics.frameCount == 0, let start = frameStartTime {
            metrics.firstFrameTime = now.timeIntervalSince(start)
            print("[E2EMetrics] First frame: \(String(format: "%.2f", metrics.firstFrameTime))s")
        }

        // Calculate frame interval
        if let lastTime = lastFrameTime {
            frameIntervals.append(now.timeIntervalSince(lastTime))
        }

        lastFrameTime = now
        metrics.frameCount += 1
    }

    /// Record PTZ command latency
    func ptzCommandSent(latency: TimeInterval) {
        metrics.ptzCommandCount += 1
        // Calculate running average
        let totalLatency = metrics.ptzLatency * Double(metrics.ptzCommandCount - 1) + latency
        metrics.ptzLatency = totalLatency / Double(metrics.ptzCommandCount)
    }

    /// Record error
    func errorOccurred() {
        metrics.errorCount += 1
    }

    /// Calculate average FPS from frame intervals
    private func calculateAverageFPS() {
        guard !frameIntervals.isEmpty else {
            metrics.averageFPS = 0
            return
        }

        let averageInterval = frameIntervals.reduce(0, +) / Double(frameIntervals.count)
        metrics.averageFPS = averageInterval > 0 ? 1.0 / averageInterval : 0
    }

    /// Reset collector
    func reset() {
        metrics = E2EMetrics()
        isRunning = false
        connectionStartTime = nil
        frameStartTime = nil
        lastFrameTime = nil
        frameIntervals = []
    }
}
