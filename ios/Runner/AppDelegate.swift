import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let kioskChannel = FlutterMethodChannel(name: "com.akademihub.app/kiosk",
                                              binaryMessenger: engineBridge.applicationRegistrar.messenger())

    kioskChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "startKioskMode" {
        if #available(iOS 12.0, *) {
          UIAccessibility.requestGuidedAccessSession(enabled: true) { success in
            DispatchQueue.main.async {
              result(success)
            }
          }
        } else {
          result(FlutterError(code: "UNSUPPORTED", message: "iOS version not supported", details: nil))
        }
      } else if call.method == "stopKioskMode" {
        if #available(iOS 12.0, *) {
          UIAccessibility.requestGuidedAccessSession(enabled: false) { success in
            DispatchQueue.main.async {
              result(success)
            }
          }
        } else {
          result(FlutterError(code: "UNSUPPORTED", message: "iOS version not supported", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }
}

