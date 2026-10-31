import '../models/mileage_models.dart';

/// "장학 대상자 확인" 탭 목데이터.
///
/// 마일리지 화면의 장학 탭은 이제 학교 홈페이지의 실제 "대상자" 공지
/// (`MileageService.fetchTargetNotices`)를 쓴다. 이 목데이터는 공지 목데이터
/// (`notice_mock_data.dart`)가 아직 참조해서 남겨 두었다.
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
