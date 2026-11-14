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
