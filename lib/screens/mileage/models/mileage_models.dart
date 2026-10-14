import 'package:flutter/widgets.dart';

/// 마일리지 적립 내역 한 건.
class MileageActivity {
  const MileageActivity({
    required this.title,
    required this.date,
    required this.points,
    required this.icon,
  });

  final String title;

  /// "10.08" 형태의 적립일.
  final String date;
  final int points;
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
