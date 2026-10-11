import '../models/mileage_models.dart';

/// "장학 대상자 확인" 탭 목데이터.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 장학 대상자 공지 조회에
/// 대응하는 엔드포인트가 없다. 그래서 이 기능은 전부 하드코딩된 목데이터로만
/// 동작한다 — 추측으로 서버 API를 만들어 호출하지 않는다. 나중에 실제 API가
/// 생기면 이 파일만 교체하면 된다.
class MileageNoticeMockData {
  MileageNoticeMockData._();

  // 스크린샷(Figma node 6:108)에서 그대로 읽은 공지 3건.
  static const List<MileageNotice> notices = [
    MileageNotice(
      title: '2026학년도 1학기 마일리지장학 대상자 공지',
      author: '이용진',
      date: '2026.08.05',
      viewCount: 1934,
    ),
    MileageNotice(
      title: '2025학년도 2학기 마일리지장학 대상자 공지',
      author: '이용진',
      date: '2026.02.05',
      viewCount: 4454,
    ),
    MileageNotice(
      title: '2025학년도 1학기 마일리지장학 대상자 공지',
      author: '이용진',
      date: '2025.07.28',
      viewCount: 4939,
    ),
  ];
}
