import 'dart:async';
import 'dart:math';

import '../models/department_rank.dart';

/// 학과별 목업 설정값. [FakeDepartmentRankService._build]가 이 값으로
/// [DepartmentRank]를 만들어낸다.
class _DeptConfig {
  const _DeptConfig({
    required this.totalCount,
    required this.myRank,
    required this.mean,
    required this.sd,
    required this.shortName,
    this.myGpa,
  });

  final int totalCount;
  final int myRank;

  /// 학과 평점의 평균/표준편차 — 이 값으로 종 모양(정규분포) 분포를 만든다.
  final double mean;
  final double sd;

  /// 칩에 쓰는 줄임 이름.
  final String shortName;

  /// 분포에서 나온 값 대신 고정해서 쓸 내 평점(없으면 내 등수 자리의 값).
  final double? myGpa;
}

/// ⚠️ 목업 데이터, 실제 성적 API 아님.
///
/// "학과 전체 성적 분포"를 조회하는 포털/수강신청 API는 존재하지 않는다.
/// [FakeStudentInfoService](../../../services/fakes/fake_student_info_service.dart)
/// 처럼 가짜 응답을 돌려주는 서비스로, 학과별 등수/성적 분포를 전부 이 파일
/// 안에서 지어낸다. 같은 학과를 다시 조회하면 항상 같은 숫자가 나오도록 난수 없이
/// 계산만으로 만든다.
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
    // 시안("나 몇 등이야?")의 숫자: 84명 중 12등(상위 14%), 평점 4.12, 학과 평균
    // 3.41(평균보다 0.71 높음).
    '컴퓨터공학전공': _DeptConfig(
      totalCount: 84,
      myRank: 12,
      mean: 3.41,
      sd: 0.5,
      shortName: '컴공',
      myGpa: 4.12,
    ),
    '대순종학과': _DeptConfig(
      totalCount: 18,
      myRank: 3,
      mean: 3.5,
      sd: 0.45,
      shortName: '대순',
    ),
    '사학과': _DeptConfig(
      totalCount: 34,
      myRank: 15,
      mean: 3.3,
      sd: 0.5,
      shortName: '사학',
    ),
    '전기공학과': _DeptConfig(
      totalCount: 61,
      myRank: 22,
      mean: 3.35,
      sd: 0.5,
      shortName: '전기',
    ),
    'IT기계공학과': _DeptConfig(
      totalCount: 45,
      myRank: 11,
      mean: 3.4,
      sd: 0.5,
      shortName: 'IT기계',
    ),
    '화학공학과': _DeptConfig(
      totalCount: 39,
      myRank: 9,
      mean: 3.3,
      sd: 0.5,
      shortName: '화공',
    ),
    '데이터경영산업공학과': _DeptConfig(
      totalCount: 47,
      myRank: 5,
      mean: 3.45,
      sd: 0.5,
      shortName: '데경',
    ),
    '토목공학전공': _DeptConfig(
      totalCount: 29,
      myRank: 13,
      mean: 3.25,
      sd: 0.5,
      shortName: '토목',
    ),
    '건축공학과': _DeptConfig(
      totalCount: 36,
      myRank: 18,
      mean: 3.3,
      sd: 0.5,
      shortName: '건축공',
    ),
    '건축공학전공': _DeptConfig(
      totalCount: 31,
      myRank: 10,
      mean: 3.35,
      sd: 0.5,
      shortName: '건축',
    ),
    '영어영문학과': _DeptConfig(
      totalCount: 42,
      myRank: 20,
      mean: 3.3,
      sd: 0.5,
      shortName: '영문',
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
    // 등수마다 "상위 몇 %인 사람의 평점"을 정규분포의 역함수로 구해 채운다 — 그래야
    // 점수 분포 그래프가 가운데가 불룩한 종 모양이 된다. 1등부터 내림차순.
    final n = config.totalCount;
    final gpas = <double>[
      for (var i = 0; i < n; i++)
        double.parse(
          (config.mean + config.sd * _inverseNormalCdf(1 - (i + 0.5) / n))
              .clamp(1.0, 4.5)
              .toStringAsFixed(2),
        ),
    ];

    final myGpa = config.myGpa ?? gpas[config.myRank - 1];
    final average = gpas.reduce((a, b) => a + b) / gpas.length;

    return DepartmentRank(
      departmentName: departmentName,
      shortName: config.shortName,
      semester: 1,
      grade: 1,
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
        _subject('컴퓨터개론', 'A+', config.myRank * 0.25, n),
        _subject('이산수학', 'A0', config.myRank * 0.75, n),
        _subject('대학영어', 'B+', config.myRank * 2.6, n),
        _subject('자료구조', 'A0', config.myRank * 0.9, n),
        _subject('선형대수', 'B0', config.myRank * 3.1, n),
        _subject('운영체제', 'B+', config.myRank * 2.2, n),
      ],
    );
  }

  SubjectRank _subject(String name, String grade, double rank, int total) {
    return SubjectRank(
      name: name,
      grade: grade,
      rank: rank.round().clamp(1, total),
      total: total,
    );
  }

  /// 표준정규분포의 누적확률 [p](0~1)에 해당하는 값(z). Acklam 근사식.
  static double _inverseNormalCdf(double p) {
    const a = [
      -3.969683028665376e+01,
      2.209460984245205e+02,
      -2.759285104469687e+02,
      1.383577518672690e+02,
      -3.066479806614716e+01,
      2.506628277459239e+00,
    ];
    const b = [
      -5.447609879822406e+01,
      1.615858368580409e+02,
      -1.556989798598866e+02,
      6.680131188771972e+01,
      -1.328068155288572e+01,
    ];
    const c = [
      -7.784894002430293e-03,
      -3.223964580411365e-01,
      -2.400758277161838e+00,
      -2.549732539343734e+00,
      4.374664141464968e+00,
      2.938163982698783e+00,
    ];
    const d = [
      7.784695709041462e-03,
      3.224671290700398e-01,
      2.445134137142996e+00,
      3.754408661907416e+00,
    ];
    const low = 0.02425;

    if (p < low) {
      final q = sqrt(-2 * log(p));
      return (((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    if (p > 1 - low) {
      final q = sqrt(-2 * log(1 - p));
      return -(((((c[0] * q + c[1]) * q + c[2]) * q + c[3]) * q + c[4]) * q +
              c[5]) /
          ((((d[0] * q + d[1]) * q + d[2]) * q + d[3]) * q + 1);
    }
    final q = p - 0.5;
    final r = q * q;
    return (((((a[0] * r + a[1]) * r + a[2]) * r + a[3]) * r + a[4]) * r +
            a[5]) *
        q /
        (((((b[0] * r + b[1]) * r + b[2]) * r + b[3]) * r + b[4]) * r + 1);
  }
}
