/// 순위 분포 한 줄(등수 + 평점).
class DepartmentRankEntry {
  const DepartmentRankEntry({required this.rank, required this.gpa});

  /// 1부터 시작하는 등수.
  final int rank;

  final double gpa;
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
}
