// 학과 성적 분포 목록: 평점을 높은 순으로 전부 나열하고 내 평점 줄을 표시한다.

import 'package:daejin_app/screens/home/rank/models/department_rank.dart';
import 'package:daejin_app/screens/home/rank/widgets/gpa_ranking_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DepartmentRank _data(double myGpa, List<double> gpas) => DepartmentRank(
  departmentName: '컴퓨터공학전공',
  grade: 3,
  myGpa: myGpa,
  departmentAverageGpa: 3.0,
  totalCount: gpas.length,
  myRank: gpas.where((g) => g > myGpa).length + 1,
  distribution: [
    for (var i = 0; i < gpas.length; i++)
      DepartmentRankEntry(rank: i + 1, gpa: gpas[i]),
  ],
);

void main() {
  test('평점 높은 순으로 1위부터 차례로 붙이고 내 평점 줄을 표시한다', () {
    final rows = gpaRankingRows(_data(3.8, [3.1, 4.2, 3.8]));
    expect([for (final r in rows) r.rank], [1, 2, 3]);
    expect([for (final r in rows) r.gpa], [4.2, 3.8, 3.1]);
    expect([for (final r in rows) r.isMe], [false, true, false]);
  });

  test('평점이 같은 사람이 있어도 나는 첫 줄 하나만 표시한다', () {
    final rows = gpaRankingRows(_data(4.34, [4.34, 4.34, 4.22]));
    expect([for (final r in rows) r.isMe], [true, false, false]);
  });

  test('목록에 내 평점이 없으면 내 자리에 끼워 넣는다', () {
    final rows = gpaRankingRows(_data(3.5, [4.2, 3.8, 3.1]));
    expect([for (final r in rows) r.gpa], [4.2, 3.8, 3.5, 3.1]);
    expect(rows[2].isMe, isTrue);
  });

  testWidgets('제목과 순위·평점이 보인다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GpaRankingListCard(data: _data(3.8, [4.2, 3.8, 3.1])),
          ),
        ),
      ),
    );
    expect(find.text('컴퓨터공학전공(3학년) 성적 분포'), findsOneWidget);
    expect(find.text('1위'), findsOneWidget);
    expect(find.text('4.20'), findsOneWidget);
    expect(find.text('3.80'), findsOneWidget);
  });
}
