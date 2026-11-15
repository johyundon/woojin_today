// 펼친 달력(CalendarExpandedGrid)이 일정 제목을 막대로 그리고, 한 주에 3줄을
// 넘는 일정은 그 날짜 칸에 "+N"으로 남은 개수를 보여 주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/calendar/models/calendar_event.dart';
import 'package:daejin_app/screens/calendar/widgets/calendar_expanded_grid.dart';

CalendarEvent _event(String id, int start, int end, String title) =>
    CalendarEvent(
      id: id,
      // 2026년 9월은 화요일 시작: 1~5일이 첫 주, 6~12일이 둘째 주.
      startDate: DateTime(2026, 9, start),
      endDate: DateTime(2026, 9, end),
      label: '학사일정',
      title: title,
      color: calendarEventPalette[0],
    );

Future<void> _pump(
  WidgetTester tester,
  List<CalendarEvent> events, {
  ValueChanged<int>? onDaySelected,
  void Function(CalendarEvent event, int day)? onEventTap,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 700 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CalendarExpandedGrid(
          focusedMonth: DateTime(2026, 9),
          events: events,
          selectedDay: 8,
          today: DateTime(2026, 9, 8),
          onDaySelected: onDaySelected ?? (_) {},
          onEventTap: onEventTap,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('여러 날 일정은 한 주 안에서 막대 하나로, 주가 바뀌면 다음 줄에 이어 그린다', (tester) async {
    await _pump(tester, [_event('a', 3, 8, '수강신청 변경')]);

    // 3~5일(첫 주) + 6~8일(둘째 주) → 막대 두 개.
    expect(find.text('수강신청 변경'), findsNWidgets(2));
    final first = tester.getRect(find.text('수강신청 변경').first);
    // 이번 달 3일(다음 달 3일도 회색으로 보여서 앞의 것).
    final day3 = tester.getRect(find.text('3').first);
    expect(first.left, greaterThan(day3.left - 30));
    expect(tester.takeException(), isNull);
  });

  testWidgets('앞뒤 달 날짜는 회색으로 보이고 눌러도 날짜를 고르지 않는다', (tester) async {
    int? tapped;
    await _pump(tester, const [], onDaySelected: (d) => tapped = d);

    // 2026년 9월은 화요일 시작: 앞에 8월 30·31일, 끝에 10월 1~3일이 보인다.
    expect(find.text('31'), findsOneWidget);
    await tester.tap(find.text('31'));
    await tester.tap(find.text('2').last); // 10월 2일
    expect(tapped, isNull);
  });

  testWidgets('한 날에 일정이 4개 이상이면 3개만 막대로, 나머지는 +N으로 보인다', (tester) async {
    await _pump(tester, [
      for (var i = 0; i < 5; i++) _event('e$i', 9, 9, '일정$i'),
    ]);

    expect(find.text('일정0'), findsOneWidget);
    expect(find.text('일정2'), findsOneWidget);
    expect(find.text('일정3'), findsNothing);
    expect(find.text('+2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('긴 제목은 칸을 넘지 않고 잘린다', (tester) async {
    await _pump(tester, [
      _event('long', 16, 16, '2027학년도 대학입학전형 수시모집 원서접수 마감 안내'),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜 칸을 누르면 그 날을 알린다(막대 위를 눌러도)', (tester) async {
    int? tapped;
    await _pump(tester, [
      _event('a', 14, 15, '왕방축제'),
    ], onDaySelected: (d) => tapped = d);

    // 막대는 누름을 무시하고(onEventTap 없음) 아래 날짜 칸이 받는다.
    await tester.tap(find.text('왕방축제'), warnIfMissed: false);
    expect(tapped, 14);
  });

  testWidgets('막대를 누르면 그 일정과 누른 칸의 날짜를 알리고, 날짜 숫자를 누르면 날짜를 알린다', (
    tester,
  ) async {
    int? day;
    CalendarEvent? opened;
    int? barDay;
    final festival = _event('a', 14, 15, '왕방축제');
    await _pump(
      tester,
      [festival],
      onDaySelected: (d) => day = d,
      onEventTap: (e, d) {
        opened = e;
        barDay = d;
      },
    );

    await tester.tap(find.text('왕방축제'));
    await tester.pumpAndSettle();
    expect(opened, festival);
    expect(barDay, 14);
    expect(day, isNull);

    // 14~15일 막대의 오른쪽(15일 칸)을 누르면 15일을 알린다.
    final bar = tester.getRect(find.text('왕방축제'));
    final col15 = tester.getCenter(find.text('15'));
    await tester.tapAt(Offset(col15.dx, bar.center.dy));
    await tester.pumpAndSettle();
    expect(barDay, 15);

    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(day, 14);
  });

  testWidgets('내용에 맞춤이면 일정 없는 주는 일정 있는 주보다 낮다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CalendarExpandedGrid(
              focusedMonth: DateTime(2026, 9),
              // 둘째 주(6~12일)에만 일정 두 줄.
              events: [_event('a', 7, 9, '가'), _event('b', 8, 8, '나')],
              selectedDay: null,
              today: DateTime(2026, 9, 1),
              onDaySelected: (_) {},
              fitWeeksToContent: true,
            ),
          ),
        ),
      ),
    );

    // 같은 열(일요일)의 6일→13일 간격(일정 있는 주)과 13일→20일 간격(없는 주).
    final y6 = tester.getTopLeft(find.text('6')).dy;
    final y13 = tester.getTopLeft(find.text('13')).dy;
    final y20 = tester.getTopLeft(find.text('20')).dy;
    expect(y13 - y6, greaterThan(y20 - y13));
    expect(y20 - y13, lessThan(50));
    expect(find.text('가'), findsOneWidget);
    expect(find.text('나'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
