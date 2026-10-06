import 'package:flutter/material.dart';

import '../home/home_colors.dart' show accentOrange;

/// 시간표 짜기 화면(다크 전용)의 색상 팔레트.
///
/// Figma 노드가 전부 스크린샷으로 평탄화되어 있어 정확한 hex 값을 뽑을 수
/// 없었다(디자인 브리프 참고). 홈 화면의 accentOrange(`#FF7A29`)를 그대로
/// 포인트 컬러로 재사용하고, 나머지는 스크린샷을 눈으로 보고 근사한 값이다.
class TimetableColors {
  TimetableColors._();

  static const Color background = Color(0xFF0B0B0D);
  static const Color surface = Color(0xFF1C1C1F);
  static const Color surfaceElevated = Color(0xFF2A2A2E);
  static const Color border = Color(0xFF2C2C2F);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9A9A9E);
  static const Color accent = accentOrange;
  static const Color danger = Color(0xFFFF4D4F);
  static const Color gridLine = Color(0xFF232326);
}

/// 강의 블록 색상 팔레트(과목마다 순환). 스크린샷에서 보이는 민트/주황/
/// 핑크/파랑 계열 4색 + 보조 1색.
const List<Color> timetableBlockPalette = [
  Color(0xFF1FA98A), // 민트/틸
  Color(0xFFFF7A29), // 주황 (accentOrange)
  Color(0xFFE0558F), // 핑크/마젠타
  Color(0xFF3D6CFF), // 파랑/인디고
  Color(0xFF8B5CF6), // 보라
];

/// 같은 과목(courseCode-section)은 항상 같은 색을 쓰도록 키 해시로 팔레트
/// 인덱스를 고정한다.
Color colorForCourseKey(String key) {
  final index = key.hashCode.abs() % timetableBlockPalette.length;
  return timetableBlockPalette[index];
}
