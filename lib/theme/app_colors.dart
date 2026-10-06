import 'package:flutter/material.dart';

/// Figma 노드(6:3, 6:4, 6:5)가 스크린샷으로 평탄화되어 있어 정확한 hex 값을
/// 추출할 수 없었다. 스크린샷을 눈으로 보고 근사한 다크 테마 + 오렌지 포인트
/// 컬러 팔레트.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF1C1C1F);
  static const Color border = Color(0xFF4A4A4E);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9A9E);
  static const Color accent = Color(0xFFFF7A29);
  static const Color disabledButton = Color(0xFF2A2A2D);
  static const Color disabledButtonText = Color(0xFF7A7A7E);
  static const Color error = Color(0xFFFF5C5C);
}
