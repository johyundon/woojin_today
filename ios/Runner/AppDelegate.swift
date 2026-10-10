import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications 필수 설정: 이게 없으면 앱이 포그라운드일 때
    // 알림이 조용히 무시된다(iOS는 델리게이트가 있어야만 포그라운드에서 알림을
    // 띄울지 물어본다 — 백그라운드/홈 화면에서는 이 델리게이트 없이도 SpringBoard가
    // 바로 띄우기 때문에 그때는 정상 동작해 보였다).
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
