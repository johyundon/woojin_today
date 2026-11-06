import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 캠퍼스 지도 화면의 색상(v7). 지도 위에 떠 있는 흰 카드들이라 공통 v7 색을
/// 그대로 쓰고, 시안에만 있는 몇 가지 값만 여기 둔다.
class CampusMapColors {
  CampusMapColors._();

  /// 지도가 그려지기 전 바탕(시안의 지도 바탕색).
  static const Color background = Color(0xFFEEF0F3);
  static const Color surface = Colors.white;
  static const Color textPrimary = AppColors.textStrong;
  static const Color textSecondary = AppColors.textSub;
  static const Color accent = AppColors.blue;

  /// 건물 상세 카드의 건물 이름 글자.
  static const Color buildingName = Color(0xFF2B2F3B);

  /// 회색 버튼("출발지로 선택") 글자.
  static const Color secondaryButtonText = Color(0xFF3F4558);

  /// 위쪽 흰 검색 영역의 그림자(아래로 은은하게).
  static const List<BoxShadow> headerShadow = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 4), blurRadius: 20),
  ];

  /// 아래쪽 건물 상세 카드의 그림자(위로 은은하게).
  static const List<BoxShadow> sheetShadow = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, -4), blurRadius: 24),
  ];
}
