import 'package:daejin_app/screens/home/rank/models/rank_calculator.dart';
import 'package:daejin_app/services/twin_rank_service.dart';
import 'package:flutter_test/flutter_test.dart';

TwinGradeStats _stats(
  double my,
  List<double> peers, {
  double? avg,
  int total = 0,
}) => TwinGradeStats(
  myGpa: my,
  sameGradeAvg: avg,
  peerGpas: peers,
  totalCount: total,
  fetchedAt: DateTime(2026, 10, 31),
);

void main() {
  group('buildDepartmentRank', () {
    test('나보다 높은 사람 수 + 1이 등수, 분포는 높은 순', () {
      final r = buildDepartmentRank(
        _stats(3.9, [3.5, 4.2, 3.9, 4.0], avg: 3.8),
        departmentName: '컴퓨터공학전공',
        grade: 3,
      );
      expect(r.myRank, 3);
      expect(r.totalCount, 4);
      expect(r.departmentAverageGpa, 3.8);
      expect(r.distribution.map((e) => e.gpa), [4.2, 4.0, 3.9, 3.5]);
    });

    test('평점이 같으면 같은 등수다', () {
      final r = buildDepartmentRank(
        _stats(4.0, [4.5, 4.0, 4.0, 3.0]),
        departmentName: 'x',
        grade: 1,
      );
      expect(r.myRank, 2);
    });

    test('같은 학년 평균이 없으면 동기 평균을 쓴다', () {
      final r = buildDepartmentRank(
        _stats(4.0, [4.0, 3.0]),
        departmentName: 'x',
        grade: 1,
      );
      expect(r.departmentAverageGpa, 3.5);
    });

    test('동기 목록이 비면 내 평점만으로 1등, 인원은 서버 값', () {
      final r = buildDepartmentRank(
        _stats(3.0, [], total: 0),
        departmentName: 'x',
        grade: 1,
      );
      expect(r.myRank, 1);
      expect(r.totalCount, 1);
      expect(r.distribution.single.gpa, 3.0);
    });
  });

  group('estimateGrade', () {
    test('3월부터 새 학년으로 센다', () {
      expect(estimateGrade('20240001', DateTime(2026, 10, 31)), 3);
      expect(estimateGrade('20240001', DateTime(2026, 2, 28)), 2);
      expect(estimateGrade('20260001', DateTime(2026, 3, 2)), 1);
    });

    test('1~4학년으로 맞추고, 학번을 못 읽으면 3', () {
      expect(estimateGrade('20180001', DateTime(2026, 10, 31)), 4);
      expect(estimateGrade('20300001', DateTime(2026, 10, 31)), 1);
      expect(estimateGrade('abc', DateTime(2026, 10, 31)), 3);
    });
  });
}
