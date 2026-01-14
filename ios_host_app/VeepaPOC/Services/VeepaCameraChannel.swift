import Flutter

/// Method channel for Swift → Dart communication
class VeepaCameraChannel {
    private let channel: FlutterMethodChannel
    static let channelName = "com.veepapoc/camera"

    init(messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(
            name: VeepaCameraChannel.channelName,
            binaryMessenger: messenger
        )
    }

    /// Connect to a camera device
    func connect(deviceId: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            channel.invokeMethod("connect", arguments: ["deviceId": deviceId]) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown error"))
                } else if (result as AnyObject) === FlutterMethodNotImplemented {
                    continuation.resume(throwing: ChannelError.notImplemented("connect"))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Disconnect from current camera
    func disconnect() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            channel.invokeMethod("disconnect", arguments: nil) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown error"))
                } else if (result as AnyObject) === FlutterMethodNotImplemented {
                    continuation.resume(throwing: ChannelError.notImplemented("disconnect"))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Control PTZ (Pan-Tilt-Zoom)
    func setPTZ(direction: String, speed: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            channel.invokeMethod("setPTZ", arguments: [
                "direction": direction,
                "speed": speed
            ]) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown error"))
                } else if (result as AnyObject) === FlutterMethodNotImplemented {
                    continuation.resume(throwing: ChannelError.notImplemented("setPTZ"))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Stop PTZ movement
    func stopPTZ() async throws {
        try await setPTZ(direction: "stop", speed: 0)
    }

    /// Start zoom
    func setZoom(direction: String, speed: Int) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            channel.invokeMethod("setZoom", arguments: [
                "direction": direction,
                "speed": speed
            ]) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown error"))
                } else if (result as AnyObject) === FlutterMethodNotImplemented {
                    continuation.resume(throwing: ChannelError.notImplemented("setZoom"))
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Get connection status
    func getConnectionStatus() async throws -> [String: Any] {
        try await withCheckedThrowingContinuation { continuation in
            channel.invokeMethod("getConnectionStatus", arguments: nil) { result in
                if let error = result as? FlutterError {
                    continuation.resume(throwing: ChannelError.flutter(error.message ?? "Unknown error"))
                } else if (result as AnyObject) === FlutterMethodNotImplemented {
                    continuation.resume(throwing: ChannelError.notImplemented("getConnectionStatus"))
                } else if let status = result as? [String: Any] {
                    continuation.resume(returning: status)
                } else {
                    continuation.resume(returning: [:])
                }
            }
        }
    }
}

/// Errors from method channel communication
enum ChannelError: Error, LocalizedError {
    case flutter(String)
    case notImplemented(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .flutter(let message):
            return "Flutter error: \(message)"
        case .notImplemented(let method):
            return "Method not implemented: \(method)"
        case .invalidResponse:
            return "Invalid response from Flutter"
        }
    }
}
