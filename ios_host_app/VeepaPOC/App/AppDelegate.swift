import UIKit
import Flutter

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Flutter engine early for faster first display
        FlutterEngineManager.shared.initializeEngine()
        return true
    }
}
