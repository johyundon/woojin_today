// 캘린더 일정이 학번별 칸에 따로 저장되고, 예전 한 칸의 일정은 처음 읽을 때 그
// 학생의 칸으로 옮겨지며, 로그인 뒤 알림이 다시 걸리는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/screens/calendar/models/calendar_event.dart';
import 'package:daejin_app/screens/calendar/services/calendar_event_storage.dart';
import 'package:daejin_app/screens/calendar/services/calendar_reminder_restore.dart';

CalendarEvent _event(String id, {List<int> reminder = const []}) =>
    CalendarEvent(
      id: id,
      startDate: DateTime(2026, 12, 10),
      endDate: DateTime(2026, 12, 10),
      label: '내 일정',
      title: '일정 $id',
      color: Colors.blue,
      reminderDaysBefore: reminder,
    );

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  test('학번마다 다른 칸에 저장되어 서로의 일정이 안 보인다', () async {
    final a = CalendarEventStorage(prefs: prefs, userId: '20210001');
    final b = CalendarEventStorage(prefs: prefs, userId: '20210002');
    await a.saveAll([_event('local-a')]);

    expect((await a.loadAll()).map((e) => e.id), ['local-a']);
    expect(await b.loadAll(), isEmpty);
    expect(await prefs.getString('daejin_calendar_events_20210001'), isNotNull);
  });

  test('예전 한 칸의 일정은 처음 읽을 때 그 학생의 칸으로 옮겨진다', () async {
    await CalendarEventStorage(prefs: prefs).saveAll([_event('local-old')]);

    final mine = CalendarEventStorage(prefs: prefs, userId: '20210001');
    expect((await mine.loadAll()).map((e) => e.id), ['local-old']);
    expect(await prefs.getString('daejin_calendar_events'), isNull);
    // 옮긴 뒤 다른 학생에게는 보이지 않는다.
    final other = CalendarEventStorage(prefs: prefs, userId: '20210002');
    expect(await other.loadAll(), isEmpty);
  });

  test('학번별 칸만 로그아웃 때 남길 키로 친다', () {
    expect(
      CalendarEventStorage.isKeptOnLogout('daejin_calendar_events_20210001'),
      isTrue,
    );
    expect(
      CalendarEventStorage.isKeptOnLogout('daejin_calendar_events'),
      isFalse,
    );
  });

  test('로그인 뒤 알림이 켜진 일정의 안 지난 알림만 다시 건다', () async {
    final storage = CalendarEventStorage(prefs: prefs, userId: '20210001');
    await storage.saveAll([
      _event('local-on', reminder: const [0, 1]),
      _event('local-off'),
    ]);
    final scheduled = <String, DateTime>{};

    await restoreCalendarReminders(
      storage: storage,
      // 12월 9일 오전 10시: 하루 전(9일 9시) 알림은 지났고 당일(10일) 알림만 남음.
      now: DateTime(2026, 12, 9, 10),
      schedule: ({
        required String eventId,
        required String title,
        required String body,
        required DateTime scheduledAt,
      }) async => scheduled[eventId] = scheduledAt,
    );

    expect(scheduled.length, 1);
    expect(scheduled.keys.single, startsWith('local-on'));
    expect(scheduled.values.single.day, 10);
  });
}
