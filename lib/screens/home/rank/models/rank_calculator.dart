import '../../../../services/twin_rank_service.dart';
import 'department_rank.dart';

/// T-WIN에서 받은 평점들로 등수를 계산한다. 서버는 등수를 직접 주지 않는다.
///
/// - 등수 = 나보다 평점이 높은 사람 수 + 1. 평점이 같으면 같은 등수다.
/// - 인원은 받아온 동기 평점 개수(없으면 서버의 totalCnt).
/// - 학과 평균은 서버가 준 같은 학년 평균, 없으면 동기 평점 평균.
///
/// 동기 목록에 내 평점이 들어 있는지는 확인하지 못했다. 들어 있지 않다면 인원이
/// 실제보다 1 적게 나온다.
DepartmentRank buildDepartmentRank(
  TwinGradeStats stats, {
  required String departmentName,
  required int grade,
}) {
  final peers = [...stats.peerGpas]..sort((a, b) => b.compareTo(a));
  // 분포 그래프는 값이 하나 이상 있어야 그릴 수 있다.
  final gpas = peers.isEmpty ? [stats.myGpa] : peers;
  final myRank = peers.where((g) => g > stats.myGpa).length + 1;
  final total = peers.isEmpty ? stats.totalCount : peers.length;

  return DepartmentRank(
    departmentName: departmentName,
    grade: grade,
    myGpa: stats.myGpa,
    departmentAverageGpa:
        stats.sameGradeAvg ?? gpas.reduce((a, b) => a + b) / gpas.length,
    totalCount: total < myRank ? myRank : total,
    myRank: myRank,
    distribution: [
      for (var i = 0; i < gpas.length; i++)
        DepartmentRankEntry(rank: i + 1, gpa: gpas[i]),
    ],
  );
}

/// 학번 앞 4자리(입학년도)로 학년을 추정한다. 3월부터 새 학년으로 보고 1~4로
/// 맞춘다. 휴학·편입생은 틀릴 수 있어 화면에서 바꿀 수 있게 한다. 학번을 읽지
/// 못하면 명세의 대체값 3을 쓴다.
int estimateGrade(String studentId, DateTime now) {
  final entryYear = studentId.length >= 4
      ? int.tryParse(studentId.substring(0, 4))
      : null;
  if (entryYear == null) return 3;
  final schoolYear = now.month >= 3 ? now.year : now.year - 1;
  return (schoolYear - entryYear + 1).clamp(1, 4);
}
