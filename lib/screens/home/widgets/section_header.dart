import 'package:flutter/material.dart';

import '../home_colors.dart';

/// "필요한 기능만 모아봤어요!" + "모아보기" 섹션 헤더.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.colors, required this.onMorePressed});

  final HomeColors colors;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '필요한 기능만 모아봤어요!',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: onMorePressed,
          child: Text(
            '모아보기',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
