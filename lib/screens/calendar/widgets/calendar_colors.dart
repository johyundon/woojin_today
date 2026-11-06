import 'package:flutter/material.dart';

/// 캘린더 화면들에서만 쓰는 v7 색(공통 [AppColors]에 없는 값). 디자인 값
/// (oklch/rgba)을 sRGB로 옮겼다.
abstract final class CalendarColors {
  /// 일·토 요일 글자(oklch 0.62 0.18 25).
  static const Color weekendRed = Color(0xFFDE4E4B);

  /// 삭제 글자·아이콘·버튼(oklch 0.6 0.22 25).
  static const Color deleteRed = Color(0xFFE62B34);

  /// 삭제 버튼·아이콘 원 바탕.
  static const Color deleteSoft = Color(0xFFFDECEC);

  /// 알림 꺼진 종 버튼의 테두리와 종 색.
  static const Color bellOffLine = Color(0xFFD5D9E0);
  static const Color bellOffIcon = Color(0xFF8A90A0);

  /// 바텀시트 위쪽 손잡이 막대.
  static const Color grabber = Color(0xFFDDE0E4);

  /// 시트·팝업 뒤를 덮는 어두운 막(rgba 20,22,30 / 0.55).
  static const Color barrier = Color(0x8C14161E);
}
