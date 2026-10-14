// MileageScreen이 두 탭을 오버플로우 없이 보여주고, 공지 → 대상자 확인
// 다이얼로그 → 명단보기 다이얼로그 → 학번 검색까지 이어지는 흐름이 제대로
// 동작하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/mileage/mileage_screen.dart';

void main() {
  testWidgets('총 마일리지 · 이번 학기 · 장학 기준 · 적립 내역이 렌더링된다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MileageScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('모은 마일리지'), findsOneWidget);
    expect(find.text('1,240'), findsOneWidget);
    expect(find.text('실버까지 260P'), findsOneWidget);
    expect(find.text('+620P'), findsOneWidget);
    expect(find.text('2,000P'), findsOneWidget);
    expect(find.text('신입생 멘토링 참여'), findsOneWidget);
    expect(find.text('+200'), findsOneWidget);
  });

  testWidgets('장학 기준 카드를 누르면 공지 3건이 보인다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MileageScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장학 기준'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('이용진'), findsNWidgets(3));
    expect(find.text('대상자 확인'), findsNWidgets(3));
  });

  testWidgets('대상자 확인 → 명단보기 → 검색까지 이어진다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MileageScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('장학 기준'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('대상자 확인').first);
    await tester.pumpAndSettle();
    expect(find.text('아쉽게도 대상자 명단에 없어요..'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('명단보기'));
    await tester.pumpAndSettle();
    expect(find.text('명단 (800명)'), findsOneWidget);
    expect(find.text('20181760'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(find.byType(TextField), '20181760');
    await tester.pumpAndSettle();
    // 검색창 자체에도 입력한 텍스트가 보이고, 그리드에도 매칭된 카드가
    // 남아있어 "20181760"은 두 군데(검색창 + 그리드 항목)에서 찾아진다.
    expect(
      find.descendant(
        of: find.byType(GridView),
        matching: find.text('20181760'),
      ),
      findsOneWidget,
    );
    expect(find.text('20210665'), findsNothing);

    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.text('명단 (800명)'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
