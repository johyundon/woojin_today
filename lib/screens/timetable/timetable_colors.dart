import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 시간표 짜기 화면("우진이의 하루" v4 리디자인)의 색상 팔레트.
///
/// 상단(배지·제목·버튼)은 [AppColors.cobalt] 배경 위에 직접 그리므로 이
/// 토큰을 쓰지 않는다. 여기 토큰들은 그 아래 흰색 둥근 패널(그리드·검색·
/// 결과 리스트)에서 쓰는 값이다 — 기존 다크 테마와 반대로 밝은 배경
/// 기준이라 textPrimary/textSecondary도 그에 맞춰 바뀌었다.
class TimetableColors {
  TimetableColors._();

  static const Color background = AppColors.cobalt;
  static const Color panelBackground = Colors.white;
  static const Color surface = Color(0xFFF5F3EF);
  static const Color surfaceElevated = Color(0xFFECE9E2);
  static const Color border = Color(0xFFE4E1DA);
  static const Color textPrimary = AppColors.ink;
  static const Color textSecondary = Color(0xFF9A978F);
  static const Color accent = AppColors.cobalt;
  static const Color danger = Color(0xFFFF4D4F);
  static const Color gridLine = Color(0xFFECEBF3);
}

/// 강의 블록 색상 팔레트(과목마다 순환). standalone.html "05 시간표" 시안의
/// 블록 5색(코발트·코랄·라임·잉크·연코발트)을 그대로 쓴다.
const List<Color> timetableBlockPalette = [
  AppColors.cobalt,
  AppColors.blushPink,
  AppColors.lime,
  AppColors.ink,
  Color(0xFF5B7FE0), // 연코발트. AppColors에 없는 중간톤이라 별도 정의.
];

/// 같은 과목(courseCode-section)은 항상 같은 색을 쓰도록 키 해시로 팔레트
/// 인덱스를 고정한다.
Color colorForCourseKey(String key) {
  final index = key.hashCode.abs() % timetableBlockPalette.length;
  return timetableBlockPalette[index];
}

/// [timetableBlockPalette] 색상 위에 올릴 텍스트 색. 라임·코랄처럼 밝은
/// 배경에는 어두운 잉크색을, 코발트·잉크처럼 어두운 배경에는 흰색을 써야
/// 읽힌다 — 밝기(luminance) 기준으로 자동 판단한다.
Color textColorOnBlock(Color background) {
  return background.computeLuminance() > 0.5 ? AppColors.ink : Colors.white;
}
