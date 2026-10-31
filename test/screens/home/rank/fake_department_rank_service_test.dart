// 목업 학과등수 데이터(FakeDepartmentRankService)가 시안 숫자와 종 모양 분포를
// 만드는지 확인한다. 실제 화면은 T-WIN 데이터를 쓰고, 이 목업은 숨겨 둔 과목별
// 석차 카드 등을 다시 켤 때를 위해 남겨 두었다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/home/rank/services/fake_department_rank_service.dart';

void main() {
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
}
