// 모아보기 화면(Figma "04 모아보기", node 2140:2): 찾기 버튼과 공지 배너 없이
// "자주 찾는 메뉴" 카드와 "모든 메뉴" 목록만 보이고, 예전 "캠퍼스 · 도구" 칸의
// 기능은 목록 아래쪽 줄로 들어가 있다.

import 'package:daejin_app/screens/collection_screen.dart';
import 'package:daejin_app/screens/home/widgets/home_top_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('시안대로 구역 제목·버튼이 보이고 찾기 버튼은 숨겨져 있다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CollectionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('자주 찾는 메뉴'), findsOneWidget);
    expect(find.text('모든 메뉴'), findsOneWidget);
    expect(find.text('바로가기'), findsNWidgets(3));
    expect(find.byType(HomeV7IconButton), findsNothing);
    expect(find.text('캠퍼스 · 도구'), findsNothing);

    // 도구 4개는 목록 줄로 한 번씩만 나온다.
    for (final label in ['날씨', '캠퍼스 지도', '파일공유', '상담 예약']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('쌓은 점수와 내역'), findsOneWidget);
    // "연강"은 캠퍼스 지도와 같은 화면이라 목록에서 뺐다.
    expect(find.text('연강'), findsNothing);
  });

  testWidgets('많이 연 기능이 자주 찾는 메뉴 카드 맨 앞에 온다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'feature_usage_counts': '{"마일리지": 5}',
    });
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CollectionScreen()));
    await tester.pumpAndSettle();

    // 카드 3장: 마일리지, 시간표, 학식(캘린더는 밀려남).
    expect(find.text('바로가기'), findsNWidgets(3));
    final cardX = [
      for (final l in ['마일리지', '시간표', '학식'])
        tester.getTopLeft(find.text(l).first).dx,
    ];
    expect(cardX[0] < cardX[1] && cardX[1] < cardX[2], isTrue);
    // 캘린더는 카드에서 빠지고 하단 탭 글자로만 남는다.
    expect(find.text('캘린더'), findsOneWidget);
  });

  testWidgets('파일공유는 준비 중이라 누르면 화면 대신 안내창이 뜬다', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: CollectionScreen()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('파일공유'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('파일공유'));
    await tester.pumpAndSettle();
    expect(find.text('준비 중인 기능이에요'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
  });
}
