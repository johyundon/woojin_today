import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 시간표 화면들("우진이의 하루" v7)의 색상 팔레트.
///
/// 대부분 [AppColors]의 v7 값을 그대로 가리키고, v7 공통 팔레트에 없는
/// 값(그리드 줄·목록 구분선·손잡이·팝업 뒤 어두운 막 등)만 디자인 요소
/// 트리(v7spec 16~28)의 숫자를 그대로 옮겨 둔다.
class TimetableColors {
  TimetableColors._();

  static const Color background = AppColors.canvas;
  static const Color panelBackground = Colors.white;
  static const Color surface = AppColors.fill;
  static const Color surfaceElevated = AppColors.fillDisabled;
  static const Color border = AppColors.line;
  static const Color textPrimary = AppColors.textStrong;
  static const Color textSecondary = AppColors.textSub;
  static const Color accent = AppColors.blue;
  static const Color danger = Color(0xFFFF4D4F);

  /// 그리드 가로줄 rgb(232, 234, 238).
  static const Color gridLine = Color(0xFFE8EAEE);

  /// 과목 목록 줄 사이 구분선 rgb(234, 236, 239).
  static const Color rowLine = Color(0xFFEAECEF);

  /// 과목 상세 팝업 표 줄 구분선 rgb(238, 240, 242).
  static const Color detailRowLine = Color(0xFFEEF0F2);

  /// 아래 패널 손잡이 rgb(221, 224, 228).
  static const Color handle = Color(0xFFDDE0E4);

  /// 팝업 뒤 어두운 막 rgba(20, 22, 30, 0.55).
  static const Color barrier = Color(0x8C14161E);

  /// 아래 패널 그림자(검정 6%, 위로 4, 번짐 20).
  static const List<BoxShadow> sheetShadow = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, -4), blurRadius: 20),
  ];

  /// "자동 생성" 버튼 테두리·아이콘 그라데이션(파랑 → 보라 → 분홍).
  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A78E6), Color(0xFF7C5CF0), Color(0xFFD25FE0)],
    stops: [0, 0.55, 1],
  );

  /// "자동 생성"·"과목 추가" 버튼 글자 rgb(63, 69, 88).
  static const Color headerButtonText = Color(0xFF3F4558);
}

/// 강의 블록 색상 팔레트(과목마다 순환). v7 디자인 시간표 블록 색(oklch 값을
/// sRGB로 바꾼 값)과 각 색 위의 글자색.
const List<Color> timetableBlockPalette = [
  Color(0xFF5376EA), // oklch(0.6 0.18 268) 남보라
  Color(0xFFF2A359), // oklch(0.78 0.13 62) 주황
  Color(0xFF88D9A5), // oklch(0.82 0.11 155) 연두
  AppColors.blue,
  Color(0xFF7B57C8), // oklch(0.55 0.17 295) 보라
  Color(0xFF64D1D7), // oklch(0.8 0.1 200) 청록
];

final Map<Color, Color> _blockTextColors = {
  Color(0xFFF2A359): Color(0xFF2F3347),
  Color(0xFF88D9A5): Color(0xFF14452A),
  Color(0xFF64D1D7): Color(0xFF0F3F4A),
};

/// 같은 과목(courseCode-section)은 항상 같은 색을 쓰도록 키 해시로 팔레트
/// 인덱스를 고정한다.
Color colorForCourseKey(String key) {
  final index = key.hashCode.abs() % timetableBlockPalette.length;
  return timetableBlockPalette[index];
}

/// [timetableBlockPalette] 색상 위에 올릴 텍스트 색. 디자인이 밝은 블록에는
/// 그 색의 진한 글자색을, 나머지에는 흰색을 쓴다. 팔레트 밖 색이면 밝기로
/// 고른다.
Color textColorOnBlock(Color background) {
  final mapped = _blockTextColors[background];
  if (mapped != null) return mapped;
  if (timetableBlockPalette.contains(background)) return Colors.white;
  return background.computeLuminance() > 0.5
      ? AppColors.textStrong
      : Colors.white;
}

/// 강의계획서 화면(v7 디자인 26) 전용 색.
class SyllabusColors {
  SyllabusColors._();

  /// 펼친 절의 본문 글자 rgb(63, 68, 75).
  static const Color bodyText = Color(0xFF3F444B);
}

/// AI 자동 생성 설문·결과 화면(v7 디자인 17~22)에서만 쓰는 색.
class AiRecommendColors {
  AiRecommendColors._();

  /// 진행바의 아직 안 간 칸 rgb(209, 213, 219).
  static const Color progressTrack = Color(0xFFD1D5DB);

  /// 슬라이더 손잡이 그림자(파랑 28% 아래로 3 번짐 8 + 검정 16% 아래로 1 번짐 3).
  static const List<BoxShadow> thumbShadow = [
    BoxShadow(color: Color(0x470A78E6), offset: Offset(0, 3), blurRadius: 8),
    BoxShadow(color: Color(0x29000000), offset: Offset(0, 1), blurRadius: 3),
  ];

  /// "이 시간표 할래요" 버튼 그라데이션 rgb(43, 140, 240) → rgb(10, 120, 230).
  static const LinearGradient confirmGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2B8CF0), Color(0xFF0A78E6)],
  );
}
