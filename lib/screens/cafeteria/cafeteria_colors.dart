import 'package:flutter/material.dart';

import '../home/home_colors.dart' show accentOrange;

/// "오늘의 학식" 화면(다크 전용)의 색상 팔레트.
///
/// Figma 노드(6:70 "학식")가 실제 벡터 레이어가 아니라 앱 스크린샷 4장(6:71~
/// 6:74)이 평탄화된 상태라 `get_design_context`로 정확한 hex 값을 뽑을 수
/// 없었다(calendar_screen.dart, timetable_colors.dart와 같은 상황). 홈 화면
/// 팔레트([HomeColors] 다크)와 accentOrange(`#FF7A29`)를 그대로 재사용하고,
/// 나머지는 스크린샷을 눈으로 보고 근사한 값이다.
class CafeteriaColors {
  CafeteriaColors._();

  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF1C1C1F);

  /// 메뉴 카드 하나하나처럼, surface보다 한 단계 밝혀서 구분해야 할 때 쓴다.
  static const Color surfaceElevated = Color(0xFF2A2A2E);
  static const Color border = Color(0xFF2C2C2F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9A9E);
  static const Color accent = accentOrange;
}
