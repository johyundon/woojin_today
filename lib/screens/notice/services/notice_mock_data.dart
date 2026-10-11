import '../../mileage/services/mileage_notice_mock_data.dart';
import '../models/notice_item.dart';

/// "공지사항" 화면 목데이터.
///
/// *** 중요: 서버 API 없음 ***
/// API 명세서(daejin-api-spec-reference)에 공지사항 목록/상세 조회에
/// 대응하는 엔드포인트가 없다. 그래서 이 화면은 전부 하드코딩된 목데이터로만
/// 동작한다 — 추측으로 서버 API를 만들어 호출하지 않는다. 나중에 실제
/// API가 생기면 [noticesFor] 안쪽만 교체하면 된다.
///
/// 마일리지 카테고리의 "대상자" 공지 3건은 새로 만들지 않고
/// [MileageNoticeMockData.notices](이미 마일리지 화면이 쓰는 값)를 그대로
/// 재사용한다 — 같은 공지를 두 군데서 다른 값으로 들고 있으면 안 되므로.
class NoticeMockData {
  NoticeMockData._();

  static List<NoticeItem> noticesFor(NoticeCategory category) {
    switch (category) {
      case NoticeCategory.academic:
        return _academic;
      case NoticeCategory.comprehensiveTimetable:
        return _comprehensiveTimetable;
      case NoticeCategory.mileage:
        return _mileage;
    }
  }

  // 스크린샷(Figma node 6:47)에서 그대로 읽은 제목/작성자/날짜/조회수.
  // 목록에서 "..."로 잘려 보인 2/3번째 제목은 맥락에 맞게 이어서 완성했다
  // (지어낸 부분, 실제 공지 원문 아님). 본문은 1번째("조기졸업") 공지만
  // 스크린샷(6:48)에 보였고 그마저도 아래쪽이 잘려있어, 보이는 부분까지만
  // 그대로 옮기고 "(이하 생략)"으로 표시했다. 2~5번째 공지는 본문 자체가
  // 스크린샷에 없어 제목에 맞춰 적당히 지어낸 안내문이다.
  static const _academic = [
    NoticeItem(
      title: '2026학년도 2학기 조기졸업 신청 안내',
      author: '최선미',
      date: '2026.09.03',
      viewCount: 82,
      isNew: true,
      body:
          '1. 관련 : 학칙 시행세칙 제96조(조기졸업) 및 제97조(조기졸업의 기준)\n\n'
          '2. 2026학년도 2학기 조기졸업 신청을 다음과 같이 알려드립니다.\n\n'
          ' 가. 조기졸업 요건(2012학번 이상)\n'
          '   1) 신청대상 : 4학년 1학기(7학기) 재학생\n'
          '   2) 조기졸업 요건 : 총 평점평균 4.2 이상\n'
          '   3) 조기졸업 신청 결격사항\n\n'
          '(이하 생략)',
    ),
    NoticeItem(
      title: '2026학년도 2학기 강사/비전임교원 신규임용자 및 임용예정자 공고',
      author: '김천수',
      date: '2026.08.26',
      viewCount: 297,
      body: '2026학년도 2학기 강사 및 비전임교원 신규임용자·임용예정자 명단을 붙임과 같이 공고합니다.',
    ),
    NoticeItem(
      title: '2026학년도 2학기 크로스리스팅(Cross-Listing) 교과목 안내',
      author: '정한별',
      date: '2026.08.18',
      viewCount: 427,
      body: '2026학년도 2학기 크로스리스팅(Cross-Listing) 운영 교과목을 붙임과 같이 안내드립니다.',
    ),
    NoticeItem(
      title: '2026학년도 2학기 복학 및 휴학 안내',
      author: '이영선',
      date: '2026.08.11',
      viewCount: 1978,
      body: '2026학년도 2학기 복학 및 휴학 신청 기간과 절차를 아래와 같이 안내드립니다.',
    ),
    NoticeItem(
      title: '2026-2학기 교양 강의시간표 변경사항 안내',
      author: '유경재',
      date: '2026.08.10',
      viewCount: 2625,
      body: '2026-2학기 교양 강의시간표 중 일부 변경된 사항을 아래와 같이 안내드립니다.',
    ),
  ];

