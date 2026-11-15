// 하단 탭 바의 가운데 홈 버튼은 홈 화면일 때만 파랗고, 다른 탭에서는 회색이다.
// 다른 탭에서도 파라면 어느 탭에 있는지 헷갈리기 때문이다.

import 'package:daejin_app/screens/home/widgets/home_bottom_nav.dart';
import 'package:daejin_app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Color? _centerColor(WidgetTester tester) {
  final box = tester.widget<Container>(
    find
        .ancestor(
          of: find.bySemanticsLabel('홈'),
          matching: find.byType(Container),
        )
        .first,
  );
  return (box.decoration as BoxDecoration?)?.color;
}

Future<void> _pump(WidgetTester tester, int selectedIndex) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        bottomNavigationBar: HomeBottomNav(selectedIndex: selectedIndex),
      ),
    ),
  );
}

void main() {
  testWidgets('홈 화면이면 가운데 버튼이 파랗다', (tester) async {
    await _pump(tester, 2);
    expect(_centerColor(tester), AppColors.blueSoft);
  });

  testWidgets('다른 탭이면 가운데 버튼이 회색이다', (tester) async {
    await _pump(tester, 1);
    expect(_centerColor(tester), AppColors.fill);
  });

  testWidgets('모아보기·캘린더·홈·시간표·MY 순서로 보이고, 탭 번호는 그대로다', (tester) async {
    final tapped = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: HomeBottomNav(
            selectedIndex: 2,
            onTap: tapped.add,
          ),
        ),
      ),
    );

    double x(String label) => tester.getCenter(find.text(label)).dx;
    final home = tester.getCenter(find.bySemanticsLabel('홈')).dx;
    expect(x('모아보기'), lessThan(x('캘린더')));
    expect(x('캘린더'), lessThan(home));
    expect(home, lessThan(x('시간표')));
    expect(x('시간표'), lessThan(x('MY')));

    for (final label in ['모아보기', '캘린더', '시간표', 'MY']) {
      await tester.tap(find.text(label));
    }
    expect(tapped, [1, 3, 0, 4]);
  });
}
