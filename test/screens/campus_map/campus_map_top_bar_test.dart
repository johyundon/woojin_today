// 지도 기본 화면 위쪽 카드(제목 + 검색창 + 카테고리 칩)가 누른 대로 알려 주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/widgets/campus_map_top_bar.dart';

void main() {
  testWidgets('검색창만 보이고 칩은 없다, 검색창을 누르면 알려 준다', (tester) async {
    var searchTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusMapTopBar(
            onBack: () {},
            onTapSearch: () => searchTaps++,
            selectedCategory: null,
            onCategoryTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text(CampusMapTopBar.title), findsOneWidget);
    expect(find.text(CampusMapTopBar.searchHint), findsOneWidget);
    for (final c in hiddenCampusMapCategories) {
      expect(find.text(c.label), findsNothing);
    }

    await tester.tap(find.text(CampusMapTopBar.searchHint));
    await tester.pumpAndSettle();
    expect(searchTaps, 1);
  });
}
