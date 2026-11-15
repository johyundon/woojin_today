import 'package:flutter/widgets.dart';

/// 마일리지 적립 내역(비교과 이수) 한 건.
class MileageActivity {
  const MileageActivity({
    required this.title,
    required this.date,
    required this.points,
    required this.icon,
  });

  final String title;

  /// 날짜와 부가 정보 한 줄(예: "2026.05.01 · 교수학습지원센터").
  final String date;

  /// 화면에 보일 점수 글자(예: "50", "7.5").
  final String points;
  final IconData icon;
}

/// 장학 대상자 공지 한 건.
class MileageNotice {
  const MileageNotice({
    required this.title,
    required this.author,
    required this.date,
    required this.viewCount,
  });

  final String title;
  final String author;
  final String date;
  final int viewCount;
}

/// [now]가 속한 학기와 그 기간([start] 포함 ~ [end] 미포함).
///
/// 앱의 다른 화면(홈·시간표)과 같은 학기 추정 규칙을 쓴다: 2~7월은 1학기
/// (2월 1일 ~ 7월 31일), 8월~다음 해 1월은 2학기(8월 1일 ~ 1월 31일).
/// *** 추정 *** 학교의 실제 학기 기간이 아니라 달력 기준이라, 방학 중 비교과도
/// 앞뒤 학기에 들어간다.
({int year, int semester, DateTime start, DateTime end}) semesterRangeOf(
  DateTime now,
) {
  if (now.month >= 2 && now.month <= 7) {
    return (
      year: now.year,
      semester: 1,
      start: DateTime(now.year, 2),
      end: DateTime(now.year, 8),
    );
  }
  final year = now.month >= 8 ? now.year : now.year - 1;
  return (
    year: year,
    semester: 2,
    start: DateTime(year, 8),
    end: DateTime(year + 1, 2),
  );
}
