import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 캠퍼스 지도 화면의 색상 팔레트. 홈 화면과 같은 리디자인 톤(흰 카드 +
/// 남색 그림자 + 코발트/라임 포인트 + 잉크색 글자)을 쓴다. 지도 위에 떠 있는
/// 카드들이라 배경은 따로 없고, 카드 색(surface)만 흰색이다.
class CampusMapColors {
  CampusMapColors._();

  static const Color background = Color(0xFFEDEDF8);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFF0F0F8);
  static const Color border = Color(0xFFE3EBFF);
  static const Color textPrimary = AppColors.ink;
  static const Color textSecondary = Color(0x99121212);
  static const Color accent = AppColors.cobalt;
  static const Color highlight = AppColors.lime;

  /// 홈 화면 카드(next_class_card.dart 등)와 같은 남색 그림자.
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF030A7F).withValues(alpha: 0.22),
      offset: const Offset(0, 10),
      blurRadius: 24,
    ),
  ];

  /// 검색바 초기화(X) 버튼.
  static const Color danger = Color(0xFFE5484D);
}
