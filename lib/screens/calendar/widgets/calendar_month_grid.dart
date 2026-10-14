import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/calendar_event.dart';

const List<String> _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
const Color _weekendRed = Color(0xFFE5484D);
const Color _mutedText = Color(0xFF6B6B70);

/// 월요일부터 시작하는 월간 날짜 격자. 일정이 있는 날짜는 숫자 아래에 일정
/// 색 점(최대 3개)을 찍고, 선택한 날짜는 파란 원, 오늘은 파란 테두리 원으로
/// 표시한다.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    required this.focusedMonth,
    required this.events,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
    super.key,
  });

  final DateTime focusedMonth;

  /// 보고 있는 달과 겹치는 일정 전체.
  final List<CalendarEvent> events;

  /// focusedMonth 안에서 선택된 날짜(일). 다른 달을 보고 있으면 null.
  final int? selectedDay;

  /// "오늘" 기준 날짜(테스트에서 고정할 수 있게 주입받는다).
  final DateTime today;

  final ValueChanged<int> onDaySelected;

  /// [day]일에 걸친 일정들의 색(최대 3개, 중복 색은 한 번만).
  List<Color> _dotColors(int day) {
    final date = DateTime(focusedMonth.year, focusedMonth.month, day);
    final colors = <Color>[];
    for (final event in events) {
      final start = DateTime(
        event.startDate.year,
        event.startDate.month,
        event.startDate.day,
      );
      final end = DateTime(
        event.endDate.year,
        event.endDate.month,
        event.endDate.day,
      );
      if (date.isBefore(start) || date.isAfter(end)) continue;
      if (!colors.contains(event.color)) colors.add(event.color);
      if (colors.length == 3) break;
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    // DateTime.weekday는 월=1~일=7이라, 월요일 시작 격자의 앞 빈칸 수는 -1.
    final leadingBlanks =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday - 1;
    final weekCount = ((leadingBlanks + daysInMonth) / 7).ceil();
    final isTodayMonth =
        today.year == focusedMonth.year && today.month == focusedMonth.month;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < _weekdayLabels.length; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdayLabels[i],
                    style: TextStyle(
                      color: i >= 5 ? _weekendRed : _mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var week = 0; week < weekCount; week++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _buildCell(
                    week * 7 + col - leadingBlanks + 1,
                    daysInMonth,
                    isTodayMonth,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(int day, int daysInMonth, bool isTodayMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 52);

    final selected = day == selectedDay;
    final isToday = isTodayMonth && day == today.day;
    final dots = _dotColors(day);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onDaySelected(day),
      child: SizedBox(
        height: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.cobalt : Colors.transparent,
                border: !selected && isToday
                    ? Border.all(color: AppColors.cobalt, width: 1.5)
                    : null,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.cobalt.withValues(alpha: 0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.ink,
                  fontSize: 15,
                  fontWeight: selected || isToday
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 3),
            SizedBox(
              height: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final color in dots)
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
