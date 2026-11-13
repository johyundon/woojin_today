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
}
