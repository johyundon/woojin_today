// CafeteriaScreen이 목데이터를 오버플로우 없이 그리는지, 날짜 이동/아코디언
// 토글/빈 상태가 제대로 동작하는지 확인한다.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/cafeteria/cafeteria_screen.dart';

void main() {
  testWidgets('오늘 날짜로 열리고, 목데이터(점심)가 기본으로 펼쳐져 보인다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CafeteriaScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('오늘의 학식'), findsOneWidget);
    expect(find.text('아침'), findsOneWidget);
    expect(find.text('점심'), findsOneWidget);
    expect(find.text('저녁'), findsOneWidget);
    // 기본으로 점심만 펼쳐져 있어 오늘자 점심 메뉴 식당명이 보여야 한다.
    expect(find.text('데일리밥'), findsOneWidget);
  });

  testWidgets('아침 섹션을 탭하면 펼쳐지고 다시 탭하면 접힌다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CafeteriaScreen()));
    await tester.pumpAndSettle();

    expect(find.text('천원의밥상'), findsNothing);

    await tester.tap(find.text('아침'));
    await tester.pumpAndSettle();
    expect(find.text('천원의밥상'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('아침'));
    await tester.pumpAndSettle();
    expect(find.text('천원의밥상'), findsNothing);
  });

  testWidgets('이전/다음 날짜로 이동해도 오버플로우 없이 렌더링된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CafeteriaScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('데이터가 없는 먼 미래 날짜는 빈 상태 문구를 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CafeteriaScreen()));
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byIcon(Icons.chevron_right));
    }
    await tester.pumpAndSettle();

    expect(find.text('이 날은 등록된 학식 정보가 없어요'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"날짜 직접 선택"을 누르면 날짜 선택 팝업이 뜨고 취소로 닫을 수 있다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CafeteriaScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('날짜 직접 선택'));
    await tester.pumpAndSettle();
    expect(find.text('날짜 선택'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
    expect(find.text('날짜 선택'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('날짜 휠은 년/월/일 순서로 한글 라벨을 보여주고, 바꿔서 확인하면 반영된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CafeteriaScreen()));
    await tester.pumpAndSettle();

    final now = DateTime.now();

    await tester.tap(find.text('날짜 직접 선택'));
    await tester.pumpAndSettle();

    // 년 → 월 → 일 순서로 휠이 배치돼 있고, 전부 한글 단위가 붙어 보인다.
    expect(find.text('${now.year}년'), findsOneWidget);
    expect(find.text('${now.month}월'), findsOneWidget);
    expect(find.text('${now.day}일'), findsOneWidget);

    final wheels = find.byType(CupertinoPicker);
    expect(wheels, findsNWidgets(3));

    // 세 번째(일) 휠을 한 칸 올려서 다음 날로 바꾼다(itemExtent: 36).
    await tester.drag(wheels.at(2), const Offset(0, -36));
    await tester.pumpAndSettle();

    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    final nextDay = DateTime(now.year, now.month, now.day + 1);
    expect(
      find.text(
        '${nextDay.month}월 ${nextDay.day}일 '
        '(${const ['일', '월', '화', '수', '목', '금', '토'][nextDay.weekday % 7]})',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
