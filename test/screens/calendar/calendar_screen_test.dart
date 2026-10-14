// CalendarScreen이 새 레이아웃(헤더 월 이동 / 월간 격자 / 선택일 일정 목록)을
// 오버플로우 없이 보여주고, 날짜 선택·월 이동·알림 종 버튼이 동작하는지 확인한다.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:daejin_app/screens/calendar/calendar_screen.dart';
import 'package:daejin_app/screens/calendar/models/calendar_event.dart';
import 'package:daejin_app/screens/calendar/services/calendar_event_storage.dart';
import 'package:daejin_app/screens/calendar/widgets/ringing_bell.dart';

/// 테스트에는 알림 플러그인이 없어서, 권한 요청이 "Android/iOS가 아닌 플랫폼"
/// 분기(항상 허용)로 가도록 아무 구현도 없는 가짜 플랫폼을 꽂아 둔다.
class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {
  @override
  Future<void> cancel({required int id}) async {}
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

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
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
    expect(find.text('${now.year}'), findsOneWidget);
    expect(find.text('${now.month}월'), findsOneWidget);
    for (final label in ['월', '화', '수', '목', '금', '토', '일']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.textContaining('일정 '), findsWidgets); // "일정 N개"
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('샘플 일정이 있는 날을 누르면 그날 일정 카드가 보인다', (tester) async {
    await _pump(tester);

    // 샘플 데이터: 이번 달 14~15일 "왕방축제".
    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();

    expect(find.text('왕방축제'), findsOneWidget);
    expect(find.text('일정 1개'), findsOneWidget);
    expect(find.text('학사일정'), findsOneWidget);
    expect(find.text('종일'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('일정이 없는 날은 안내 문구가 나온다', (tester) async {
    await _pump(tester);

    // 샘플 일정이 없는 날(예: 12일).
    await tester.tap(find.text('12').first);
    await tester.pumpAndSettle();

    expect(find.text('이 날은 일정이 없어요'), findsOneWidget);
    expect(find.text('일정 0개'), findsOneWidget);
  });

  testWidgets('월 이동 버튼으로 이전/다음 달로 넘어가고 그 달 날짜가 선택된다', (tester) async {
    await _pump(tester);
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('${next.month}월'), findsOneWidget);
    expect(find.textContaining('${next.month}월 1일'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('${now.month}월'), findsOneWidget);
  });

  testWidgets('일정이 많아 스크롤해도 달력 격자와 날짜 줄은 제자리에 있다', (tester) async {
    await _pump(tester);
    final now = DateTime.now();

    // 샘플 데이터: 17~19일/20~23일 "수료생 재심사 등록" 등 여러 날짜에 걸친
    // 일정이 있고, 21일에는 일정이 2개 겹친다.
    await tester.tap(find.text('21').first);
    await tester.pumpAndSettle();

    final gridTop = tester.getTopLeft(find.text('${now.month}월').first);
    final headerFinder = find.textContaining('월 21일');
    final headerBefore = tester.getTopLeft(headerFinder);

    await tester.drag(find.byType(ListView).last, const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('${now.month}월').first), gridTop);
    expect(tester.getTopLeft(headerFinder), headerBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('학사일정 카드를 누르면 상세 팝업이 뜨고, 삭제/수정 버튼은 없다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('14').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('왕방축제'));
    await tester.pumpAndSettle();

    expect(find.text('날짜'), findsOneWidget);
    expect(find.text('시간'), findsOneWidget);
    expect(find.text('종일'), findsNWidgets(2)); // 카드 + 팝업
    expect(find.text('알림 없음'), findsOneWidget);
    expect(find.text('삭제하기'), findsNothing);
    expect(find.text('수정하기'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('학사일정 알림', () {
    /// 학사일정(종일) 하나를 저장해 두고 [selectDay]를 선택한 채로 연다.
    Future<void> pumpWithAcademicEvent(
      WidgetTester tester, {
      required DateTime start,
      required DateTime end,
    }) async {
      final today = DateTime.now();
      await CalendarEventStorage().saveAll([
        CalendarEvent(
          id: 'sample-9',
          startDate: start,
          endDate: end,
          label: '학사일정',
          title: '수강신청 변경 기간',
          color: Colors.purple,
        ),
      ]);
      await _pump(tester);
      // 오늘이 일정 기간 안이면 이미 선택돼 있다. 아니면 시작일을 눌러 연다.
      final todayDate = DateTime(today.year, today.month, today.day);
      if (todayDate.isBefore(start) || todayDate.isAfter(end)) {
        if (start.month != today.month) {
          await tester.tap(find.byIcon(Icons.chevron_right));
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

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();

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

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();

        final second = start.month == end.month ? '${end.day}일' : md(end);
        expect(
          find.text('${md(start)}, $second 오전 9시에\n알림이 울립니다'),
          findsOneWidget,
        );
        await tester.tap(find.text('확인'));
        await tester.pumpAndSettle();

        // 상세 팝업에는 "시작일·마감일 오전 9시"로 보인다.
        await tester.tap(find.text('수강신청 변경 기간'));
        await tester.pumpAndSettle();
        expect(find.text('시작일·마감일 오전 9시'), findsOneWidget);
        expect(find.text('삭제하기'), findsNothing); // 학사일정은 알림만 된다
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('이미 시작된 일정(어제~내일): 시작일은 지났으니 마감일(내일)만 걸린다', (tester) async {
      await _withIosPlatform(() async {
        final end = day(1);
        await pumpWithAcademicEvent(tester, start: day(-1), end: end);

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();

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
          await tester.tap(find.byIcon(Icons.chevron_left)); // 지난달 말일이 어제
          await tester.pumpAndSettle();
          await tester.tap(find.text('${yesterday.day}').first);
        }
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();

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
      ReminderOffset? offset = ReminderOffset.tenMinutes,
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
          reminderOffset: offset,
        ),
      ]);
      await _pump(tester);
      if (daysAhead > 0) {
        // 내일이 다음 달이면 달을 넘긴다(넘기면 그 달 1일 = 내일이 선택된다).
        if (date.month != today.month) {
          await tester.tap(find.byIcon(Icons.chevron_right));
        } else {
          await tester.tap(find.text('${date.day}').first);
        }
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
      expect(find.text('10분 전'), findsOneWidget);
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
        await pumpWithMyEvent(tester, offset: null, daysAhead: 1);

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
        await tester.pump(); // 알림 켜짐 반영
        await tester.pump(const Duration(milliseconds: 80));
        expect(bellAngle(), isNot(0)); // 흔들리는 중

        await tester.pumpAndSettle();
        expect(bellAngle().abs(), lessThan(0.001)); // 다 울리고 제자리
      });
    });

    testWidgets('알림 종 버튼으로 켜면 "정각" 알림이 걸리고 저장된다', (tester) async {
      await _withIosPlatform(() async {
        await pumpWithMyEvent(tester, offset: null, daysAhead: 1);

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);

        final saved = await CalendarEventStorage().loadAll();
        expect(saved.single.reminderOffset, ReminderOffset.atStart);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('이미 지난 시각에 알림을 걸면 팝업으로 알려주고 알림은 켜지지 않는다', (tester) async {
      // 오늘 00:00 시작 → "정각" 알림 시각도 오늘 00:00이라 언제 돌려도 이미 지났다.
      await pumpWithMyEvent(
        tester,
        offset: null,
        start: const TimeOfDay(hour: 0, minute: 0),
      );

      await tester.tap(find.byIcon(Icons.notifications_none));
      await tester.pumpAndSettle();

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

    testWidgets('수정 화면에서 지난 시각으로 알림을 걸어 저장하면 일정은 저장되고 팝업이 뜬다', (tester) async {
      await pumpWithMyEvent(
        tester,
        offset: null,
        start: const TimeOfDay(hour: 0, minute: 0), // 오늘 00:00 정각 = 이미 지남
      );

      await tester.tap(find.text('팀플 회의'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('정각'));
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
          offset: null,
          start: const TimeOfDay(hour: 23, minute: 59),
        );

        await tester.tap(find.byIcon(Icons.notifications_none));
        await tester.pumpAndSettle();

        expect(find.text('이미 지난 시간이에요'), findsNothing);
        expect(find.byIcon(Icons.notifications_active), findsOneWidget);
      });
    });

    testWidgets('켜져 있는 알림을 종 버튼으로 끄면 알림이 사라진다', (tester) async {
      await pumpWithMyEvent(tester, daysAhead: 1);

      await tester.tap(find.byIcon(Icons.notifications_active));
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

    testWidgets('수정 화면에서 알림 칩을 바꿔 저장하면 반영된다', (tester) async {
      await _withIosPlatform(() async {
        await pumpWithMyEvent(tester, daysAhead: 1); // 10분 전

        await tester.tap(find.text('팀플 회의'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('수정하기'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('정각'));
        await tester.pump();
        await tester.tap(find.text('저장하기'));
        await tester.pumpAndSettle();

        final saved = await CalendarEventStorage().loadAll();
        expect(saved.single.reminderOffset, ReminderOffset.atStart);
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('X로 닫으면 아무것도 바뀌지 않는다', (tester) async {
      await pumpWithMyEvent(tester);

      await tester.tap(find.text('팀플 회의'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('수정하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '팀플 회의'), '바꾼 제목');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('팀플 회의'), findsOneWidget);
      expect(find.text('바꾼 제목'), findsNothing);
    });
  });

  group('새 일정', () {
    testWidgets('+ 버튼: 제목이 비면 저장 비활성 → 입력하고 저장하면 목록에 추가된다', (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('새 일정'), findsOneWidget);
      // 시간은 하나(09:00)뿐이고, 알림 칩이 있다.
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('10:00'), findsNothing);
      for (final label in ['없음', '정각', '10분 전', '1시간 전', '하루 전']) {
        expect(find.text(label), findsOneWidget);
      }

      ElevatedButton saveButton() => tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '저장하기'),
      );
      expect(saveButton().onPressed, isNull);

      await tester.enterText(find.byType(TextField).first, '스터디');
      await tester.tap(find.text('없음')); // 알림 권한/시각과 무관하게 저장
      await tester.pump();
      expect(saveButton().onPressed, isNotNull);

      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();

      expect(find.text('스터디'), findsOneWidget);
      expect(find.text('09:00'), findsOneWidget);
      final saved = await CalendarEventStorage().loadAll();
      final added = saved.singleWhere((e) => e.title == '스터디');
      expect(added.isUserEvent, isTrue);
      expect(added.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(added.endTime, isNull);
      expect(added.reminderOffset, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('종일 스위치를 켜면 시간 칸이 사라지고, 저장하면 종일 일정이 된다', (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.text('시간'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('시간'), findsNothing);

      await tester.enterText(find.byType(TextField).first, '하루 종일 행사');
      await tester.tap(find.text('없음'));
      await tester.pump();
      await tester.tap(find.text('저장하기'));
      await tester.pumpAndSettle();

      final saved = await CalendarEventStorage().loadAll();
      expect(saved.singleWhere((e) => e.title == '하루 종일 행사').isAllDay, isTrue);
    });

    testWidgets('작은 화면(360x640)에서도 수정 화면과 상세 팝업이 넘치지 않는다', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('14').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('왕방축제'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(10, 10)); // 팝업 닫기
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
