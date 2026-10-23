// GraduationCreditScreen이 목데이터 합계/카테고리 칩/과목 상세 바텀시트를
// 오버플로우 없이 보여주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/graduation/graduation_credit_screen.dart';
import 'package:daejin_app/screens/graduation/services/graduation_credit_mock_data.dart';

void main() {
  testWidgets('총 이수학점과 카테고리 칩을 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GraduationCreditScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('총 이수학점'), findsOneWidget);
    expect(
      find.text(
        '${GraduationCreditMockData.totalEarned}/${GraduationCreditMockData.totalRequired}',
      ),
      findsOneWidget,
    );

    final remaining =
        GraduationCreditMockData.totalRequired -
        GraduationCreditMockData.totalEarned;
    expect(find.text('졸업까지\n$remaining학점 남았어요'), findsOneWidget);

    // 가로 스크롤 칩 줄은 뷰포트 밖 항목을 지연 생성하므로, 끝까지
    // 스크롤해 마지막 카테고리("전공선택")까지 실제로 렌더링되는지 본다.
    final chipRow = find.byType(ListView).at(1);
    await tester.dragUntilVisible(
      find.text('전공선택'),
      chipRow,
      const Offset(-200, 0),
    );
    expect(find.text('전공선택'), findsWidgets);
  });

  testWidgets('과목이 있는 카테고리 칩을 누르면 상세 목록 오버레이 카드가 뜬다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GraduationCreditScreen()));
    await tester.pumpAndSettle();

    final majorCategory = GraduationCreditMockData.categories.firstWhere(
      (c) => c.label == '주전공',
    );

    await tester.tap(find.text('주전공').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(majorCategory.courses.first.name), findsOneWidget);
  });

  testWidgets('뒤로가기 버튼이 동작한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const GraduationCreditScreen(),
                  ),
                ),
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('총 이수학점'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(find.text('총 이수학점'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
