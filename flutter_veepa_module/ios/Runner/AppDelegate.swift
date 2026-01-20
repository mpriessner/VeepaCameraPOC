import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Register VsdkPlugin for P2P SDK functionality
    VsdkPlugin.register(with: self.registrar(forPlugin: "VsdkPlugin")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
