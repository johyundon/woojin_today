import 'package:flutter/foundation.dart';

import '../../../services/notification_service.dart';
import 'calendar_event_storage.dart';

/// 로그인 직후, 기기에 남아 있는 이 학생의 일정 중 알림이 켜진 것을 다시 예약한다.
///
/// 로그아웃하면 예약 알림은 전부 지워지지만 일정은 학번별 칸에 남는다
/// ([CalendarEventStorage]). 그래서 같은 학생이 다시 로그인했을 때 이걸 부르지
/// 않으면 "화면에는 알림이 켜져 있는데 실제로는 안 울리는" 상태가 된다. 이미
/// 지난 시각은 건너뛰고, 같은 알림 번호로 다시 걸면 덮어써지므로 여러 번 불러도
/// 알림이 겹치지 않는다. 권한은 묻지 않는다(전에 알림을 켤 때 이미 물었다).
///
/// 실패해도 로그인은 막지 않는다.
Future<void> restoreCalendarReminders({
  CalendarEventStorage? storage,
  Future<void> Function({
    required String eventId,
    required String title,
    required String body,
    required DateTime scheduledAt,
  })?
  schedule,
  DateTime? now,
}) async {
  try {
    final events = await (storage ?? CalendarEventStorage()).loadAll();
    final scheduleReminder =
        schedule ?? NotificationService.instance.scheduleReminder;
    final current = now ?? DateTime.now();
    for (final event in events) {
      for (final reminder in event.reminders) {
        if (reminder.at.isBefore(current)) continue;
        await scheduleReminder(
          eventId: '${event.id}${reminder.idSuffix}',
          title: event.title,
          body: reminder.body,
          scheduledAt: reminder.at,
        );
      }
    }
  } catch (e) {
    debugPrint('[Calendar] 로그인 후 알림 다시 걸기 실패: $e');
  }
}
