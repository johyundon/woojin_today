// 시간표 화면 "강의시간 알림" 토글이 실제로 알림을 예약·취소하는지, 켜짐 상태가
// 기기에 저장돼 다시 열어도 유지되는지 확인한다.
import 'package:daejin_app/screens/timetable/models/saved_timetable.dart';
import 'package:daejin_app/screens/timetable/services/class_reminder_settings.dart';
import 'package:daejin_app/screens/timetable/services/saved_timetable_storage.dart';
import 'package:daejin_app/screens/timetable/timetable_screen.dart';
import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/fakes/fake_course_catalog_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';
import 'package:daejin_app/services/notification_service.dart';
import 'package:daejin_app/services/session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _FakeStorage implements SavedTimetableStorage {
  @override
  Future<List<SavedTimetable>> loadAll() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMyTimetable implements MyTimetableServiceBase {
  @override
  Future<MyTimetableResponse> fetchMyTimetable({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async => const MyTimetableResponse(courses: [_course]);
}

/// 호출을 순서대로 기록하는 가짜 알림 서비스.
class _FakeNotifications implements NotificationService {
  _FakeNotifications({this.granted = true});

  final bool granted;
  final calls = <String>[];
  final scheduled = <({String title, DateTime firstAt})>[];

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return granted;
  }

  @override
  Future<void> cancelAllClassReminders() async => calls.add('cancelAll');

  @override
  Future<void> scheduleWeeklyClassReminder({
    required String eventId,
    required String title,
    required String body,
    required DateTime firstAt,
  }) async {
    calls.add('schedule');
    scheduled.add((title: title, firstAt: firstAt));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _course = CourseCatalogItem(
  seq: 1,
  courseCode: '900101',
  section: '01',
  courseName: '가상자료구조',
  courseType: '전필',
  credit: 3,
  targetGrade: '',
  professor: '김가상',
  rawSchedule: '월10:00-11:15,수10:00-11:15',
  room: '가상관 101',
  isClosed: false,
  capacity: 0,
  waitlistCount: 0,
  enrollmentRatio: '',
);

Future<void> _pump(
  WidgetTester tester,
  _FakeNotifications notifications,
) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: TimetableScreen(
        jsessionId: 'j',
        wmonid: 'w',
        userId2: 'u',
        courseCatalogService: FakeCourseCatalogService(),
        myTimetableService: _FakeMyTimetable(),
        savedTimetableStorage: _FakeStorage(),
        notificationService: notifications,
        now: () => DateTime(2026, 10, 26, 9), // 월요일 9시
      ),
    ),
  );
  await tester.pumpAndSettle();
  tester.takeException(); // 첫 프레임(실측 전) 일시 오버플로우는 기존 동작.
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

/// 토글을 누르고 위쪽 안내 배너가 사라질 때까지 기다린다.
Future<void> _tapToggle(WidgetTester tester) async {
  await tester.tap(find.byType(Switch));
  await _waitBanner(tester);
}

/// 배너는 내려오는 애니메이션이 끝난 뒤 2.6초를 기다렸다 올라간다.
Future<void> _waitBanner(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

bool _switchValue(WidgetTester tester) =>
    tester.widget<Switch>(find.byType(Switch)).value;

void main() {
  setUp(() {
    SessionCache.clear();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('처음에는 꺼져 있고, 아무 알림도 건드리지 않는다', (tester) async {
    final notifications = _FakeNotifications();
    await _pump(tester, notifications);

    expect(_switchValue(tester), isFalse);
    expect(notifications.calls, isEmpty);
  });

  testWidgets('켜면 권한을 묻고, 요일마다 수업 10분 전 알림을 예약하고 저장한다', (tester) async {
    final notifications = _FakeNotifications();
    await _pump(tester, notifications);

    await _tapToggle(tester);

    expect(_switchValue(tester), isTrue);
    expect(notifications.calls, [
      'permission',
      'cancelAll',
      'schedule',
      'schedule',
    ]);
    expect(notifications.scheduled.map((s) => s.firstAt), [
      DateTime(2026, 10, 26, 9, 50), // 월 10:00 수업
      DateTime(2026, 10, 28, 9, 50), // 수 10:00 수업
    ]);
    expect(notifications.scheduled.first.title, '가상자료구조 수업 10분 전');
    expect(await ClassReminderSettings().isEnabled(), isTrue);
  });

  testWidgets('권한을 거부하면 토글은 꺼진 채로 안내만 보여준다', (tester) async {
    final notifications = _FakeNotifications(granted: false);
    await _pump(tester, notifications);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('알림 권한이 꺼져 있어요'), findsOneWidget);
    await _waitBanner(tester);

    expect(_switchValue(tester), isFalse);
    expect(notifications.calls, ['permission']);
    expect(await ClassReminderSettings().isEnabled(), isFalse);
  });

  testWidgets('끄면 강의시간 알림을 모두 취소하고 저장한다', (tester) async {
    final notifications = _FakeNotifications();
    await _pump(tester, notifications);
    await _tapToggle(tester);
    notifications.calls.clear();

    await _tapToggle(tester);

    expect(_switchValue(tester), isFalse);
    expect(notifications.calls, ['cancelAll']);
    expect(await ClassReminderSettings().isEnabled(), isFalse);
  });

  testWidgets('저장된 켜짐 상태로 다시 열면 켜져 있고 불러온 시간표로 다시 예약한다', (tester) async {
    await ClassReminderSettings().setEnabled(true);
    final notifications = _FakeNotifications();
    await _pump(tester, notifications);

    // 앱을 다시 연 것과 같다: 권한을 다시 묻지 않고, 불러온 시간표로 맞춘다.
    expect(_switchValue(tester), isTrue);
    expect(notifications.calls, ['cancelAll', 'schedule', 'schedule']);
  });
}
