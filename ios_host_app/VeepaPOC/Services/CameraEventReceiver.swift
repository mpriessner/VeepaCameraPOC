import Flutter

/// Event receiver for Dart → Swift communication
class CameraEventReceiver: NSObject, FlutterStreamHandler {
    private var eventSink: FlutterEventSink?
    private var methodChannel: FlutterMethodChannel?

    // MARK: - Event Callbacks

    /// Called when connection state changes
    var onConnectionStateChanged: ((String) -> Void)?

    /// Called when player state changes
    var onPlayerStateChanged: ((String) -> Void)?

    /// Called when frame rate is updated
    var onFrameRateUpdated: ((Double) -> Void)?

    /// Called when an error occurs
    var onError: ((String) -> Void)?

    /// Called when PTZ state changes
    var onPTZStateChanged: ((String, Int, Bool) -> Void)?

    /// Called when device info is received
    var onDeviceInfo: ((String, String, String?) -> Void)?

    // MARK: - FlutterStreamHandler

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        print("[CameraEventReceiver] Event stream listening")
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        print("[CameraEventReceiver] Event stream cancelled")
        return nil
    }

    // MARK: - Setup

    /// Set up the event receiver with Flutter engine
    static func setup(messenger: FlutterBinaryMessenger) -> CameraEventReceiver {
        let receiver = CameraEventReceiver()

        // EventChannel for native → Dart (if needed in future)
        let eventChannel = FlutterEventChannel(
            name: "com.veepapoc/camera_events",
            binaryMessenger: messenger
        )
        eventChannel.setStreamHandler(receiver)

        // MethodChannel for Dart → native events
        let methodChannel = FlutterMethodChannel(
            name: "com.veepapoc/camera_events_out",
            binaryMessenger: messenger
        )
        receiver.methodChannel = methodChannel

        methodChannel.setMethodCallHandler { call, result in
            if call.method == "sendEvent" {
                if let args = call.arguments as? [String: Any] {
                    receiver.handleEvent(args)
                }
                result(nil)
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        print("[CameraEventReceiver] Setup complete")
        return receiver
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: [String: Any]) {
        guard let type = event["type"] as? String else {
            print("[CameraEventReceiver] Event missing type")
            return
        }

        print("[CameraEventReceiver] Received event: \(type)")

        switch type {
        case "connectionState":
            if let state = event["state"] as? String {
                onConnectionStateChanged?(state)
            }

        case "playerState":
            if let state = event["state"] as? String {
                onPlayerStateChanged?(state)
            }

        case "frameRate":
            if let fps = event["fps"] as? Double {
                onFrameRateUpdated?(fps)
            }

        case "error":
            if let message = event["message"] as? String {
                onError?(message)
            }

        case "ptzState":
            if let direction = event["direction"] as? String,
               let speed = event["speed"] as? Int,
               let isMoving = event["isMoving"] as? Bool {
                onPTZStateChanged?(direction, speed, isMoving)
            }

        case "deviceInfo":
            if let deviceId = event["deviceId"] as? String,
               let deviceName = event["deviceName"] as? String {
                let ipAddress = event["ipAddress"] as? String
                onDeviceInfo?(deviceId, deviceName, ipAddress)
            }

        default:
            print("[CameraEventReceiver] Unknown event type: \(type)")
        }
    }

    // MARK: - Send Events to Dart (if needed)

    /// Send an event to Dart via EventSink
    func sendToDart(_ event: [String: Any]) {
        eventSink?(event)
    }
}
