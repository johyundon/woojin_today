import 'dart:async';
import 'dart:math';

import '../models/department_rank.dart';

/// 학과별 목업 설정값. [FakeDepartmentRankService._build]가 이 값으로
/// [DepartmentRank]를 만들어낸다.
class _DeptConfig {
  const _DeptConfig({
    required this.totalCount,
    required this.myRank,
    required this.topGpa,
    required this.bottomGpa,
    required this.seed,
  });

  final int totalCount;
  final int myRank;
  final double topGpa;
  final double bottomGpa;
  final int seed;
}

/// ⚠️ 목업 데이터, 실제 성적 API 아님.
///
/// "학과 전체 성적 분포"를 조회하는 포털/수강신청 API는 존재하지 않는다.
/// [FakeStudentInfoService](../../../services/fakes/fake_student_info_service.dart)
/// 처럼 가짜 응답을 돌려주는 서비스로, 학과별 등수/성적 분포를 전부 이 파일
/// 안에서 지어낸다. 같은 학과를 다시 조회하면 항상 같은 숫자가 나오도록
/// 고정 시드(seed)로 생성한다.
class FakeDepartmentRankService {
  /// 학과 변경 화면에서 고를 수 있는 학과 목록.
  static const List<String> departmentNames = [
    '컴퓨터공학전공',
    '대순종학과',
    '사학과',
    '전기공학과',
    'IT기계공학과',
    '화학공학과',
    '데이터경영산업공학과',
    '토목공학전공',
    '건축공학과',
    '건축공학전공',
    '영어영문학과',
  ];

  /// 학과 변경 화면에서 학과 이름 아래에 보여줄 단과대학(목업).
  static const Map<String, String> departmentColleges = {
    '컴퓨터공학전공': '공과대학',
    '대순종학과': '인문대학',
    '사학과': '인문대학',
    '전기공학과': '공과대학',
    'IT기계공학과': '공과대학',
    '화학공학과': '공과대학',
    '데이터경영산업공학과': '공과대학',
    '토목공학전공': '공과대학',
    '건축공학과': '공과대학',
    '건축공학전공': '공과대학',
    '영어영문학과': '인문대학',
  };

  static const Map<String, _DeptConfig> _configs = {
    '컴퓨터공학전공': _DeptConfig(
      totalCount: 52,
      myRank: 7,
      topGpa: 4.5,
      bottomGpa: 1.8,
      seed: 1,
    ),
    '대순종학과': _DeptConfig(
      totalCount: 18,
      myRank: 3,
      topGpa: 4.4,
      bottomGpa: 2.2,
      seed: 2,
    ),
    '사학과': _DeptConfig(
      totalCount: 34,
      myRank: 15,
      topGpa: 4.3,
      bottomGpa: 1.9,
      seed: 3,
    ),
    '전기공학과': _DeptConfig(
      totalCount: 61,
      myRank: 22,
      topGpa: 4.5,
      bottomGpa: 1.7,
      seed: 4,
    ),
    'IT기계공학과': _DeptConfig(
      totalCount: 45,
      myRank: 11,
      topGpa: 4.4,
      bottomGpa: 1.8,
      seed: 5,
    ),
    '화학공학과': _DeptConfig(
      totalCount: 39,
      myRank: 9,
      topGpa: 4.3,
      bottomGpa: 2.0,
      seed: 6,
    ),
    '데이터경영산업공학과': _DeptConfig(
      totalCount: 47,
      myRank: 5,
      topGpa: 4.5,
      bottomGpa: 1.9,
      seed: 7,
    ),
    '토목공학전공': _DeptConfig(
      totalCount: 29,
      myRank: 13,
      topGpa: 4.2,
      bottomGpa: 2.1,
      seed: 8,
    ),
    '건축공학과': _DeptConfig(
      totalCount: 36,
      myRank: 18,
      topGpa: 4.3,
      bottomGpa: 1.8,
      seed: 9,
    ),
    '건축공학전공': _DeptConfig(
      totalCount: 31,
      myRank: 10,
      topGpa: 4.4,
      bottomGpa: 2.0,
      seed: 10,
    ),
    '영어영문학과': _DeptConfig(
      totalCount: 42,
      myRank: 20,
      topGpa: 4.3,
      bottomGpa: 1.9,
      seed: 11,
    ),
  };

  /// [departmentName]은 반드시 [departmentNames]에 있는 값이어야 한다(학과
  /// 변경 화면이 그 목록만 보여주므로 다른 값이 들어올 일은 없다).
  Future<DepartmentRank> fetchDepartmentRank({
    required String departmentName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _build(departmentName, _configs[departmentName]!);
  }

  DepartmentRank _build(String departmentName, _DeptConfig config) {
    final random = Random(config.seed);
    final gpas = <double>[];
    var current = config.topGpa;

    for (var i = 0; i < config.totalCount; i++) {
      // 바로 앞 등수와 같은 평점(동점)이 간간이 나오도록 18% 확률로 내리지
      // 않고 유지한다.
      if (i > 0 && random.nextDouble() < 0.18) {
        gpas.add(gpas.last);
        continue;
      }
      final remaining = config.totalCount - i;
      final span = current - config.bottomGpa;
      final step = span / remaining * (0.6 + random.nextDouble() * 0.8);
      current = (current - step).clamp(config.bottomGpa, config.topGpa);
      gpas.add(double.parse(current.toStringAsFixed(2)));
    }

    final myGpa = gpas[config.myRank - 1];
    final average = gpas.reduce((a, b) => a + b) / gpas.length;

    return DepartmentRank(
      departmentName: departmentName,
      grade: 3,
      myGpa: myGpa,
      departmentAverageGpa: double.parse(average.toStringAsFixed(2)),
      totalCount: config.totalCount,
      myRank: config.myRank,
      distribution: [
        for (var i = 0; i < gpas.length; i++)
          DepartmentRankEntry(rank: i + 1, gpa: gpas[i]),
      ],
      subjects: [
        // 내 등수에 비례해 과목별 석차를 지어낸다(등급 순서대로 좋은 석차부터).
        SubjectRank(
          name: '컴퓨터개론',
          grade: 'A+',
          rank: max(1, (config.myRank * 0.25).round()),
          total: config.totalCount,
        ),
        SubjectRank(
          name: '이산수학',
          grade: 'A0',
          rank: max(1, (config.myRank * 0.75).round()),
          total: config.totalCount,
        ),
        SubjectRank(
          name: '대학영어',
          grade: 'B+',
          rank: min(config.totalCount, (config.myRank * 2.6).round()),
          total: config.totalCount,
        ),
      ],
    );
  }
}
