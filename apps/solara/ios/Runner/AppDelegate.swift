import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications: フォアグラウンドでの通知提示や iOS<10 互換のため
    // UNUserNotificationCenter の delegate を FlutterAppDelegate に設定する。
    // 許諾要求はここでは行わない (DarwinInitializationSettings の request* を全て
    // false にし、Set Intention 後のソフトアスクで明示的に要求する = Apple 4.5.4 準拠)。
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
