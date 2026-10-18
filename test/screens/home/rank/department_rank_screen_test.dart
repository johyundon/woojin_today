// 학과등수 화면이 시안("나 몇 등이야?")의 숫자와 구성을 보여주는지, 분포가 종
// 모양인지, 과목 "전체" 펼치기와 학과 변경 흐름이 동작하는지 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/home/rank/department_rank_screen.dart';
import 'package:daejin_app/screens/home/rank/services/fake_department_rank_service.dart';

Future<void> _pump(WidgetTester tester, {double w = 390}) async {
  tester.view.physicalSize = Size(w * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const MaterialApp(home: DepartmentRankScreen(isDark: true)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('컴공 기준 시안의 숫자와 구성이 그대로 나온다', (tester) async {
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('1학기 · 컴공 1학년'), findsOneWidget);
    expect(find.text('나 몇 등이야?'), findsOneWidget);
    expect(find.text('학과 84명 중'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('상위 14%'), findsOneWidget);
    expect(find.text('나'), findsOneWidget);
    expect(find.text('하위'), findsOneWidget);
    expect(find.text('학과 점수 분포'), findsOneWidget);
    expect(find.text('상위'), findsOneWidget);

    // 내 평점 4.12 / 4.5, 학과 평균보다 0.71, 장학.
    expect(find.text('내 평점'), findsOneWidget);
    expect(find.textContaining('4.12'), findsOneWidget);
    expect(find.text('학과 평균보다 0.71'), findsOneWidget);
    expect(find.text('성적우수 장학\n지원 가능'), findsOneWidget);
    expect(find.text('기준 상위 20%'), findsOneWidget);

    // 과목별 석차 3개(+ 전체 ›).
    for (final name in ['컴퓨터개론', '이산수학', '대학영어']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.textContaining('3/84'), findsOneWidget);
    expect(find.textContaining('9/84'), findsOneWidget);
    expect(find.textContaining('31/84'), findsOneWidget);
    expect(find.text('전체 ›'), findsOneWidget);
  });

  testWidgets('점수 분포는 가운데가 불룩한 종 모양이다', (tester) async {
    // 가짜 서비스가 실제 지연(Future.delayed)을 쓰므로 가짜 시계 밖에서 기다린다.
    final data = (await tester.runAsync(
      () => FakeDepartmentRankService().fetchDepartmentRank(
        departmentName: '컴퓨터공학전공',
      ),
    ))!;
    final gpas = data.distribution.map((e) => e.gpa).toList();
    final min = gpas.reduce((a, b) => a < b ? a : b);
    final max = gpas.reduce((a, b) => a > b ? a : b);

    // 20칸으로 묶으면 한가운데 근처가 가장 높고 양 끝은 낮다.
    final counts = List<int>.filled(20, 0);
    for (final g in gpas) {
      counts[((g - min) / (max - min) * 20).floor().clamp(0, 19)]++;
    }
    final peakIndex = counts.indexOf(counts.reduce((a, b) => a > b ? a : b));
    expect(peakIndex, inInclusiveRange(7, 13));
    expect(counts.first, lessThan(counts[peakIndex]));
    expect(counts.last, lessThan(counts[peakIndex]));

    expect(data.totalCount, 84);
    expect(data.myRank, 12);
    expect(data.myGpa, 4.12);
    expect(data.departmentAverageGpa, closeTo(3.41, 0.02));
    expect(data.subjects.length, greaterThan(3));
  });

  testWidgets('전체 ›를 누르면 과목이 모두 보이고 접기 ‹로 줄어든다', (tester) async {
    await _pump(tester);

    expect(find.text('자료구조'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('전체 ›'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('전체 ›'));
    await tester.pumpAndSettle();
    for (final name in ['자료구조', '선형대수', '운영체제']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('접기 ‹'), findsOneWidget);

    await tester.tap(find.text('접기 ‹'));
    await tester.pumpAndSettle();
    expect(find.text('자료구조'), findsNothing);
    expect(find.text('전체 ›'), findsOneWidget);
  });

  testWidgets('학과를 바꾸면 그 학과의 줄임 이름과 인원이 나온다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text('1학기 · 컴공 1학년'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전기공학과'));
    await tester.pump();
    await tester.tap(find.text('변경하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('변경'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('1학기 · 전기 1학년'), findsOneWidget);
    expect(find.text('학과 61명 중'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('작은 화면(360w)에서도 넘치지 않는다', (tester) async {
    await _pump(tester, w: 360);
    expect(tester.takeException(), isNull);
  });
}
