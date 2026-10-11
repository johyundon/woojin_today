import '../../mileage/models/mileage_models.dart';

/// "공지사항" 화면의 카테고리 탭 3개(Figma node 6:47/6:50/6:54).
enum NoticeCategory {
  academic('학사공지'),
  comprehensiveTimetable('종합강의시간표'),
  mileage('마일리지');

  const NoticeCategory(this.label);

  final String label;
}

/// 공지 한 건.
///
/// [scholarshipNotice]가 null이 아니면(마일리지 카테고리의 "대상자" 공지)
/// 카드를 눌렀을 때 상세 화면 대신 기존 마일리지 화면의
/// `showMileageTargetConfirmDialog` 다이얼로그로 이어진다 — 그래서 이
/// 경우엔 [body]가 없어도 된다.
class NoticeItem {
  const NoticeItem({
    required this.title,
    required this.author,
    required this.date,
    required this.viewCount,
    this.isNew = false,
    this.body,
    this.attachmentFileName,
    this.scholarshipNotice,
  });

  final String title;
  final String author;
  final String date;
  final int viewCount;
  final bool isNew;

  /// 상세 화면 본문. [scholarshipNotice]가 있으면 안 쓰인다.
  final String? body;

  /// 상세 화면의 "첨부파일" 섹션에 보여줄 파일명. null이면 첨부파일 섹션을
  /// 아예 그리지 않는다.
  final String? attachmentFileName;

  /// null이 아니면 마일리지 "대상자" 공지 — 탭했을 때 상세 화면이 아니라
  /// 기존 마일리지 화면의 대상자 확인 다이얼로그로 이어진다.
  final MileageNotice? scholarshipNotice;
}
