import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "< 2026년 9월 >" 월 이동 네비게이션.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    required this.focusedMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    super.key,
  });

  final DateTime focusedMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPreviousMonth,
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary),
        ),
        Text(
          '${focusedMonth.year}년 ${focusedMonth.month}월',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        IconButton(
          onPressed: onNextMonth,
          icon: const Icon(Icons.chevron_right, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
