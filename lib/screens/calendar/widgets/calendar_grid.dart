import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/calendar_event.dart';
import 'calendar_week_row.dart';

const List<String> _weekdayLabels = ['일', '월', '화', '수', '목', '금', '토'];

/// 요일 헤더 + 주(week) 단위 날짜/일정 막대 그리드.
///
/// 구글 캘린더 월간뷰처럼, 여러 날에 걸친 일정은 해당 날짜 칸들을 가로지르는
/// 긴 막대 하나로 이어져 그려진다. 주 경계를 넘는 일정은 주마다 독립된
/// 막대로 끊어서 그린다(모서리를 이어붙이는 정교한 처리는 범위 밖).
class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    required this.focusedMonth,
    required this.events,
    required this.selectedDay,
    required this.expanded,
    required this.onDaySelected,
    super.key,
  });

  final DateTime focusedMonth;

  /// 보고 있는 달과 겹치는 일정 전체.
  final List<CalendarEvent> events;

  /// focusedMonth 안에서 선택된 날짜. 다른 달을 보고 있으면 null.
  final int? selectedDay;

  /// false(압축, 기본)면 날짜 박스 안에 얇은 색 줄로 일정을 요약하고, true
  /// (확장)면 박스 없이 숫자만 그리고 그 아래 긴 이름표 막대로 일정을 그린다.
  final bool expanded;

  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
    ).day;
    // Dart의 DateTime.weekday는 월요일=1 ~ 일요일=7이라, 일요일 시작 그리드를
    // 맞추려면 %7로 보정한다(일요일 7 -> 0).
    final leadingBlanks =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday % 7;
    final weekCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < weekCount; week++)
          CalendarWeekRow(
            weekFirstDay: week * 7 - leadingBlanks + 1,
            daysInMonth: daysInMonth,
            focusedMonth: focusedMonth,
            events: events,
            selectedDay: selectedDay,
            expanded: expanded,
            onDaySelected: onDaySelected,
          ),
      ],
    );
  }
}
