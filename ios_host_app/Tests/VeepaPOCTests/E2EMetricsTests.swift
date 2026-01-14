import XCTest
@testable import VeepaPOC

class E2EMetricsTests: XCTestCase {

    override func setUp() {
        super.setUp()
        E2EMetricsCollector.shared.reset()
    }

    override func tearDown() {
        E2EMetricsCollector.shared.reset()
        super.tearDown()
    }

    // MARK: - E2EMetrics Struct Tests

    func testMetricsInitialValues() {
        let metrics = E2EMetrics()

        XCTAssertEqual(metrics.engineInitTime, 0)
        XCTAssertEqual(metrics.connectionTime, 0)
        XCTAssertEqual(metrics.firstFrameTime, 0)
        XCTAssertEqual(metrics.averageFPS, 0)
        XCTAssertEqual(metrics.ptzLatency, 0)
        XCTAssertEqual(metrics.frameCount, 0)
        XCTAssertEqual(metrics.errorCount, 0)
    }

    func testMetricsReport() {
        var metrics = E2EMetrics()
        metrics.engineInitTime = 1.5
        metrics.connectionTime = 2.0
        metrics.firstFrameTime = 0.5
        metrics.averageFPS = 25.0
        metrics.ptzLatency = 0.1

        let report = metrics.report()

        XCTAssertTrue(report.contains("E2E Test Metrics Report"))
        XCTAssertTrue(report.contains("1.50"))
        XCTAssertTrue(report.contains("25.0"))
    }

    func testMetricsToJSON() {
        var metrics = E2EMetrics()
        metrics.connectionTime = 2.0
        metrics.frameCount = 100

        let json = metrics.toJSON()

        XCTAssertEqual(json["connectionTime"] as? Double, 2.0)
        XCTAssertEqual(json["frameCount"] as? Int, 100)
    }

    func testQualityGatesPassing() {
        var metrics = E2EMetrics()
        metrics.connectionTime = 5.0      // < 10 ✓
        metrics.firstFrameTime = 2.0      // < 5 ✓
        metrics.averageFPS = 15.0         // > 10 ✓
        metrics.ptzLatency = 0.2          // < 0.5 ✓
        metrics.errorCount = 0            // == 0 ✓

        XCTAssertTrue(metrics.passedAllQualityGates)
    }

    func testQualityGatesFailingConnection() {
        var metrics = E2EMetrics()
        metrics.connectionTime = 15.0     // > 10 ✗
        metrics.firstFrameTime = 2.0
        metrics.averageFPS = 15.0
        metrics.ptzLatency = 0.2
        metrics.errorCount = 0

        XCTAssertFalse(metrics.passedAllQualityGates)
    }

    func testQualityGatesFailingFPS() {
        var metrics = E2EMetrics()
        metrics.connectionTime = 5.0
        metrics.firstFrameTime = 2.0
        metrics.averageFPS = 5.0          // < 10 ✗
        metrics.ptzLatency = 0.2
        metrics.errorCount = 0

        XCTAssertFalse(metrics.passedAllQualityGates)
    }

    func testQualityGatesFailingErrors() {
        var metrics = E2EMetrics()
        metrics.connectionTime = 5.0
        metrics.firstFrameTime = 2.0
        metrics.averageFPS = 15.0
        metrics.ptzLatency = 0.2
        metrics.errorCount = 1            // > 0 ✗

        XCTAssertFalse(metrics.passedAllQualityGates)
    }

    // MARK: - E2EMetricsCollector Tests

    func testCollectorSingleton() {
        let collector1 = E2EMetricsCollector.shared
        let collector2 = E2EMetricsCollector.shared

        XCTAssertTrue(collector1 === collector2)
    }

    func testCollectorStartStop() {
        let collector = E2EMetricsCollector.shared

        XCTAssertFalse(collector.isRunning)

        collector.start()
        XCTAssertTrue(collector.isRunning)

        collector.stop()
        XCTAssertFalse(collector.isRunning)
    }

    func testCollectorRecordEngineInit() {
        let collector = E2EMetricsCollector.shared
        collector.start()

        collector.recordEngineInit(duration: 1.5)

        XCTAssertEqual(collector.metrics.engineInitTime, 1.5)
    }

    func testCollectorConnectionTiming() {
        let collector = E2EMetricsCollector.shared
        collector.start()

        collector.connectionStarted()
        Thread.sleep(forTimeInterval: 0.1) // 100ms
        collector.connectionCompleted()

        XCTAssertGreaterThan(collector.metrics.connectionTime, 0.05)
    }

    func testCollectorFrameCounting() {
        let collector = E2EMetricsCollector.shared
        collector.start()
        collector.connectionStarted()
        collector.connectionCompleted()

        for _ in 0..<10 {
            collector.frameReceived()
        }

        XCTAssertEqual(collector.metrics.frameCount, 10)
    }

    func testCollectorPTZLatency() {
        let collector = E2EMetricsCollector.shared
        collector.start()

        collector.ptzCommandSent(latency: 0.1) // 100ms
        collector.ptzCommandSent(latency: 0.2) // 200ms

        // Average should be 0.15
        XCTAssertEqual(collector.metrics.ptzLatency, 0.15, accuracy: 0.01)
        XCTAssertEqual(collector.metrics.ptzCommandCount, 2)
    }

    func testCollectorErrorTracking() {
        let collector = E2EMetricsCollector.shared
        collector.start()

        collector.errorOccurred()
        collector.errorOccurred()

        XCTAssertEqual(collector.metrics.errorCount, 2)
    }

    func testCollectorReset() {
        let collector = E2EMetricsCollector.shared
        collector.start()
        collector.recordEngineInit(duration: 1.0)
        collector.connectionStarted()
        collector.connectionCompleted()
        collector.frameReceived()
        collector.ptzCommandSent(latency: 0.1)
        collector.errorOccurred()

        collector.reset()

        XCTAssertEqual(collector.metrics.engineInitTime, 0)
        XCTAssertEqual(collector.metrics.frameCount, 0)
        XCTAssertEqual(collector.metrics.ptzCommandCount, 0)
        XCTAssertEqual(collector.metrics.errorCount, 0)
        XCTAssertFalse(collector.isRunning)
    }
}
