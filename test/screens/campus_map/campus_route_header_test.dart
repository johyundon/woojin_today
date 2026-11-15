// 길안내 화면 위쪽 카드: 출발·도착 칸, 칸 끝 X로 비우기, 왼쪽 바꾸기 버튼을 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/widgets/campus_map_top_bar.dart';
import 'package:daejin_app/screens/campus_map/widgets/campus_route_header.dart';

void main() {
  Future<List<String>> pump(
    WidgetTester tester, {
    String? origin,
    String? destination,
  }) async {
    final taps = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusRouteHeader(
            onBack: () => taps.add('back'),
            originName: origin,
            destinationName: destination,
            onTapOrigin: () => taps.add('tapOrigin'),
            onTapDestination: () => taps.add('tapDestination'),
            onClearOrigin: () => taps.add('clearOrigin'),
            onClearDestination: () => taps.add('clearDestination'),
            onSwap: () => taps.add('swap'),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('출발만 고르면 도착 칸은 안내 문구, X는 출발 칸에만', (tester) async {
    final taps = await pump(tester, origin: '중앙도서관');

    expect(find.text(CampusMapTitleRow.title), findsOneWidget);
    expect(find.text('중앙도서관'), findsOneWidget);
    expect(find.text(CampusMapTopBar.searchHint), findsOneWidget);
    expect(find.bySemanticsLabel('출발 지우기'), findsOneWidget);
    expect(find.bySemanticsLabel('도착 지우기'), findsNothing);

    await tester.tap(find.bySemanticsLabel('출발 지우기'));
    await tester.tap(find.text(CampusMapTopBar.searchHint));
    await tester.tap(find.bySemanticsLabel('출발·도착 바꾸기'));
    await tester.pumpAndSettle();
    expect(taps, ['clearOrigin', 'tapDestination', 'swap']);
  });

  testWidgets('둘 다 고르면 두 칸 모두 X가 있다', (tester) async {
    final taps = await pump(tester, origin: '중앙도서관', destination: '인문학관');

    await tester.tap(find.bySemanticsLabel('도착 지우기'));
    await tester.pumpAndSettle();
    expect(taps, ['clearDestination']);
  });
}
