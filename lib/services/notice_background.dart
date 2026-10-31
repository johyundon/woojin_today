import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'notice_watcher.dart';
import 'notification_service.dart';

/// 앱이 꺼져 있을 때도 몇 시간마다 새 공지를 확인하도록 OS에 작업을 맡긴다.
///
/// 확인 자체는 [NoticeWatcher.check]가 한다. 여기서는 OS에 "주기적으로 이 앱을
/// 잠깐 깨워 달라"고 등록하거나 취소만 한다. 한 번 확인할 때 학교에 요청이 약
/// 10번 가므로 간격을 6시간으로 길게 둔다.
///
/// - 안드로이드: WorkManager가 6시간마다(배터리 상태에 따라 조금 늦게) 실행한다.
/// - iOS: 6시간은 "이보다 빨리 깨우지 말라"는 희망일 뿐이고, 실제로 언제(또는
///   며칠 동안 아예 안) 깨울지는 iOS가 사용 습관을 보고 정한다. 사용자가 앱을
///   완전히 종료(위로 쓸어 올림)하면 다시 열 때까지 깨우지 않는다.
class NoticeBackground {
  const NoticeBackground();

  /// 작업 이름. iOS는 `Info.plist`의 `BGTaskSchedulerPermittedIdentifiers`와
  /// `AppDelegate.swift`에 같은 값이 있어야 한다.
  static const taskId = 'com.johyundon.woojintoday.noticeCheck';

  static const interval = Duration(hours: 6);

  /// 앱 시작 시(main.dart) 한 번 부른다. 등록·취소보다 먼저 불려야 한다.
  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(noticeCallbackDispatcher);
    } catch (e) {
      debugPrint('[NoticeBackground] 초기화 실패: $e');
    }
  }

  /// 이미 등록돼 있으면 안드로이드는 그대로 둔다(keep). iOS는 다음 실행을
  /// 지금부터 6시간 뒤 이후로 다시 잡는다(앱을 연 김에 이미 확인했으므로 괜찮다).
  Future<void> start() => Workmanager().registerPeriodicTask(
    taskId,
    taskId,
    frequency: interval,
    initialDelay: interval,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );

  Future<void> stop() => Workmanager().cancelByUniqueName(taskId);
}

/// OS가 앱을 백그라운드에서 깨웠을 때 실행되는 입구. 화면이 없는 별도 실행
/// 환경이라 알림 기능을 여기서 다시 준비한다.
@pragma('vm:entry-point')
void noticeCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final watcher = NoticeWatcher();
      // 로그아웃 등으로 설정이 지워졌는데 작업 취소가 실패한 경우, 학교에
      // 요청하지 않고 끝낸다.
      if (!await watcher.isEnabled()) return true;
      await NotificationService.instance.initialize();
      await watcher.check();
    } catch (e) {
      debugPrint('[NoticeBackground] 백그라운드 확인 실패: $e');
    }
    // 실패해도 true: false면 안드로이드가 곧바로 재시도해 학교 요청이 늘어난다.
    return true;
  });
}
