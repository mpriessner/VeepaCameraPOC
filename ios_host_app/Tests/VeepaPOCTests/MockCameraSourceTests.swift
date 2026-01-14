import XCTest
@testable import VeepaPOC

class MockCameraSourceTests: XCTestCase {
    var sut: MockCameraSource!

    override func setUp() {
        super.setUp()
        sut = MockCameraSource()
        sut.connectionDelay = 0.01 // Speed up tests
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(sut.connectionState.isConnected)
        XCTAssertFalse(sut.isStreaming)
        XCTAssertNil(sut.currentDeviceId)
    }

    func testConnect() async throws {
        try await sut.connect(deviceId: "test-device")

        XCTAssertTrue(sut.connectionState.isConnected)
        XCTAssertEqual(sut.currentDeviceId, "test-device")
    }

    func testDisconnect() async throws {
        try await sut.connect(deviceId: "test-device")
        await sut.disconnect()

        XCTAssertFalse(sut.connectionState.isConnected)
        XCTAssertNil(sut.currentDeviceId)
    }

    func testStreamRequiresConnection() async {
        do {
            try await sut.startStream()
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is CameraError)
        }
    }

    func testConnectionFailure() async {
        sut.shouldFailConnection = true

        do {
            try await sut.connect(deviceId: "test-device")
            XCTFail("Should throw")
        } catch {
            XCTAssertTrue(error is CameraError)
            if case .error = sut.connectionState {
                // Expected
            } else {
                XCTFail("Should be in error state")
            }
        }
    }

    func testStartAndStopStream() async throws {
        try await sut.connect(deviceId: "test-device")
        try await sut.startStream()

        XCTAssertTrue(sut.isStreaming)

        await sut.stopStream()

        XCTAssertFalse(sut.isStreaming)
    }

    func testStateChangeCallback() async throws {
        var stateChanges: [CameraConnectionState] = []
        sut.onStateChanged = { state in
            stateChanges.append(state)
        }

        try await sut.connect(deviceId: "test-device")

        XCTAssertEqual(stateChanges.count, 2)
        XCTAssertEqual(stateChanges[0], .connecting)
        XCTAssertEqual(stateChanges[1], .connected)
    }

    func testFrameCallback() async throws {
        var receivedFrames: [VideoFrame] = []
        sut.onFrame = { frame in
            receivedFrames.append(frame)
        }

        try await sut.connect(deviceId: "test-device")
        try await sut.startStream()

        // Wait a bit for frames to be generated
        try await Task.sleep(nanoseconds: 150_000_000) // 150ms

        await sut.stopStream()

        XCTAssertGreaterThan(receivedFrames.count, 0)
        XCTAssertEqual(receivedFrames.first?.width, 1920)
        XCTAssertEqual(receivedFrames.first?.height, 1080)
    }
}
