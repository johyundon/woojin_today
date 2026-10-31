import '../twin_rank_service.dart';

/// ⚠️ 목업 데이터. 학교 서버에 요청하지 않고 고정된 숫자를 돌려준다.
/// 학과 등수는 항상 실제 서버를 쓰므로 지금은 팩토리에서 쓰지 않는다.
class FakeTwinRankService implements TwinRankServiceBase {
  @override
  Future<TwinGradeStats> fetchGradeStats({
    required String userId,
    required String userPwd,
    required String sustCd,
    required String shyrCd,
    bool forceRefresh = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // 84명, 4.50부터 0.03씩 내려가는 평점.
    final peers = [for (var i = 0; i < 84; i++) 4.5 - i * 0.03];
    return TwinGradeStats(
      myGpa: 4.12,
      sameGradeAvg: 3.41,
      peerGpas: peers,
      totalCount: peers.length,
      fetchedAt: DateTime.now(),
    );
  }
}
