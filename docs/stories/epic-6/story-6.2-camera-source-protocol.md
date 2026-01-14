# Story 6.2: Define Camera Source Protocol

> **Epic**: 6 - SwiftUI Host Setup (Phase 2)
> **Status**: Draft
> **Priority**: P0 - Must Have
> **Estimated Effort**: Small
> **Phase**: 2 - Flutter Add-to-App Integration

---

## User Story

**As a** developer,
**I want** an abstract camera source protocol,
**So that** I can support multiple camera types (local, external, Flutter-based).

---

## Acceptance Criteria

- [ ] AC1: `CameraSourceProtocol` defined with standard interface
- [ ] AC2: Methods: connect(), disconnect(), startStream(), stopStream()
- [ ] AC3: Properties: connectionState, isStreaming, currentDevice
- [ ] AC4: Events: onFrame, onStateChanged callbacks
- [ ] AC5: Documentation for future implementers
- [ ] AC6: Mock implementation for testing
- [ ] AC7: Protocol ready for FlutterCameraSource implementation

---

## Technical Specification

### CameraSourceProtocol

Create `ios_host_app/VeepaPOC/Protocols/CameraSourceProtocol.swift`:

```swift
import Foundation
import Combine

/// Connection state for camera sources
enum CameraConnectionState {
    case disconnected
    case connecting
    case connected
    case error(Error)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

/// Protocol defining interface for all camera sources
/// Conforming types: LocalCameraSource, FlutterCameraSource (Veepa)
protocol CameraSourceProtocol: AnyObject {
    // MARK: - Properties

    /// Current connection state
    var connectionState: CameraConnectionState { get }

    /// Publisher for connection state changes
    var connectionStatePublisher: AnyPublisher<CameraConnectionState, Never> { get }

    /// Whether video stream is active
    var isStreaming: Bool { get }

    /// Current device identifier
    var currentDeviceId: String? { get }

    // MARK: - Connection

    /// Connect to camera
    /// - Parameter deviceId: Device identifier to connect to
    /// - Returns: Success status
    func connect(deviceId: String) async throws

    /// Disconnect from camera
    func disconnect() async

    // MARK: - Streaming

    /// Start video stream
    func startStream() async throws

    /// Stop video stream
    func stopStream() async

    // MARK: - Callbacks

    /// Frame callback - called when new video frame available
    var onFrame: ((VideoFrame) -> Void)? { get set }

    /// State change callback
    var onStateChanged: ((CameraConnectionState) -> Void)? { get set }
}

/// Video frame from camera
struct VideoFrame {
    let data: Data
    let width: Int
    let height: Int
    let timestamp: Date

    init(data: Data, width: Int, height: Int, timestamp: Date = Date()) {
        self.data = data
        self.width = width
        self.height = height
        self.timestamp = timestamp
    }
}

/// Camera device information
struct CameraDevice {
    let id: String
    let name: String
    let type: CameraType
    let ipAddress: String?

    enum CameraType {
        case local      // Built-in device camera
        case external   // External IP camera (Veepa)
    }
}
```

### Mock Implementation

Create `ios_host_app/VeepaPOC/Services/MockCameraSource.swift`:

```swift
import Foundation
import Combine

/// Mock camera source for testing
class MockCameraSource: CameraSourceProtocol {
    // MARK: - Properties

    private(set) var connectionState: CameraConnectionState = .disconnected
    private let connectionStateSubject = CurrentValueSubject<CameraConnectionState, Never>(.disconnected)

    var connectionStatePublisher: AnyPublisher<CameraConnectionState, Never> {
        connectionStateSubject.eraseToAnyPublisher()
    }

    private(set) var isStreaming = false
    private(set) var currentDeviceId: String?

    var onFrame: ((VideoFrame) -> Void)?
    var onStateChanged: ((CameraConnectionState) -> Void)?

    // MARK: - Simulated delays

    var connectionDelay: TimeInterval = 1.0
    var shouldFailConnection = false

    // MARK: - Connection

    func connect(deviceId: String) async throws {
        updateState(.connecting)

        try await Task.sleep(nanoseconds: UInt64(connectionDelay * 1_000_000_000))

        if shouldFailConnection {
            let error = CameraError.connectionFailed("Simulated failure")
            updateState(.error(error))
            throw error
        }

        currentDeviceId = deviceId
        updateState(.connected)
    }

    func disconnect() async {
        isStreaming = false
        currentDeviceId = nil
        updateState(.disconnected)
    }

    // MARK: - Streaming

    func startStream() async throws {
        guard connectionState.isConnected else {
            throw CameraError.notConnected
        }

        isStreaming = true

        // Simulate frame generation
        Task {
            while isStreaming {
                let frame = VideoFrame(
                    data: Data(count: 1920 * 1080 * 3),
                    width: 1920,
                    height: 1080
                )
                onFrame?(frame)
                try? await Task.sleep(nanoseconds: 66_666_666) // ~15 FPS
            }
        }
    }

    func stopStream() async {
        isStreaming = false
    }

    // MARK: - Private

    private func updateState(_ state: CameraConnectionState) {
        connectionState = state
        connectionStateSubject.send(state)
        onStateChanged?(state)
    }
}

/// Camera errors
enum CameraError: Error, LocalizedError {
    case connectionFailed(String)
    case notConnected
    case streamError(String)

    var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .notConnected:
            return "Not connected to camera"
        case .streamError(let reason):
            return "Stream error: \(reason)"
        }
    }
}
```

---

## Test Cases

### TC6.2.1: Protocol Compilation
**Type**: Automated (Build)
**Priority**: P0

**Given**: Protocol file created
**When**: Project builds
**Then**: No compilation errors

---

### TC6.2.2: Mock Implementation Works
**Type**: Unit Test
**Priority**: P0

```swift
// VeepaPOCTests/MockCameraSourceTests.swift
import XCTest
@testable import VeepaPOC

class MockCameraSourceTests: XCTestCase {
    var sut: MockCameraSource!

    override func setUp() {
        sut = MockCameraSource()
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
}
```

---

## Definition of Done

- [ ] Protocol compiles correctly
- [ ] Mock implementation passes tests
- [ ] Documentation complete for implementers
- [ ] Code committed with message: "feat(epic-6): Define Camera Source Protocol - Story 6.2"

---

## Dependencies

- **Depends On**: Story 6.1
- **Blocks**: Story 7.2 (FlutterCameraSource)
