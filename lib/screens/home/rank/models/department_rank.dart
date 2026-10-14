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
/// 실제 성적 API가 없어 전부 목업이다([FakeDepartmentRankService] 참고).
class DepartmentRank {
  const DepartmentRank({
    required this.departmentName,
    required this.grade,
    required this.myGpa,
    required this.departmentAverageGpa,
    required this.totalCount,
    required this.myRank,
    required this.distribution,
    required this.subjects,
  });

  final String departmentName;

  final int grade;

  final double myGpa;

  final double departmentAverageGpa;

  final int totalCount;

  /// 1부터 시작하는 내 등수.
  final int myRank;

  /// 1위부터 등수 오름차순으로 정렬된 전체 분포.
  final List<DepartmentRankEntry> distribution;

  /// 과목별 석차(목업).
  final List<SubjectRank> subjects;
}
