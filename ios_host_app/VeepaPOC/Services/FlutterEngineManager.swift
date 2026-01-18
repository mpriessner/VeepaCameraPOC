import Flutter

/// Manages Flutter engine lifecycle
class FlutterEngineManager {
    static let shared = FlutterEngineManager()

    private(set) var engine: FlutterEngine?
    private var isInitializing = false

    private init() {
        print("[FlutterEngineManager] Singleton created")
    }

    /// Initialize Flutter engine
    func initializeEngine() {
        print("[FlutterEngineManager] initializeEngine called")

        guard engine == nil else {
            print("[FlutterEngineManager] Engine already exists, skipping initialization")
            return
        }

        guard !isInitializing else {
            print("[FlutterEngineManager] Already initializing, skipping")
            return
        }

        isInitializing = true

        print("[FlutterEngineManager] Creating new FlutterEngine...")
        let newEngine = FlutterEngine(name: "veepa_camera_engine")

        print("[FlutterEngineManager] Running engine...")
        let runSuccess = newEngine.run()
        print("[FlutterEngineManager] Engine run result: \(runSuccess)")

        print("[FlutterEngineManager] Registering GeneratedPluginRegistrant...")
        GeneratedPluginRegistrant.register(with: newEngine)

        // Register Veepa SDK plugin (P2P connection and video player)
        // This provides the native implementation for AppP2PApi and AppPlayerController
        print("[FlutterEngineManager] Getting registrar for VsdkPlugin...")
        if let registrar = newEngine.registrar(forPlugin: "VsdkPlugin") {
            print("[FlutterEngineManager] Registering VsdkPlugin...")
            VsdkPlugin.register(with: registrar)
            print("[FlutterEngineManager] VsdkPlugin registered successfully")
        } else {
            print("[FlutterEngineManager] WARNING: Could not get registrar for VsdkPlugin")
        }

        engine = newEngine
        isInitializing = false

        print("[FlutterEngineManager] Initialized successfully with Veepa SDK")
    }

    /// Get view controller for Flutter content
    func getViewController() -> FlutterViewController? {
        guard let engine = engine else {
            print("[FlutterEngineManager] Engine not initialized, cannot create ViewController")
            return nil
        }

        print("[FlutterEngineManager] Creating FlutterViewController")
        return FlutterViewController(engine: engine, nibName: nil, bundle: nil)
    }

    /// Cleanup engine
    func destroyEngine() {
        print("[FlutterEngineManager] destroyEngine called")
        if let engine = engine {
            print("[FlutterEngineManager] Destroying engine context...")
            engine.destroyContext()
        }
        engine = nil
        isInitializing = false
        print("[FlutterEngineManager] Engine destroyed")
    }
}
