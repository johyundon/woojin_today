import 'package:daejin_app/screens/calendar/widgets/date_pick_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('고를 수 있는 기간 밖 날은 눌리지 않고, 기간 밖 달로 넘어가지 않는다', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showDatePickSheet(
                context,
                title: '알림 받을 날짜',
                initialDate: DateTime(2026, 11, 13),
                today: DateTime(2026, 11, 13),
                firstDate: DateTime(2026, 11, 13),
                lastDate: DateTime(2026, 11, 26),
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    // 27일(끝난 뒤)·12일(지난 날)은 눌러도 그대로 13일이다.
    await tester.tap(find.text('27'));
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    // 다음 달·지난 달로는 넘어가지 않는다.
    await tester.tap(find.byIcon(Icons.chevron_right_rounded));
    await tester.tap(find.byIcon(Icons.chevron_left_rounded));
    await tester.pumpAndSettle();
    expect(find.text('2026년 11월'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 13));

    // 기간 안의 날(26일)은 고를 수 있다.
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('26'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 26));
  });

  testWidgets('여러 날 고르기: 누를 때마다 골라지고 다시 누르면 풀리며, 최대 개수를 넘지 않는다', (
    tester,
  ) async {
    List<DateTime>? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showMultiDatePickSheet(
                context,
                title: '알림 받을 날짜',
                initialMonth: DateTime(2026, 11, 14),
                today: DateTime(2026, 11, 14),
                firstDate: DateTime(2026, 11, 14),
                lastDate: DateTime(2026, 11, 30),
                maxCount: 3,
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('누르거나 끌어서 여러 날을 고를 수 있어요'), findsOneWidget);

    for (final day in ['18', '19', '20', '21']) {
      await tester.tap(find.text(day));
    }
    await tester.tap(find.text('13')); // 기간 밖이라 안 골라진다
    await tester.pumpAndSettle();
    expect(find.text('3일 골랐어요 · 더는 고를 수 없어요'), findsOneWidget);
    // 19일을 다시 누르면 풀리고, 그 자리에 22일을 고를 수 있다.
    await tester.tap(find.text('19'));
    await tester.tap(find.text('22'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(picked, [
      DateTime(2026, 11, 18),
      DateTime(2026, 11, 20),
      DateTime(2026, 11, 22),
    ]);
  });

  testWidgets('여러 날 고르기: 끌면 처음 칸부터 지금 칸까지 연속으로 골라지고, 골라진 칸에서 끌면 풀린다', (
    tester,
  ) async {
    List<DateTime>? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              picked = await showMultiDatePickSheet(
                context,
                title: '알림 받을 날짜',
                initialMonth: DateTime(2026, 11, 14),
                today: DateTime(2026, 11, 14),
                firstDate: DateTime(2026, 11, 14),
                lastDate: DateTime(2026, 11, 30),
                maxCount: 14,
              );
            },
            child: const Text('열기'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    // 16일에서 20일까지 끌면 16~20일이 이어서 골라진다.
    Future<void> drag(String from, String to) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(from)),
      );
      await gesture.moveTo(tester.getCenter(find.text(to)));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    await drag('16', '20');
    expect(find.text('5일 골랐어요'), findsOneWidget);
    // 골라진 18일에서 19일까지 끌면 그 두 날이 풀린다.
    await drag('18', '19');
    expect(find.text('3일 골랐어요'), findsOneWidget);

    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(picked, [
      DateTime(2026, 11, 16),
      DateTime(2026, 11, 17),
      DateTime(2026, 11, 20),
    ]);
  });
}
