// 모아보기 화면 위쪽: "편집" 글자 대신 찾기(돋보기) 버튼이 있고, 누르면 통합
// 검색 화면이 열린다.

import 'package:daejin_app/screens/collection_screen.dart';
import 'package:daejin_app/screens/home/widgets/home_top_icon_button.dart';
import 'package:daejin_app/screens/search/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('모아보기 오른쪽 위 찾기 버튼을 누르면 검색 화면이 열린다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CollectionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('편집'), findsNothing);
    final search = find.bySemanticsLabel('검색');
    expect(search, findsOneWidget);
    expect(find.byType(HomeV7IconButton), findsOneWidget);

    await tester.tap(find.byType(HomeV7IconButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SearchScreen), findsOneWidget);
    // 검색 화면이 공지를 불러오기 시작하므로 정리를 위해 화면을 닫는다.
    await tester.pumpWidget(const SizedBox());
  });
}
