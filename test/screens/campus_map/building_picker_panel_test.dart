// 건물 고르기 목록이 "내 위치" 줄을 넘겨받았을 때만, 검색어가 없을 때만 보여 주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/widgets/building_picker_panel.dart';

Widget _panel({VoidCallback? onMe}) => MaterialApp(
  home: Scaffold(
    body: BuildingPickerPanel(onSelected: (_) {}, onSelectMyLocation: onMe),
  ),
);

void main() {
  testWidgets('내 위치 줄을 누르면 알려 주고, 검색어를 치면 숨긴다', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_panel(onMe: () => taps++));

    expect(find.text('내 위치'), findsOneWidget);
    await tester.tap(find.text('내 위치'));
    await tester.pumpAndSettle();
    expect(taps, 1);

    await tester.enterText(find.byType(TextField), '도서관');
    await tester.pump();
    expect(find.text('내 위치'), findsNothing);
  });

  testWidgets('내 위치를 넘기지 않으면 줄이 없다', (tester) async {
    await tester.pumpWidget(_panel());
    expect(find.text('내 위치'), findsNothing);
  });
}
