import 'package:flutter/material.dart';

import '../home/home_colors.dart' show accentOrange;

/// 캠퍼스 지도 화면(다크 전용)의 색상 팔레트. Figma 디자인이 전부 스크린샷으로
/// 평탄화되어 있어(디자인 브리프 참고) 정확한 hex 값을 뽑을 수 없었다 —
/// 시간표/학과등수 화면과 같은 다크 팔레트를 그대로 재사용한다.
class CampusMapColors {
  CampusMapColors._();

  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF1C1C1F);
  static const Color surfaceElevated = Color(0xFF2A2A2E);
  static const Color border = Color(0xFF2C2C2F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9A9E);
  static const Color accent = accentOrange;

  /// 검색바 초기화(X) 버튼 — Figma(6:100)에서 빨강/코랄로 보여 시간표
  /// 화면의 danger 색(timetable_colors.dart)과 맞췄다.
  static const Color danger = Color(0xFFFF4D4F);
}
