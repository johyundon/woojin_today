import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 날짜 그리드 한 칸.
///
/// 두 가지 뷰가 있다(Figma node 6:40 ↔ 6:44, [CalendarExpandHandle]로 전환):
/// - 압축 뷰(기본, [expanded]=false): 숫자를 박스로 감싸고, 그 아래 이
///   날짜에 겹치는 일정 수만큼 얇은 색 줄을 쌓아 그린다(이름표 없음).
/// - 확장 뷰([expanded]=true): 박스 없이 숫자만 그린다(선택된 날짜만 원형
///   강조). 겹치는 일정은 [CalendarWeekRow]가 그 아래 별도 줄에 긴 이름표
///   막대로 그린다.
///
/// [day]가 null이면 이번 달에 속하지 않는 빈 칸(월 시작/끝의 여백)이다.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.expanded,
    required this.eventColors,
    required this.onTap,
    super.key,
  });

  final int? day;
  final bool isSelected;
  final bool expanded;

  /// 압축 뷰에서만 쓰인다 — 이 날짜에 겹치는 일정들의 색, 주(week) 안에서
  /// 배정된 줄(row) 순서대로.
  final List<Color> eventColors;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) return const SizedBox(height: 32);

    if (expanded) {
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
              child: _DayNumber(day: day, isSelected: isSelected),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DayNumber(day: day, isSelected: isSelected),
            for (final color in eventColors)
              Container(
                margin: const EdgeInsets.only(top: 3),
                height: 2.5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({required this.day, required this.isSelected});

  final int day;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$day',
      style: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
      ),
    );
  }
}
