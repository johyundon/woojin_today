import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 캠퍼스 지도 화면의 색상 팔레트. 졸업학점 화면과 같은 리디자인 톤
/// (흰 카드 + 코발트 포인트 + 잉크색 글자)을 쓴다. 지도 위에 떠 있는
/// 카드들이라 배경은 따로 없고, 카드 색(surface)만 흰색이다.
class CampusMapColors {
  CampusMapColors._();

  static const Color background = Color(0xFFEDEDF8);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFF0F0F8);
  static const Color border = Color(0xFFE3EBFF);
  static const Color textPrimary = AppColors.ink;
  static const Color textSecondary = Color(0xFF8E8E9A);
  static const Color accent = AppColors.cobalt;

  /// 검색바 초기화(X) 버튼.
  static const Color danger = Color(0xFFE5484D);
}
