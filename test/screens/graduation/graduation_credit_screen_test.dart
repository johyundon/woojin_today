// GraduationCreditScreen이 목데이터 합계/영역별 진행률을 오버플로우 없이
// 보여주는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/graduation/graduation_credit_screen.dart';
import 'package:daejin_app/screens/graduation/services/graduation_credit_mock_data.dart';

void main() {
  testWidgets('전체 합계와 영역별 이수 현황을 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GraduationCreditScreen()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('지금까지 이수한 학점'), findsOneWidget);
    expect(
      find.text('${GraduationCreditMockData.totalEarned}'),
      findsOneWidget,
    );
    expect(
      find.text(' / ${GraduationCreditMockData.totalRequired}학점'),
      findsOneWidget,
    );

    for (final category in GraduationCreditMockData.categories) {
      expect(find.text(category.label), findsOneWidget);
      expect(
        find.text('${category.earned} / ${category.required}학점'),
        findsOneWidget,
      );
    }
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
    expect(find.text('지금까지 이수한 학점'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('지금까지 이수한 학점'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
