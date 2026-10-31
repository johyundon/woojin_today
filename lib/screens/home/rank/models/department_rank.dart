/// 순위 분포 한 줄(등수 + 평점).
class DepartmentRankEntry {
  const DepartmentRankEntry({required this.rank, required this.gpa});

  /// 1부터 시작하는 등수.
  final int rank;

  final double gpa;
}

/// 과목별 석차 한 줄("컴퓨터개론 A+ 3/84").
class SubjectRank {
  const SubjectRank({
    required this.name,
    required this.grade,
    required this.rank,
    required this.total,
  });

  final String name;

  /// 학점 등급("A+", "A0", "B+" ...).
  final String grade;

  /// 1부터 시작하는 그 과목에서의 내 석차.
  final int rank;

  /// 그 과목 석차 집계 인원.
  final int total;
}

/// "학과등수" 결과 화면에 필요한 데이터 전부.
///
/// 실제 화면은 T-WIN 평점으로 [buildDepartmentRank](rank_calculator.dart)가
/// 만든다. [shortName]·[semester]·[subjects]는 실제 데이터가 없어 비워 두고,
/// 목업([FakeDepartmentRankService])에서만 채운다.
class DepartmentRank {
  const DepartmentRank({
    required this.departmentName,
    this.shortName,
    this.semester,
    required this.grade,
    required this.myGpa,
    required this.departmentAverageGpa,
    required this.totalCount,
    required this.myRank,
    required this.distribution,
    this.subjects = const [],
  });

  final String departmentName;

  /// 줄임 이름(예: "컴공", 목업만).
  final String? shortName;

  /// 몇 학기인지(목업만).
  final int? semester;

  final int grade;

  final double myGpa;

  final double departmentAverageGpa;

  final int totalCount;

  /// 1부터 시작하는 내 등수.
  final int myRank;

  /// 1위부터 등수 오름차순으로 정렬된 전체 분포.
  final List<DepartmentRankEntry> distribution;

  /// 과목별 석차(목업만. 실제 API에는 과목별 성적이 없다).
  final List<SubjectRank> subjects;
}
