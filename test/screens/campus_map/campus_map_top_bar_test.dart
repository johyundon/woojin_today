// 지도 기본 화면 위쪽 카드(검색창 + 카테고리 칩)가 누른 대로 알려 주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/campus_map/widgets/campus_map_top_bar.dart';

void main() {
  testWidgets('검색창과 칩 3개가 보이고, 누르면 알려 준다', (tester) async {
    var searchTaps = 0;
    int? tappedChip;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CampusMapTopBar(
            onBack: () {},
            onTapSearch: () => searchTaps++,
            selectedCategory: null,
            onCategoryTap: (i) => tappedChip = i,
          ),
        ),
      ),
    );

    expect(find.text(CampusMapTopBar.searchHint), findsOneWidget);
    for (final c in campusMapCategories) {
      expect(find.text(c.label), findsOneWidget);
    }

    await tester.tap(find.text(CampusMapTopBar.searchHint));
    await tester.tap(find.text('식당'));
    await tester.pumpAndSettle();

    expect(searchTaps, 1);
    expect(tappedChip, 1);
  });
}
