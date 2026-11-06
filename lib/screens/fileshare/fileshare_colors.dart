import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// [FileShareScreen]과 그 전용 위젯들이 함께 쓰는 화면 레벨 색상(v7).

/// 레이더 위 사람 아바타 바탕(번갈아 쓴다).
const List<Color> avatarColors = [AppColors.blueSoft, AppColors.blue];

/// 아바타 바탕 위 글자색 — 파랑 바탕이면 흰 글자, 그 외에는 진한 글자.
Color avatarForeground(Color background) =>
    background == AppColors.blue ? Colors.white : AppColors.textStrong;

/// 상태 카드 안 구분선(꺼짐/켜짐).
const Color statusDividerOff = Color(0xFFE2E4E8);
const Color statusDividerOn = Color(0x260A78E6);
