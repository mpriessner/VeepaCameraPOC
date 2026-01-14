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
