import 'package:flutter/material.dart';

/// "오늘 뭐 먹지?" 화면(v7 디자인 48 cafeteria)에서만 쓰는 색. 공통 v7 색은
/// [AppColors]에 있고, 여기에는 거기에 없는 값만 디자인에서 그대로 옮겨 둔다.
class CafeteriaColors {
  CafeteriaColors._();

  /// 메뉴 카드 테두리 rgb(232, 234, 238).
  static const Color cardBorder = Color(0xFFE8EAEE);

  /// 선택 안 된 식당 탭 글자·아이콘 rgb(63, 69, 88).
  static const Color tabText = Color(0xFF3F4558);
}
