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
  ValueChanged<CalendarEvent>? onEventTap,
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
    final day3 = tester.getRect(find.text('3'));
    expect(first.left, greaterThan(day3.left - 30));
    expect(tester.takeException(), isNull);
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

  testWidgets('막대를 누르면 그 일정을 알리고(상세 열기), 날짜 숫자를 누르면 날짜를 알린다', (tester) async {
    int? day;
    CalendarEvent? opened;
    final festival = _event('a', 14, 15, '왕방축제');
    await _pump(
      tester,
      [festival],
      onDaySelected: (d) => day = d,
      onEventTap: (e) => opened = e,
    );

    await tester.tap(find.text('왕방축제'));
    await tester.pumpAndSettle();
    expect(opened, festival);
    expect(day, isNull);

    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(day, 14);
  });
}
