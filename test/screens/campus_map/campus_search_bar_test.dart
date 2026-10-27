// CampusSearchBar의 초기화(X) 버튼이 선택된 건물이 있을 때만 보이는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/widgets/campus_search_bar.dart';

Widget _bar({String? origin, String? destination}) => MaterialApp(
  home: Scaffold(
    body: CampusSearchBar(
      originName: origin,
      destinationName: destination,
      onTapOrigin: () {},
      onTapDestination: () {},
      onReset: () {},
    ),
  ),
);

void main() {
  testWidgets('아무것도 선택하지 않았으면 X 버튼이 없다', (tester) async {
    await tester.pumpWidget(_bar());

    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('출발지나 목적지가 선택되면 X 버튼이 보인다', (tester) async {
    await tester.pumpWidget(_bar(origin: '진리관'));
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.pumpWidget(_bar(destination: '진리관'));
    expect(find.byIcon(Icons.close), findsOneWidget);
  });
}
