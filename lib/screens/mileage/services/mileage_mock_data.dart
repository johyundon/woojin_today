import '../models/mileage_models.dart';

/// "마일리지 현황" 탭 목데이터.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 마일리지 조회에 대응하는
/// 엔드포인트가 없다. 그래서 이 기능은 전부 하드코딩된 목데이터로만 동작한다
/// — 추측으로 서버 API를 만들어 호출하지 않는다. 나중에 실제 API가 생기면
/// 이 파일만 교체하면 된다.
class MileageMockData {
  MileageMockData._();

  // 스크린샷(Figma node 6:106)에서 그대로 읽은 값.
  static const int myRank = 46;
  static const int myScore = 0;

  // 1위 점수(80) 대비 비율로 바 길이를 계산한다. 스크린샷에서 그대로 읽은 값.
  static const List<MileageRankEntry> top5 = [
    MileageRankEntry(rank: 1, score: 80),
    MileageRankEntry(rank: 2, score: 72),
    MileageRankEntry(rank: 3, score: 64),
    MileageRankEntry(rank: 4, score: 32),
    MileageRankEntry(rank: 5, score: 26),
  ];
}
