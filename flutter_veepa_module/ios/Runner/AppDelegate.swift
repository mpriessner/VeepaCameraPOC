import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Note: VsdkPlugin is registered in the iOS host app, not here
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
