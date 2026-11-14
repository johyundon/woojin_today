import 'package:daejin_app/screens/calendar/models/calendar_event.dart';
import 'package:daejin_app/screens/calendar/widgets/event_row.dart';
import 'package:daejin_app/screens/calendar/widgets/ringing_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CalendarEvent event() => CalendarEvent(
    id: 'local-1',
    startDate: DateTime(2026, 10, 31),
    endDate: DateTime(2026, 10, 31),
    label: '개인일정',
    title: '과제 제출',
    color: calendarEventPalette.first,
    startTime: const TimeOfDay(hour: 9, minute: 0),
  );

  // 종 위의 AnimatedScale 중 가장 가까운 것이 종 버튼, 가장 먼 것이 카드다.
  final scales = find.ancestor(
    of: find.byType(RingingBell),
    matching: find.byType(AnimatedScale),
  );

  double currentScale(WidgetTester tester, Finder animatedScale) => tester
      .widget<ScaleTransition>(
        find
            .descendant(
              of: animatedScale,
              matching: find.byType(ScaleTransition),
            )
            .first,
      )
      .scale
      .value;

  testWidgets('종 버튼을 누르면 작아졌다가 돌아오고, 카드는 눌리지 않는다', (tester) async {
    final toggles = <bool>[];
    var cardTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventRow(
            event: event(),
            onReminderToggled: toggles.add,
            onTap: () => cardTaps++,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RingingBell)),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));

    expect(currentScale(tester, scales.first), lessThan(1));
    expect(currentScale(tester, scales.last), 1, reason: '카드는 눌린 모양이 아니어야 한다');

    await gesture.up();
    await tester.pumpAndSettle();

    expect(currentScale(tester, scales.first), 1);
    expect(currentScale(tester, scales.last), 1);
    expect(toggles, [true]);
    expect(cardTaps, 0);
  });

  testWidgets('카드를 누르면 카드만 작아지고 상세 열기가 호출된다', (tester) async {
    final toggles = <bool>[];
    var cardTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventRow(
            event: event(),
            onReminderToggled: toggles.add,
            onTap: () => cardTaps++,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('과제 제출')),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));

    expect(currentScale(tester, scales.last), closeTo(0.95, 0.001));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(currentScale(tester, scales.last), 1);
    expect(cardTaps, 1);
    expect(toggles, isEmpty);
  });

  testWidgets('알림이 켜져 있으면 아래 줄에 다음 알림과 남은 개수 칩이 보이고, 지난 알림은 빠진다', (
    tester,
  ) async {
    Future<void> pump(CalendarEvent e, DateTime now) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventRow(
            event: e,
            onReminderToggled: (_) {},
            onTap: () {},
            now: now,
          ),
        ),
      ),
    );

    final e = event()
      ..setReminderDaysBefore(const [3, 1, 0])
      ..reminderTime = const TimeOfDay(hour: 22, minute: 0);
    // 10/28 22시, 10/30 22시, 10/31 22시 중 10/29 정오 기준 다음은 10/30.
    await pump(e, DateTime(2026, 10, 29, 12));
    expect(find.text('10.30 오후 10시 +1'), findsOneWidget);
    expect(find.text('10.31'), findsOneWidget); // 기간 줄은 그대로

    // 알림이 다 지났으면 칩이 없다.
    await pump(e, DateTime(2026, 11, 1));
    expect(find.byIcon(Icons.notifications_rounded), findsNothing);

    // 알림이 꺼져 있으면 칩이 없다.
    await pump(event(), DateTime(2026, 10, 29));
    expect(find.byIcon(Icons.notifications_rounded), findsNothing);
  });
}
