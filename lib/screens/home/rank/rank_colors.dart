import 'package:flutter/material.dart';

import '../home_colors.dart' show accentOrange;

/// "학과등수" 화면들의 라이트/다크 색상 세트.
///
/// Figma 노드(6:67/6:68/6:69)가 전부 다른 앱 스크린샷이 평탄화된 상태라
/// `get_design_context`로 쓸만한 코드를 뽑을 수 없었다(홈 화면
/// [HomeColors](../home_colors.dart), 캘린더/시간표 화면과 같은 선례). 다크
/// 팔레트는 스크린샷을 눈으로 보고 근사했고, 라이트 팔레트는 Figma 시안이
/// 없어 [RankColors]가 참고하는 홈 화면 팔레트 톤을 그대로 유추했다.
class RankColors {
  const RankColors(this.isDark);

  final bool isDark;

  Color get background =>
      isDark ? const Color(0xFF0B0B0D) : const Color(0xFFF2F2F2);

  Color get surface =>
      isDark ? const Color(0xFF1C1C1F) : const Color(0xFFFFFFFF);

  Color get surfaceElevated =>
      isDark ? const Color(0xFF2A2A2E) : const Color(0xFFECECF0);

  Color get border =>
      isDark ? const Color(0xFF2C2C2F) : const Color(0xFFE0E0E4);

  Color get textPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1C);

  Color get textSecondary =>
      isDark ? const Color(0xFF9A9A9E) : const Color(0xFF6B6B70);

  // 순위 막대그래프의 트랙(배경) 색.
  Color get barTrack =>
      isDark ? const Color(0xFF2A2A2E) : const Color(0xFFE4E4E8);

  // 순위 막대그래프 채움 색(내 등수가 아닌 줄).
  Color get barFill =>
      isDark ? const Color(0xFF3D6CFF) : const Color(0xFF3762E6);

  // 내 등수(동점 포함) 하이라이트 색 — 모드 무관 포인트 컬러.
  Color get highlight => accentOrange;
}
