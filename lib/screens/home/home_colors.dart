import 'package:flutter/material.dart';

/// 홈 화면 전용 라이트/다크 색상 세트.
/// Figma 노드(6:14 다크, 6:20 라이트)가 스크린샷으로 평탄화되어 있어 정확한 hex 값을
/// 추출할 수 없었다. 두 스크린샷을 눈으로 비교해 근사한 팔레트.
class HomeColors {
  const HomeColors(this.isDark);

  final bool isDark;

  Color get background =>
      isDark ? const Color(0xFF0B0B0D) : const Color(0xFFF2F2F2);

  Color get cardSurface =>
      isDark ? const Color(0xFF1C1C1F) : const Color(0xFFFFFFFF);

  Color get textPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1C);

  Color get textSecondary =>
      isDark ? const Color(0xFF9A9A9E) : const Color(0xFF6B6B70);

  Color get avatarBackground =>
      isDark ? const Color(0xFF1C1C1F) : const Color(0xFFFFFFFF);

  // 다크 모드일 때(스위치 썸이 왼쪽) 트랙 색.
  Color get switchTrackDark => const Color(0xFF2A2A2D);

  // 라이트 모드일 때(스위치 썸이 오른쪽) 트랙 색.
  Color get switchTrackLight => const Color(0xFFE4E4E8);

  Color get adBackground =>
      isDark ? const Color(0xFF1C1C1F) : const Color(0xFFE7E7EA);
}

// 카드 브랜드 컬러(다크 모드). 아바타 메뉴 "로그아웃" 등 모드 무관 포인트 컬러로도 쓰인다.
const Color accentOrange = Color(0xFFFF7A29);
