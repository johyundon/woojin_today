import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';

/// 일요일부터 시작하는 월간 날짜 격자(v7). 일정이 있는 날짜는 숫자 아래에 일정
/// 색 점(최대 3개)을 찍고, 선택한 날짜는 파란 둥근 사각형, 오늘은 파란 테두리
/// 둥근 사각형으로 표시한다.
class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    required this.focusedMonth,
    required this.events,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
    this.rangeStart,
    this.rangeEnd,
    this.isEnabled,
    this.isSelected,
    this.onDayDragged,
    this.onDragEnd,
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

  /// 기간 선택 표시(날짜 고르기 시트에서만 씀). 둘 다 있으면 시작~끝을 파란 원으로,
  /// 그 사이를 연한 파란 띠로 잇는다. 메인 캘린더는 넘기지 않아 모양이 그대로다.
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  /// 고를 수 있는 날인지(날짜 고르기 시트에서만 씀). false인 날은 흐리게 보이고
  /// 눌리지 않는다. null이면 모든 날을 고를 수 있다.
  final bool Function(DateTime date)? isEnabled;

  /// 여러 날을 골라 둔 표시(알림 날짜 여러 개 고르기에서만 씀). true인 날은
  /// [selectedDay]처럼 파란 칸으로 보인다.
  final bool Function(DateTime date)? isSelected;

  /// 날짜 칸 위를 끌 때(드래그) 손가락 아래에 있는 날(일)을 알린다. 끌기 시작한
  /// 칸에서 한 번, 다른 칸으로 옮겨 갈 때마다 다시 부른다(같은 칸이면 다시 안
  /// 부름). null이면 끌기를 받지 않는다(여러 날 고르기 창에서만 씀).
  final ValueChanged<int>? onDayDragged;

  /// 끌기가 끝났을 때.
  final VoidCallback? onDragEnd;

  /// 한 주 줄의 높이(칸 44 + 줄 사이 2). 끈 위치를 날짜로 바꿀 때 쓴다.
  static const double _weekStride = 46;

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
    // DateTime.weekday는 월=1~일=7이라, 일요일 시작 격자의 앞 빈칸 수는 % 7.
    final leadingBlanks =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday % 7;
    final weekCount = ((leadingBlanks + daysInMonth) / 7).ceil();
    final isTodayMonth =
        today.year == focusedMonth.year && today.month == focusedMonth.month;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < weekdayLabelsSunFirst.length; i++)
              Expanded(
                child: Center(
                  child: Text(
                    weekdayLabelsSunFirst[i],
                    style: TextStyle(
                      color: i == 0 || i == 6
                          ? CalendarColors.weekendRed
                          : AppColors.textSub,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _withDrag(
          leadingBlanks: leadingBlanks,
          daysInMonth: daysInMonth,
          child: Column(
            children: [
              for (var week = 0; week < weekCount; week++)
                Padding(
                  padding: EdgeInsets.only(top: week == 0 ? 0 : 2),
                  child: Row(
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
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// [onDayDragged]가 있으면 날짜 칸들을 끌기로 감싼다. 끈 위치(가로 7칸 ×
  /// 주 줄)를 날짜로 바꿔, 칸이 바뀔 때마다 알린다.
  Widget _withDrag({
    required int leadingBlanks,
    required int daysInMonth,
    required Widget child,
  }) {
    final onDrag = onDayDragged;
    if (onDrag == null) return child;
    int? last;
    return LayoutBuilder(
      builder: (context, constraints) {
        int? dayAt(Offset p) {
          if (p.dx < 0 || p.dx >= constraints.maxWidth || p.dy < 0) {
            return null;
          }
          final col = (p.dx / (constraints.maxWidth / 7)).floor();
          final week = (p.dy / _weekStride).floor();
          final day = week * 7 + col - leadingBlanks + 1;
          return day < 1 || day > daysInMonth ? null : day;
        }

        void report(Offset p) {
          final day = dayAt(p);
          if (day == null || day == last) return;
          last = day;
          onDrag(day);
        }

        return GestureDetector(
          // 처음 누른 칸부터 끌기로 친다(살짝 움직인 거리도 버리지 않음).
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (d) {
            last = null;
            report(d.localPosition);
          },
          onPanUpdate: (d) => report(d.localPosition),
          onPanEnd: (_) => onDragEnd?.call(),
          onPanCancel: () => onDragEnd?.call(),
          child: child,
        );
      },
    );
  }

  Widget _buildCell(int day, int daysInMonth, bool isTodayMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 44);

    final date = DateTime(focusedMonth.year, focusedMonth.month, day);
    final start = rangeStart;
    final end = rangeEnd;
    final isRangeStart = start != null && _sameDay(date, start);
    final isRangeEnd = end != null && _sameDay(date, end);
    final hasRange = start != null && end != null && start.isBefore(end);
    final inRange =
        hasRange &&
        !date.isBefore(_dateOnly(start)) &&
        !date.isAfter(_dateOnly(end));
    final selected =
        day == selectedDay ||
        isRangeStart ||
        isRangeEnd ||
        (isSelected?.call(date) ?? false);
    final isToday = isTodayMonth && day == today.day;
    final dots = _dotColors(day);
    final enabled = isEnabled?.call(date) ?? true;

    return Pressable(
      onTap: enabled ? () => onDaySelected(day) : null,
      pressedScale: 0.9,
      child: SizedBox(
        height: 44,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // 기간 안의 날짜는 칸 폭 전체에 연한 띠를 깔고, 시작일은 오른쪽 반,
                // 끝일은 왼쪽 반만 깔아서 원끼리 띠로 이어 보이게 한다.
                if (inRange)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 36,
                          color: isRangeStart
                              ? Colors.transparent
                              : AppColors.blueSoft,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 36,
                          color: isRangeEnd
                              ? Colors.transparent
                              : AppColors.blueSoft,
                        ),
                      ),
                    ],
                  ),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected ? AppColors.blue : Colors.transparent,
                    border: !selected && isToday
                        ? Border.all(color: AppColors.blue, width: 1.5)
                        : null,
                    boxShadow: selected ? AppColors.cardShadow : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: selected
                          ? Colors.white
                          : enabled
                          ? AppColors.textStrong
                          : AppColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: selected || isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ],
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
