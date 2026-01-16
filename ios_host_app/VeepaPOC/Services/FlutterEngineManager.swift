import Flutter

/// Manages Flutter engine lifecycle
class FlutterEngineManager {
    static let shared = FlutterEngineManager()

    private(set) var engine: FlutterEngine?

    private init() {}

    /// Initialize Flutter engine
    func initializeEngine() {
        guard engine == nil else { return }

        let newEngine = FlutterEngine(name: "veepa_camera_engine")
        newEngine.run()
        GeneratedPluginRegistrant.register(with: newEngine)

        // Register Veepa SDK plugin (P2P connection and video player)
        // This provides the native implementation for AppP2PApi and AppPlayerController
        VsdkPlugin.register(with: newEngine.registrar(forPlugin: "VsdkPlugin")!)

        engine = newEngine

        print("[FlutterEngine] Initialized successfully with Veepa SDK")
    }

    /// Get view controller for Flutter content
    func getViewController() -> FlutterViewController? {
        guard let engine = engine else {
            print("[FlutterEngine] Engine not initialized")
            return nil
        }

        return FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    }

    /// Cleanup engine
    func destroyEngine() {
        engine?.destroyContext()
        engine = nil
        print("[FlutterEngine] Destroyed")
    }
}
