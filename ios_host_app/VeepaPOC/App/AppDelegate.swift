import UIKit
import Flutter

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("[AppDelegate] didFinishLaunchingWithOptions called")

        // Initialize Flutter engine early for faster first display
        do {
            FlutterEngineManager.shared.initializeEngine()
            print("[AppDelegate] Flutter engine initialized successfully")
        } catch {
            print("[AppDelegate] ERROR initializing Flutter engine: \(error)")
        }

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("[AppDelegate] applicationWillTerminate - cleaning up")
        FlutterEngineManager.shared.destroyEngine()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("[AppDelegate] applicationDidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("[AppDelegate] applicationWillEnterForeground")
    }
}
