// CalendarScreen이 v7 레이아웃(헤더 월 이동 / 월간 격자 / 선택일 일정 목록)을
// 오버플로우 없이 보여주고, 날짜 선택·월 이동·알림 종 버튼이 동작하는지 확인한다.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/screens/calendar/calendar_screen.dart';
import 'package:daejin_app/screens/calendar/models/calendar_event.dart';
import 'package:daejin_app/screens/calendar/services/calendar_event_storage.dart';
import 'package:daejin_app/screens/calendar/widgets/ringing_bell.dart';
import 'package:daejin_app/services/academic_schedule_service.dart';

/// 테스트에는 알림 플러그인이 없어서, 권한 요청이 "Android/iOS가 아닌 플랫폼"
/// 분기(항상 허용)로 가도록 아무 구현도 없는 가짜 플랫폼을 꽂아 둔다.
class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel({required int id}) async {}
}

/// 종 버튼으로 알림 설정 창을 열고, 기본값(당일) 그대로 저장한다.
Future<void> _saveDefaultReminder(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.notifications_none));
  await tester.pumpAndSettle();
  expect(find.text('알림 설정'), findsOneWidget);
  await tester.tap(find.text('저장'));
  await tester.pumpAndSettle();
}

/// 예약·취소된 알림을 기록하는 가짜 iOS 플랫폼(권한은 항상 허용). "며칠 전"을
/// 여러 개 넣으면 날짜마다 예약되고, 끄거나 지우면 전부 취소되는지 확인할 때 쓴다.
class _RecordingIosPlatform extends IOSFlutterLocalNotificationsPlugin {
  final scheduled = <int, DateTime>{};
  final cancelled = <int>{};

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
    bool carPlay = false,
    bool providesAppNotificationSettings = false,
  }) async => true;

  @override
  Future<void> zonedSchedule({
    required int id,
    String? title,
    String? body,
    required tz.TZDateTime scheduledDate,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
    DarwinNotificationDetails? notificationDetails,
  }) async {
    cancelled.remove(id);
    scheduled[id] = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      scheduledDate.hour,
      scheduledDate.minute,
    );
  }

  @override
  Future<void> cancel({required int id}) async => cancelled.add(id);

  /// 지금 걸려 있는(예약 후 취소되지 않은) 알림 시각들, 빠른 순.
  List<DateTime> get active => [
    for (final e in scheduled.entries)
      if (!cancelled.contains(e.key)) e.value,
  ]..sort();
}

