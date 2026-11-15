import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'models/cafeteria_menu.dart';

/// 학식 화면(디자인 "07 학식")에서만 쓰는 색. 공통 색은 [AppColors]에 있고,
/// 여기에는 거기에 없는 값만 디자인에서 그대로 옮겨 둔다.
class CafeteriaColors {
  CafeteriaColors._();

  /// 메뉴 카드 테두리·끼니 구역 사이 선 rgb(232, 234, 238).
  static const Color cardBorder = Color(0xFFE8EAEE);

  /// 선택 안 된 식당 탭 글자, 끼니 제목(조식/중식/석식) rgb(63, 69, 88).
  static const Color tabText = Color(0xFF3F4558);

  /// 회색 글자(gray/700) — 요일, 메뉴 구성, 가격.
  static const Color gray700 = Color(0xFF7E7F87);

  /// 맨 위 "학식" 제목(gray/1000).
  static const Color title = Color(0xFF191A1A);

  /// 날짜 칩·메뉴 카드의 옅은 그림자.
  static const List<BoxShadow> chipShadow = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 4),
  ];
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 8),
  ];

  /// 메뉴 카드 식당 태그의 (바탕, 글자) 색. 식당마다 다르게 — 학생식당 파랑,
  /// 생활관식당 주황, 교직원식당 초록(디자인 "Tag").
  static (Color, Color) tagColors(CafeteriaVenue venue) => switch (venue) {
    CafeteriaVenue.dorm => (const Color(0xFFFFF1E6), const Color(0xFFF2700D)),
    CafeteriaVenue.staff => (const Color(0xFFE6F8EF), const Color(0xFF14A363)),
    CafeteriaVenue.student ||
    CafeteriaVenue.cafe => (AppColors.blueSoft, AppColors.blueText),
  };
}
