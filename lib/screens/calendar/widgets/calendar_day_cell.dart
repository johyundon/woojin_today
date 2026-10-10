import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 날짜 그리드 한 칸: 날짜 숫자만 그린다. 일정 막대는 [CalendarWeekRow]가
/// 날짜 숫자 줄 아래에 별도 줄로 그린다(구글 캘린더 월간뷰 방식).
///
/// [day]가 null이면 이번 달에 속하지 않는 빈 칸(월 시작/끝의 여백)이다.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final int? day;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) return const SizedBox(height: 32);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 32,
        child: Center(
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
