import Flutter
import UIKit
import UserNotifications
import workmanager_apple

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

    // 앱이 꺼져 있을 때 새 공지 확인(workmanager). iOS가 앱을 깨우면 화면 없는
    // Flutter 엔진이 따로 뜨는데, 거기서도 알림·저장소 플러그인을 쓰도록 등록한다.
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    // 이 앱은 UIScene을 써서 실행 처리기를 여기서(didFinishLaunching이 끝나기
    // 전에) 등록해야 한다. 6시간은 "이보다 빨리 깨우지 말라"는 희망이고 실제
    // 시각은 iOS가 정한다. 이름은 Info.plist·notice_background.dart와 같아야 한다.
    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.johyundon.woojintoday.noticeCheck",
      earliestBeginInSeconds: NSNumber(value: 6 * 60 * 60)
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