  // 스크린샷(Figma node 6:50)에서 그대로 읽은 값. 1번째("2026학년도
  // 2학기") 공지만 본문/첨부파일이 스크린샷(6:52)에 보였고, 2~3번째는
  // 같은 패턴으로 적당히 지어냈다(지어낸 값, 실제 공지 아님).
  static const _comprehensiveTimetable = [
    NoticeItem(
      title: '2026학년도 2학기 종합강의시간표',
      author: '이경원',
      date: '2026.07.24',
      viewCount: 6912,
      body:
          '2026학년도 2학기 종합강의시간표\n\n'
          '[학사일정 변경 안내]\n\n'
          '왕방축제\n'
          '(변경 전) 2026. 9. 16. ~ 9.17. → (변경 후) 2026. 9. 14. ~ 9. 15.',
      attachmentFileName: '2026학년도 2학기 종합강의시간표_게시용.pdf',
    ),
    NoticeItem(
      title: '2026학년도 1학기 종합강의시간표',
      author: '조창묵',
      date: '2026.01.23',
      viewCount: 9321,
      body: '2026학년도 1학기 종합강의시간표를 붙임과 같이 안내드립니다.',
      attachmentFileName: '2026학년도 1학기 종합강의시간표_게시용.pdf',
    ),
    NoticeItem(
      title: '2025학년도 2학기 종합강의시간표',
      author: '이경원',
      date: '2025.07.31',
      viewCount: 13884,
      body: '2025학년도 2학기 종합강의시간표를 붙임과 같이 안내드립니다.',
      attachmentFileName: '2025학년도 2학기 종합강의시간표_게시용.pdf',
    ),
  ];

  // 스크린샷(Figma node 6:54)에서 그대로 읽은 값. "대상자" 공지 3건은
  // MileageNoticeMockData.notices(마일리지 화면이 이미 쓰는 값)를 그대로
  // 재사용하고, 버튼이 없는 "시행 안내" 공지 2건만 이 화면 전용으로 추가했다
  // (본문은 스크린샷에 없어 지어낸 값).
  static final _mileage = [
    NoticeItem(
      title: MileageNoticeMockData.notices[0].title,
      author: MileageNoticeMockData.notices[0].author,
      date: MileageNoticeMockData.notices[0].date,
      viewCount: MileageNoticeMockData.notices[0].viewCount,
      scholarshipNotice: MileageNoticeMockData.notices[0],
    ),
    const NoticeItem(
      title: '2026학년도 1학기 마일리지장학 시행 안내',
      author: '이용진',
      date: '2026.05.19',
      viewCount: 954,
      body: '2026학년도 1학기 마일리지장학 시행 계획을 아래와 같이 안내드립니다.',
    ),
    NoticeItem(
      title: MileageNoticeMockData.notices[1].title,
      author: MileageNoticeMockData.notices[1].author,
      date: MileageNoticeMockData.notices[1].date,
      viewCount: MileageNoticeMockData.notices[1].viewCount,
      scholarshipNotice: MileageNoticeMockData.notices[1],
    ),
    const NoticeItem(
      title: '2025학년도 2학기 마일리지장학 시행 안내',
      author: '이용진',
      date: '2025.10.10',
      viewCount: 2407,
      body: '2025학년도 2학기 마일리지장학 시행 계획을 아래와 같이 안내드립니다.',
    ),
    NoticeItem(
      title: MileageNoticeMockData.notices[2].title,
      author: MileageNoticeMockData.notices[2].author,
      date: MileageNoticeMockData.notices[2].date,
      viewCount: MileageNoticeMockData.notices[2].viewCount,
      scholarshipNotice: MileageNoticeMockData.notices[2],
    ),
  ];
}
