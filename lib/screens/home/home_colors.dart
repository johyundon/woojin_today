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

/// 홈 화면(v7) 카드에만 쓰는 색. 공통 팔레트(AppColors)에 없는 값만 모았고,
/// 디자인 요소 트리(12_home_class / 13_home_free)의 값을 그대로 옮겼다.
class HomeV7Colors {
  HomeV7Colors._();

  /// 날짜 배지 바탕.
  static const Color dateBadge = Color(0xFFEBEDF0);

  /// 새 알림 점(빨강).
  static const Color alertDot = Color(0xFFEE343B);

  /// "다음 수업" 카드 테두리.
  static const Color nextCardBorder = Color(0xFFDCE3EE);

  /// "N분 남음" 배지 바탕.
  static const Color remainBadge = Color(0xFFCFE4FB);

  /// 파란 칸 위의 종료 시각 / 과목명 글자.
  static const Color onBlueSub = Color(0xFFE6F0FF);
  static const Color onBlueTitle = Color(0xFFEAF3FF);

  /// 강의실·내일 첫 수업 같은 카드 속 진한 글자와, 그 아래 옅은 글자.
  static const Color cardTitle = Color(0xFF3F4558);
  static const Color cardSub = Color(0xFF6B7183);

  /// "길찾기" 버튼 그라데이션 시작색.
  static const Color directionsStart = Color(0xFF2B8CF0);

  /// "길찾기" 버튼 그림자.
  static const Color directionsShadow = Color(0x1F2F86EC);

  /// "오늘 수업" 라벨, 학식 식당 이름.
  static const Color label = Color(0xFF5A6070);

  /// "오늘은 수업 없음!" 제목.
  static const Color emptyHeadline = Color(0xFF2C3144);

  /// 공강 카드의 점선 구분선.
  static const Color dashLine = Color(0xFFD1D5DB);

  /// 학식 메뉴 제목.
  static const Color lunchTitle = Color(0xFF2F3345);

  /// 남색 카드 위의 옅은 글자.
  static const Color onNavySub = Color(0xFFE3E6EE);
}
