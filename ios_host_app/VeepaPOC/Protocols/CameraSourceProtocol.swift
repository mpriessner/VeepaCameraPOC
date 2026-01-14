import Foundation
import Combine

/// Connection state for camera sources
enum CameraConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(CameraError)

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    static func == (lhs: CameraConnectionState, rhs: CameraConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
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
