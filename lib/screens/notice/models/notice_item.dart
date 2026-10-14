import '../../mileage/models/mileage_models.dart';

/// "공지사항" 화면의 분류 칩(전체 제외 4개).
enum NoticeTag {
  academic('학사'),
  scholarship('장학'),
  department('학과'),
  event('행사');

  const NoticeTag(this.label);

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
    required this.tag,
    this.isNew = false,
    this.isRequired = false,
    this.body,
    this.attachmentFileName,
    this.scholarshipNotice,
  });

  final String title;
  final String author;
  final String date;
  final int viewCount;
  final NoticeTag tag;

  /// 공지를 구분하는 키(읽음/북마크 저장에 쓴다). 날짜+제목.
  String get key => '$date-$title';

  /// 새로 올라온 공지(안 읽었으면 빨간 점으로 표시).
  final bool isNew;

  /// "필독" 공지(검은 칩으로 표시).
  final bool isRequired;

  /// 상세 화면 본문. [scholarshipNotice]가 있으면 안 쓰인다.
  final String? body;

  /// 상세 화면의 "첨부파일" 섹션에 보여줄 파일명. null이면 첨부파일 섹션을
  /// 아예 그리지 않는다.
  final String? attachmentFileName;

  /// null이 아니면 마일리지 "대상자" 공지 — 탭했을 때 상세 화면이 아니라
  /// 기존 마일리지 화면의 대상자 확인 다이얼로그로 이어진다.
  final MileageNotice? scholarshipNotice;
}