/// 알림 예약(zonedSchedule)은 Android에서 플러그인이 반드시 있어야 해서(없으면
/// null 오류) 플러그인이 없는 테스트 환경에서는 iOS로 두고 돌린다 — iOS 쪽은
/// 플러그인이 없으면 아무 일도 하지 않고 지나간다. 테스트 도구 규칙상 설정은
/// 테스트 본문이 끝나기 전에 되돌려야 한다.
Future<void> _withIosPlatform(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

/// 학교 서버 대신 [items] 중 요청한 달에 걸친 일정만 돌려주는 가짜 학사일정 서비스.
class _FakeSchedule implements AcademicScheduleServiceBase {
  _FakeSchedule([this.items = const [], this.fail = false]);

  final List<AcademicScheduleItem> items;
  final bool fail;
  final requested = <String>[];

  @override
  Future<List<AcademicScheduleItem>> fetchMonth(
    int year,
    int month, {
    bool forceRefresh = false,
  }) async {
    requested.add('$year-$month');
    if (fail) throw const AcademicScheduleException('fail');
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    return items
        .where((i) => !i.end.isBefore(start) && !i.start.isAfter(end))
        .toList();
  }
}

/// 예전 샘플 일정과 같은 날짜·제목의 이번 달 학사일정(기존 테스트가 기대는 값).
List<AcademicScheduleItem> _thisMonthSchedule() {
  final now = DateTime.now();
  AcademicScheduleItem item(int startDay, int endDay, String title) =>
      AcademicScheduleItem(
        start: DateTime(now.year, now.month, startDay),
        end: DateTime(now.year, now.month, endDay),
        title: title,
      );
  return [
    item(1, 4, '2026학년도 2학기 수강신청 변경'),
    item(6, 7, '2026학년도 2학기 수강정정 기간'),
    item(8, 11, '2027학년도 대학입학전형 수시모집 원서접수'),
    item(14, 15, '왕방축제'),
    item(17, 19, '수료생 재심사 등록'),
    item(20, 23, '수료생 재심사 등록'),
    item(21, 21, '수업평가 참여 기간'),
    item(28, 28, '2학기 수업일수 1/4선'),
  ];
}

Future<void> _pump(WidgetTester tester, {_FakeSchedule? schedule}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: CalendarScreen(scheduleService: schedule ?? _FakeSchedule()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // 앱은 시작할 때 NotificationService.initialize()에서 서울 시간대를 정한다.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));
  });

  setUp(() {
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('현재 연/월 헤더, 요일 줄, 선택일 안내가 보인다', (tester) async {
    await _pump(tester);
    final now = DateTime.now();

    expect(tester.takeException(), isNull);
    expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
    for (final label in ['월', '화', '수', '목', '금', '토', '일']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.textContaining('일정 '), findsWidgets); // "일정 N개"
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('학사일정이 있는 날을 누르면 그날 일정 카드가 보인다', (tester) async {
    await _pump(tester, schedule: _FakeSchedule(_thisMonthSchedule()));

    // 이번 달 14~15일 "왕방축제".
    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();

    expect(find.text('왕방축제'), findsOneWidget);
    expect(find.text('일정 1개'), findsOneWidget);
    expect(find.text('학사일정'), findsOneWidget);
    // 시간이 없는 학사일정은 "종일" 글자 없이 보인다.
    expect(find.text('종일'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('일정이 없는 날은 안내 문구가 나온다', (tester) async {
    await _pump(tester, schedule: _FakeSchedule(_thisMonthSchedule()));

    // 학사일정이 없는 날(예: 12일).
    await tester.tap(find.text('12').first);
    await tester.pumpAndSettle();

    expect(find.text('이 날은 일정이 없어요'), findsOneWidget);
    expect(find.text('일정 0개'), findsOneWidget);
  });

  testWidgets('월 이동 버튼으로 이전/다음 달로 넘어가고 그 달 날짜가 선택된다', (tester) async {
    await _pump(tester);
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1);

    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.pumpAndSettle();
    expect(find.text('${next.year}년 ${next.month}월'), findsOneWidget);
    expect(find.textContaining('${next.month}월 1일'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
  });

  testWidgets('일정이 많아 스크롤해도 달력 격자와 날짜 줄은 제자리에 있다', (tester) async {
    await _pump(tester, schedule: _FakeSchedule(_thisMonthSchedule()));
    final now = DateTime.now();

    // 17~19일/20~23일 "수료생 재심사 등록" 등 여러 날짜에 걸친 일정이 있고,
    // 21일에는 일정이 2개 겹친다.
    await tester.tap(find.text('21').first);
    await tester.pumpAndSettle();

    final gridTop = tester.getTopLeft(
      find.text('${now.year}년 ${now.month}월').first,
    );
    final headerFinder = find.textContaining('월 21일');
    final headerBefore = tester.getTopLeft(headerFinder);

    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('${now.year}년 ${now.month}월').first),
      gridTop,
    );
    expect(tester.getTopLeft(headerFinder), headerBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('학사일정 카드를 누르면 상세 팝업이 뜨고, 삭제/수정 버튼은 없다', (tester) async {
    await _pump(tester, schedule: _FakeSchedule(_thisMonthSchedule()));

    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('왕방축제'));
    await tester.pumpAndSettle();

    expect(find.text('날짜'), findsOneWidget);
    // 시간이 없는 일정은 카드와 팝업 모두 "종일"·"시간" 줄 없이 보인다.
    expect(find.text('시간'), findsNothing);
    expect(find.text('종일'), findsNothing);
    expect(find.text('알림 없음'), findsOneWidget);
    expect(find.text('삭제하기'), findsNothing);
    expect(find.text('수정하기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('일정 카드를 누르는 동안 살짝 작아졌다가 떼면 돌아온다', (tester) async {
    await _pump(tester, schedule: _FakeSchedule(_thisMonthSchedule()));
    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();

    double scale() => tester
        .widget<AnimatedScale>(
          find.ancestor(
            of: find.text('왕방축제'),
            matching: find.byType(AnimatedScale),
          ),
        )
        .scale;
    expect(scale(), 1);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('왕방축제')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(scale(), lessThan(1));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scale(), 1);
    // 손을 떼면 상세 팝업이 열린다.
    expect(find.text('날짜'), findsOneWidget);
  });

  testWidgets('일정 추가 화면의 날짜는 시트에서 시작~끝을 한 번에 고른다', (tester) async {
    await _pump(tester);
    final now = DateTime.now();
    const sunFirst = ['일', '월', '화', '수', '목', '금', '토'];
    String pill(DateTime d) => '${d.month}.${d.day} ${sunFirst[d.weekday % 7]}';

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pill(now)).first);
    await tester.pumpAndSettle();

    // 영어 기본 창이 아니라 한국어 제목·연월이 보인다.
    expect(find.text('날짜 고르기'), findsOneWidget);
    expect(find.text('${now.year}년 ${now.month}월'), findsOneWidget);
    expect(find.text('OK'), findsNothing);

    // 다음 달로 넘겨 3일 → 1일(시작보다 앞이라 새 시작) → 4일을 누르면 1~4일.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded).last);
    await tester.pumpAndSettle();
    final first = DateTime(now.year, now.month + 1, 1);
    final fourth = DateTime(now.year, now.month + 1, 4);
    await tester.tap(find.text('3').last);
    await tester.pump();
    expect(find.textContaining('끝나는 날짜를 골라 주세요'), findsOneWidget);
    await tester.tap(find.text('1').last);
    await tester.pump();
    await tester.tap(find.text('4').last);
    await tester.pump();
    expect(
      find.text('${first.month}월 1일 ~ ${first.month}월 4일'),
      findsOneWidget,
    );

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.text('날짜 고르기'), findsNothing);
    expect(find.text(pill(first)), findsOneWidget);
    expect(find.text(pill(fourth)), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜 시트에서 하루만 고르고 저장하면 하루짜리가 된다', (tester) async {
    await _pump(tester);
    final now = DateTime.now();
    const sunFirst = ['일', '월', '화', '수', '목', '금', '토'];
    String pill(DateTime d) => '${d.month}.${d.day} ${sunFirst[d.weekday % 7]}';

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pill(now)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2').last);
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    final second = DateTime(now.year, now.month + 1, 2);
    expect(find.text(pill(second)), findsNWidgets(2));
  });

  group('학사일정 연결', () {
    testWidgets('저장된 샘플 일정은 빠지고 받아온 학사일정이 저장된다', (tester) async {
      final now = DateTime.now();
      await CalendarEventStorage().saveAll([
        CalendarEvent(
          id: 'sample-1',
          startDate: DateTime(now.year, now.month, 12),
          endDate: DateTime(now.year, now.month, 12),
          label: '학사일정',
          title: '가짜 샘플 일정',
          color: Colors.blue,
        ),
      ]);
      final schedule = _FakeSchedule(_thisMonthSchedule());
      await _pump(tester, schedule: schedule);

      expect(schedule.requested, ['${now.year}-${now.month}']);
      await tester.tap(find.text('12').first);
      await tester.pumpAndSettle();
      expect(find.text('가짜 샘플 일정'), findsNothing);

      final saved = await CalendarEventStorage().loadAll();
      expect(saved.any((e) => e.id.startsWith('sample-')), isFalse);
      expect(saved.any((e) => e.title == '왕방축제'), isTrue);
    });

    testWidgets('달을 넘기면 그 달 학사일정을 받는다', (tester) async {
      final schedule = _FakeSchedule();
      await _pump(tester, schedule: schedule);
      final now = DateTime.now();
      final next = DateTime(now.year, now.month + 1);

      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(schedule.requested.last, '${next.year}-${next.month}');
    });

    testWidgets('받기에 실패하면 저장된 일정을 그대로 두고 안내한다', (tester) async {
      final now = DateTime.now();
      await CalendarEventStorage().saveAll([
        CalendarEvent(
          id: 'school-${now.year}${now.month.toString().padLeft(2, '0')}12-저장된 학사일정',
          startDate: DateTime(now.year, now.month, 12),
          endDate: DateTime(now.year, now.month, 12),
          label: '학사일정',
          title: '저장된 학사일정',
          color: Colors.blue,
        ),
      ]);
      await _pump(tester, schedule: _FakeSchedule(const [], true));

      expect(find.textContaining('학사일정을 불러오지 못했어요'), findsOneWidget);
      await tester.tap(find.text('12').first);
      await tester.pumpAndSettle();
      expect(find.text('저장된 학사일정'), findsOneWidget);
    });
  });

  group('학사일정 알림', () {
    /// 학사일정(종일) 하나를 저장해 두고 [selectDay]를 선택한 채로 연다.
    Future<void> pumpWithAcademicEvent(
      WidgetTester tester, {
      required DateTime start,
      required DateTime end,
    }) async {
      final today = DateTime.now();
      final item = AcademicScheduleItem(
        start: start,
        end: end,
        title: '수강신청 변경 기간',
      );
      await CalendarEventStorage().saveAll([
        CalendarEvent(
          id: item.id,
          startDate: start,
          endDate: end,
          label: '학사일정',
          title: '수강신청 변경 기간',
          color: Colors.purple,
        ),
      ]);
      await _pump(tester, schedule: _FakeSchedule([item]));
      // 오늘이 일정 기간 안이면 이미 선택돼 있다. 아니면 시작일을 눌러 연다.
      final todayDate = DateTime(today.year, today.month, today.day);
      if (todayDate.isBefore(start) || todayDate.isAfter(end)) {
        if (start.month != today.month) {
          await tester.tap(find.byIcon(Icons.chevron_right_rounded));
        } else {
          await tester.tap(find.text('${start.day}').first);
        }
        await tester.pumpAndSettle();
      }
    }

    DateTime day(int offset) {
      final t = DateTime.now();
      return DateTime(t.year, t.month, t.day + offset);
    }

    String md(DateTime d) => '${d.month}월 ${d.day}일';

    testWidgets('하루짜리: 켜면 그 날 오전 9시에 알림이 울린다는 팝업이 뜨고 알림이 걸린다', (tester) async {
      await _withIosPlatform(() async {
        final date = day(1);
        await pumpWithAcademicEvent(tester, start: date, end: date);

        await _saveDefaultReminder(tester);

        expect(find.text('알림이 설정됐어요'), findsOneWidget);
        expect(find.text('${md(date)} 오전 9시에\n알림이 울립니다'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);

        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
        final saved = await CalendarEventStorage().loadAll();
        expect(
          saved.single.reminderAt,
          DateTime(date.year, date.month, date.day, 9),
        );
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('여러 날(내일~모레): 시작일과 마감일 두 날짜가 팝업에 나온다', (tester) async {
      await _withIosPlatform(() async {
        final start = day(1);
        final end = day(2);
        await pumpWithAcademicEvent(tester, start: start, end: end);

        await _saveDefaultReminder(tester);

        final second = start.month == end.month ? '${end.day}일' : md(end);
        expect(
          find.text('${md(start)}, $second 오전 9시에\n알림이 울립니다'),
          findsOneWidget,
        );
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();

        // 상세 팝업에는 고른 날만 짧게 "시작일"로 보인다.
        await tester.tap(find.text('수강신청 변경 기간'));
        await tester.pumpAndSettle();
        expect(find.text('시작일'), findsOneWidget);
        expect(find.text('삭제하기'), findsNothing); // 학사일정은 알림만 된다
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('여러 날(내일~5일 뒤): 시작·마감 전날·마감일 세 날짜가 나온다', (tester) async {
      await _withIosPlatform(() async {
        final start = day(1);
        final before = day(4);
        final end = day(5);
        await pumpWithAcademicEvent(tester, start: start, end: end);

        await _saveDefaultReminder(tester);

        String next(DateTime prev, DateTime d) =>
            prev.month == d.month ? '${d.day}일' : md(d);
        expect(
          find.text(
            '${md(start)}, ${next(start, before)}, ${next(before, end)} '
            '오전 9시에\n알림이 울립니다',
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('수강신청 변경 기간'));
        await tester.pumpAndSettle();
        expect(find.text('시작일'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('이미 시작된 일정(어제~내일): 시작일은 지났으니 마감일(내일)만 걸린다', (tester) async {
      await _withIosPlatform(() async {
        final end = day(1);
        await pumpWithAcademicEvent(tester, start: day(-1), end: end);

        await _saveDefaultReminder(tester);

        expect(find.text('이미 지난 시간이에요'), findsNothing);
        expect(find.text('${md(end)} 오전 9시에\n알림이 울립니다'), findsOneWidget);
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      });
    });

    testWidgets('기간이 전부 지난 일정(그저께~어제)은 알림이 안 걸리고 지난 시간 팝업이 뜬다', (tester) async {
      await _withIosPlatform(() async {
        await pumpWithAcademicEvent(tester, start: day(-2), end: day(-1));
        // 선택된 날(오늘)에는 이 일정이 안 걸리므로 어제를 눌러 연다.
        final yesterday = day(-1);
        if (yesterday.month == DateTime.now().month) {
          await tester.tap(find.text('${yesterday.day}').first);
        } else {
          await tester.tap(
            find.byIcon(Icons.chevron_left_rounded),
          ); // 지난달 말일이 어제
          await tester.pumpAndSettle();
          await tester.tap(find.text('${yesterday.day}').first);
        }
        await tester.pumpAndSettle();

        await _saveDefaultReminder(tester);

        expect(find.text('이미 지난 시간이에요'), findsOneWidget);
        expect(find.text('알림이 설정됐어요'), findsNothing);
      });
    });
  });

  group('내 일정', () {
    /// 내 일정 하나를 미리 저장해 두고 화면을 연다. [daysAhead]가 1이면 내일
    /// 일정이라, 알림 시각이 이미 지나 못 거는 일 없이 알림 테스트를 할 수 있다.
    Future<void> pumpWithMyEvent(
      WidgetTester tester, {
      List<int> days = const [0],
      TimeOfDay? endTime,
      TimeOfDay start = const TimeOfDay(hour: 15, minute: 0),
      int daysAhead = 0,
    }) async {
      final today = DateTime.now();
      final date = DateTime(today.year, today.month, today.day + daysAhead);
      await CalendarEventStorage().saveAll([
        CalendarEvent(
          id: 'local-1',
          startDate: date,
          endDate: date,
          label: '내 일정',
          title: '팀플 회의',
          color: Colors.blue,
          startTime: start,
          endTime: endTime,
          location: '도서관 3층',
          reminderDaysBefore: days,
        ),
      ]);
      await _pump(tester);
      if (daysAhead > 0) {
        // 다음 달이면 달을 넘긴 뒤(그 달 1일이 선택됨) 그 날짜를 누른다.
        if (date.month != today.month) {
          await tester.tap(find.byIcon(Icons.chevron_right_rounded));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('${date.day}').first);
        await tester.pumpAndSettle();
      }
    }

    testWidgets('카드에 시간 하나와 장소가 보이고, 상세 팝업에 전부 나온다', (tester) async {
      await pumpWithMyEvent(tester);

      expect(find.text('15:00'), findsOneWidget);
      expect(find.text('도서관 3층'), findsOneWidget);

      await tester.tap(find.text('팀플 회의'));
      await tester.pumpAndSettle();

      expect(find.text('15:00'), findsNWidgets(2)); // 카드 + 팝업의 시간 줄
      expect(find.text('도서관 3층'), findsNWidgets(2));
      expect(find.text('정각'), findsOneWidget); // 알림 줄
      expect(find.text('삭제하기'), findsOneWidget);
      expect(find.text('수정하기'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('삭제하기 → 확인창에서 취소하면 그대로, 삭제하면 사라지고 저장도 지워진다', (tester) async {
      await pumpWithMyEvent(tester);

      await tester.tap(find.text('팀플 회의'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제하기'));
      await tester.pumpAndSettle();
      expect(find.text('일정을 삭제할까요?'), findsOneWidget);
      expect(find.textContaining("'팀플 회의' 일정이 삭제되고"), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.text('팀플 회의'), findsOneWidget);

      await tester.tap(find.text('팀플 회의'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();

      expect(find.text('팀플 회의'), findsNothing);
      expect(find.text('이 날은 일정이 없어요'), findsOneWidget);
      final saved = await CalendarEventStorage().loadAll();
      expect(saved.any((e) => e.id == 'local-1'), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('알림 종 버튼을 누르면 종이 울리는 애니메이션이 재생된다', (tester) async {
      await _withIosPlatform(() async {
        await pumpWithMyEvent(tester, days: const [], daysAhead: 1);

        double bellAngle() => tester
            .widget<Transform>(
              find.descendant(
                of: find.byType(RingingBell),
                matching: find.byType(Transform),
              ),
            )
            .transform
            .entry(1, 0);

        expect(bellAngle(), 0);
        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle(); // 알림 설정 창
        await tester.tap(find.text('저장'));
        await tester.pump(); // 알림 켜짐 반영
        await tester.pump(const Duration(milliseconds: 80));
        expect(bellAngle(), isNot(0)); // 흔들리는 중

        await tester.pumpAndSettle();
        expect(bellAngle().abs(), lessThan(0.001)); // 다 울리고 제자리
      });
    });

    testWidgets('알림 종 버튼으로 켜면 "정각" 알림이 걸리고 저장된다', (tester) async {
      await _withIosPlatform(() async {
        await pumpWithMyEvent(tester, days: const [], daysAhead: 1);

        await _saveDefaultReminder(tester);
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);

        final saved = await CalendarEventStorage().loadAll();
        expect(saved.single.reminderDaysBefore, [0]);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('이미 지난 시각에 알림을 걸면 팝업으로 알려주고 알림은 켜지지 않는다', (tester) async {
      // 오늘 00:00 시작 → "정각" 알림 시각도 오늘 00:00이라 언제 돌려도 이미 지났다.
      await pumpWithMyEvent(
        tester,
        days: const [],
        start: const TimeOfDay(hour: 0, minute: 0),
      );

      await _saveDefaultReminder(tester);

      expect(find.text('이미 지난 시간이에요'), findsOneWidget);
      expect(find.textContaining('00:00'), findsWidgets); // 어느 시각이 지났는지 보여준다
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byIcon(Icons.notifications_active), findsNothing);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('이미 지난 시간이에요'), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      final saved = await CalendarEventStorage().loadAll();
      expect(saved.single.hasReminder, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('알림이 켜진 일정을 지난 시각으로 고쳐 저장하면 일정은 저장되고 팝업이 뜬다', (tester) async {
      await pumpWithMyEvent(
        tester,
        start: const TimeOfDay(hour: 0, minute: 0), // 오늘 00:00 정각 = 이미 지남
      );

      await tester.tap(find.text('팀플 회의'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '팀플 회의'), '새벽 회의');
      await tester.pump();
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();

      expect(find.text('이미 지난 시간이에요'), findsOneWidget);
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(find.text('새벽 회의'), findsOneWidget);
      final saved = await CalendarEventStorage().loadAll();
      expect(saved.single.title, '새벽 회의'); // 일정은 저장됐고
      expect(saved.single.hasReminder, isFalse); // 알림만 빠졌다
      expect(tester.takeException(), isNull);
    });

    testWidgets('일정 시각이 아직 안 지났으면 "정각" 알림은 걸린다(23:59 일정)', (tester) async {
      // 일정 시각이 곧 오는데 "10분 전"만 이미 지난 상황을 흉내 낸다 — 종 버튼은
      // 정각이 기본이라 걸려야 한다. (23:59~24:00 사이에 돌리면 실패한다.)
      await _withIosPlatform(() async {
        await pumpWithMyEvent(
          tester,
          days: const [],
          start: const TimeOfDay(hour: 23, minute: 59),
        );

        await _saveDefaultReminder(tester);

        expect(find.text('이미 지난 시간이에요'), findsNothing);
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      });
    });

    testWidgets('켜져 있는 알림을 종 버튼으로 끄면 알림이 사라진다', (tester) async {
      await pumpWithMyEvent(tester, daysAhead: 1);

      await tester.tap(find.byIcon(Icons.notifications_active));
      await tester.pumpAndSettle();
      await tester.tap(find.text('알림 끄기'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
      final saved = await CalendarEventStorage().loadAll();
      expect(saved.single.hasReminder, isFalse);
    });

    testWidgets('수정하기 → 값이 채워져 있고 시간은 하나뿐이며, 고쳐 저장하면 반영된다', (tester) async {
      await _withIosPlatform(() async {
        // 예전에 15~16시 구간으로 저장된 일정.
        await pumpWithMyEvent(
          tester,
          endTime: const TimeOfDay(hour: 16, minute: 0),
          daysAhead: 1,
        );

        await tester.tap(find.text('팀플 회의'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('수정하기'));
        await tester.pumpAndSettle();

        expect(find.text('일정 수정'), findsOneWidget);
        expect(find.widgetWithText(TextField, '팀플 회의'), findsOneWidget);
        expect(find.widgetWithText(TextField, '도서관 3층'), findsOneWidget);
        expect(find.text('15:00'), findsOneWidget);
        expect(find.text('16:00'), findsNothing); // 끝나는 시간 칸이 없다

        await tester.enterText(
          find.widgetWithText(TextField, '팀플 회의'),
          '졸업 작품 회의',
        );
        await tester.pump();
        await tester.tap(find.text('저장하기'));
        await tester.pumpAndSettle();

        expect(find.text('졸업 작품 회의'), findsOneWidget);
        final saved = await CalendarEventStorage().loadAll();
        expect(saved.single.title, '졸업 작품 회의');
        expect(saved.single.id, 'local-1'); // 새로 만들어진 게 아니라 고쳐진 것
        expect(saved.single.startTime, const TimeOfDay(hour: 15, minute: 0));
        expect(saved.single.endTime, isNull); // 구간이 아니라 시간 하나만 남는다
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('수정 화면에는 알림 칩이 없고, 저장해도 알림 날짜는 그대로다', (tester) async {
      await _withIosPlatform(() async {
        // 날짜가 지나 알림이 꺼지지 않게 넉넉히 뒤 일정으로 한다.
        await pumpWithMyEvent(tester, days: const [7, 1], daysAhead: 20);

        await tester.tap(find.text('팀플 회의'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('수정하기'));
        await tester.pumpAndSettle();
        for (final label in ['없음', '10분 전', '1시간 전']) {
          expect(find.text(label), findsNothing);
        }

        await tester.tap(find.text('저장하기'));
        await tester.pumpAndSettle();
        if (find.text('확인').evaluate().isNotEmpty) {
          await tester.tap(find.text('확인'));
          await tester.pumpAndSettle();
        }

        final saved = await CalendarEventStorage().loadAll();
        expect(saved.single.reminderDaysBefore, [7, 1]);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('알림 설정 창: 버튼으로 며칠 전을 고르면 그날 알림이 걸리고, 지난 날은 막힌다', (
      tester,
    ) async {
      final platform = _RecordingIosPlatform();
      FlutterLocalNotificationsPlatform.instance = platform;
      await _withIosPlatform(() async {
        await pumpWithMyEvent(tester, days: const [], daysAhead: 1);
        final today = DateTime.now();
        DateTime at(int daysBefore) =>
            DateTime(today.year, today.month, today.day + 1 - daysBefore, 15);

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();
        // 처음엔 당일(정각)만 골라져 있다.
        bool selected(String label) =>
            tester
                .widget<Semantics>(
                  find
                      .ancestor(
                        of: find.text(label),
                        matching: find.byWidgetPredicate(
                          (w) => w is Semantics && w.properties.button == true,
                        ),
                      )
                      .first,
                )
                .properties
                .selected ==
            true;
        expect(selected('정각'), isTrue);
        expect(selected('1일 전'), isFalse);

        // 내일 일정이면 1주 전은 이미 지나 눌리지 않는다.
        expect(find.text('지난 날짜'), findsWidgets);
        await tester.tap(find.text('1주 전'));
        await tester.pumpAndSettle();
        expect(selected('1주 전'), isFalse);

        // 1일 전을 켜고, 정각은 끈다.
        await tester.tap(find.text('1일 전'));
        await tester.tap(find.text('정각'));
        await tester.pumpAndSettle();
        expect(selected('1일 전'), isTrue);
        expect(selected('정각'), isFalse);

        await tester.tap(find.text('저장'));
        await tester.pump(const Duration(milliseconds: 500));

        // 1일 전(오늘 15:00)이 걸렸다 — 오늘 15시가 지났으면 지난 경우가 된다.
        final saved = await CalendarEventStorage().loadAll();
        if (at(1).isAfter(today)) {
          expect(platform.active, [at(1)]);
          expect(saved.single.reminderDaysBefore, [1]);
        } else {
          expect(platform.active, isEmpty);
          expect(find.text('이미 지난 시간이에요'), findsOneWidget);
          await tester.tap(find.text('확인'));
        }
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      });
    });

    testWidgets('알림 설정 창에서 알림 끄기를 누르면 걸려 있던 알림이 모두 취소된다', (tester) async {
      final platform = _RecordingIosPlatform();
      FlutterLocalNotificationsPlatform.instance = platform;
      await _withIosPlatform(() async {
        await pumpWithMyEvent(tester, days: const [], daysAhead: 20);
        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2주 전'));
        await tester.pumpAndSettle();
        // "날짜 직접 고르기"로 오늘(= 20일 전)을 고른다.
        await tester.tap(find.text('날짜 직접 고르기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('저장').last);
        await tester.pumpAndSettle();
        expect(find.text('20일 전'), findsOneWidget);
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();
        // 20일 전(오늘 15:00)은 지났을 수도 있다.
        final todayAt = DateTime.now().copyWith(hour: 15, minute: 0);
        expect(platform.active.length, todayAt.isAfter(DateTime.now()) ? 3 : 2);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // 상세 팝업에는 짧게 보이고, "설정"으로 같은 창이 열린다.
        await tester.tap(find.text('팀플 회의'));
        await tester.pumpAndSettle();
        expect(find.text('20일 전 외 2개'), findsOneWidget);
        await tester.tap(find.text('설정'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('알림 끄기'));
        await tester.pumpAndSettle();

        expect(platform.active, isEmpty);
        expect(find.text('알림 없음'), findsOneWidget);
        final saved = await CalendarEventStorage().loadAll();
        expect(saved.single.hasReminder, isFalse);
      });
    });

    testWidgets('일정을 지우면 날짜마다 걸린 알림이 모두 취소된다', (tester) async {
      final platform = _RecordingIosPlatform();
      FlutterLocalNotificationsPlatform.instance = platform;
      await _withIosPlatform(() async {
        await pumpWithMyEvent(tester, days: const [], daysAhead: 20);
        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();
        await tester.tap(find.text('2주 전'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();
        expect(platform.active.length, 2);

        await tester.tap(find.text('팀플 회의'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('삭제하기'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('삭제').last);
        await tester.pumpAndSettle();

        expect(platform.active, isEmpty);
        expect(await CalendarEventStorage().loadAll(), isEmpty);
      });
    });

    testWidgets('X로 닫으면 아무것도 바뀌지 않는다', (tester) async {
      await pumpWithMyEvent(tester);

      await tester.tap(find.text('팀플 회의'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '팀플 회의'), '바꾼 제목');
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('팀플 회의'), findsOneWidget);
      expect(find.text('바꾼 제목'), findsNothing);
    });
  });

  group('새 일정', () {
    testWidgets('+ 버튼: 제목이 비면 저장 비활성 → 입력하고 저장하면 목록에 추가된다', (tester) async {
      await _withIosPlatform(() async {
        await _pump(tester);

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(find.text('새 일정'), findsOneWidget);
        // 시간은 하나(09:00)뿐이고, 알림 칩은 숨겨져 있다(종 버튼에서 정함).
        expect(find.text('09:00'), findsOneWidget);
        expect(find.text('10:00'), findsNothing);
        expect(find.text('10분 전'), findsNothing);

        ElevatedButton saveButton() => tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '저장하기'),
        );
        expect(saveButton().onPressed, isNull);

        await tester.enterText(find.byType(TextField).first, '스터디');
        await tester.pump();
        expect(saveButton().onPressed, isNotNull);

        await tester.tap(find.text('저장하기'));
        await tester.pumpAndSettle();
        // 기본 정각 알림(오늘 09:00)이 이미 지났으면 안내 팝업이 뜬다.
        final past = find.text('이미 지난 시간이에요').evaluate().isNotEmpty;
        if (past) {
          await tester.tap(find.text('확인'));
          await tester.pumpAndSettle();
        }

        expect(find.text('스터디'), findsOneWidget);
        expect(find.text('09:00'), findsOneWidget);
        final saved = await CalendarEventStorage().loadAll();
        final added = saved.singleWhere((e) => e.title == '스터디');
        expect(added.isUserEvent, isTrue);
        expect(added.startTime, const TimeOfDay(hour: 9, minute: 0));
        expect(added.endTime, isNull);
        expect(added.reminderDaysBefore, past ? isEmpty : [0]);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('종일 스위치를 켜면 시간 칸이 사라지고, 저장하면 종일 일정이 된다', (tester) async {
      await _withIosPlatform(() async {
        await _pump(tester);

        await tester.tap(find.byIcon(Icons.add_rounded));
        await tester.pumpAndSettle();
        expect(find.text('시간'), findsOneWidget);

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(find.text('시간'), findsNothing);

        await tester.enterText(find.byType(TextField).first, '하루 종일 행사');
        await tester.pump();
        await tester.tap(find.text('저장하기'));
        await tester.pumpAndSettle();
        if (find.text('확인').evaluate().isNotEmpty) {
          await tester.tap(find.text('확인'));
          await tester.pumpAndSettle();
        }

        final saved = await CalendarEventStorage().loadAll();
        expect(
          saved.singleWhere((e) => e.title == '하루 종일 행사').isAllDay,
          isTrue,
        );
      });
    });

    testWidgets('작은 화면(360x640)에서도 수정 화면과 상세 팝업이 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: CalendarScreen(
            scheduleService: _FakeSchedule(_thisMonthSchedule()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('14').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('왕방축제'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 10)); // 팝업 닫기
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
