import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';

const Color _weekendRed = Color(0xFFE5484D);
const Color _mutedText = Color(0xFF7C7B88);
const Color _chipBackground = Color(0xFFF1F0F7);
const Color _disabledText = Color(0xFFD5D4DD);

/// 방문 상담 날짜를 고르는 미니 월간 캘린더(calendar_month_grid.dart와 같은
/// 코발트 선택 원 스타일을 따르되, 일정 점 표시 없이 날짜 선택만 한다).
/// [minDate]~[maxDate] 범위 밖 날짜는 눌러도 반응하지 않고 흐리게 보이며,
/// 그 범위를 벗어나는 달로는 화살표로도 못 넘어간다.
class AdvisorVisitCalendar extends StatefulWidget {
  const AdvisorVisitCalendar({
    required this.selectedDate,
    required this.onDateSelected,
    required this.minDate,
    required this.maxDate,
    super.key,
  });

  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime minDate;
  final DateTime maxDate;

  @override
  State<AdvisorVisitCalendar> createState() => _AdvisorVisitCalendarState();
}

class _AdvisorVisitCalendarState extends State<AdvisorVisitCalendar> {
  late DateTime _focusedMonth = DateTime(
    widget.selectedDate?.year ?? widget.minDate.year,
    widget.selectedDate?.month ?? widget.minDate.month,
  );

  bool get _canGoPrevious => DateTime(
    _focusedMonth.year,
    _focusedMonth.month,
  ).isAfter(DateTime(widget.minDate.year, widget.minDate.month));

  bool get _canGoNext => DateTime(
    _focusedMonth.year,
    _focusedMonth.month,
  ).isBefore(DateTime(widget.maxDate.year, widget.maxDate.month));

  void _changeMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    });
  }

  bool _isSelectable(DateTime day) {
    final min = DateTime(
      widget.minDate.year,
      widget.minDate.month,
      widget.minDate.day,
    );
    final max = DateTime(
      widget.maxDate.year,
      widget.maxDate.month,
      widget.maxDate.day,
    );
    return !day.isBefore(min) && !day.isAfter(max);
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    // DateTime.weekday는 월=1~일=7이라, 월요일 시작 격자의 앞 빈칸 수는 -1.
    final leadingBlanks =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;
    final weekCount = ((leadingBlanks + daysInMonth) / 7).ceil();

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${_focusedMonth.year}년 ${_focusedMonth.month}월',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            _buildNavButton(
              Icons.chevron_left,
              _canGoPrevious,
              () => _changeMonth(-1),
            ),
            const SizedBox(width: 6),
            _buildNavButton(
              Icons.chevron_right,
              _canGoNext,
              () => _changeMonth(1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < weekdayLabelsMonFirst.length; i++)
              Expanded(
                child: Center(
                  child: Text(
                    weekdayLabelsMonFirst[i],
                    style: TextStyle(
                      color: i >= 5 ? _weekendRed : _mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < weekCount; week++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _buildCell(
                    week * 7 + col - leadingBlanks + 1,
                    daysInMonth,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildNavButton(IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: _chipBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.ink : _disabledText,
        ),
      ),
    );
  }

  Widget _buildCell(int day, int daysInMonth) {
    if (day < 1 || day > daysInMonth) return const SizedBox(height: 40);

    final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
    final selectable = _isSelectable(date);
    final selected =
        widget.selectedDate != null &&
        widget.selectedDate!.year == date.year &&
        widget.selectedDate!.month == date.month &&
        widget.selectedDate!.day == date.day;

    return GestureDetector(
      key: ValueKey(
        'visit-calendar-day-${date.year}-${date.month}-${date.day}',
      ),
      behavior: HitTestBehavior.opaque,
      onTap: selectable ? () => widget.onDateSelected(date) : null,
      child: SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.cobalt : Colors.transparent,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : selectable
                    ? AppColors.ink
                    : _disabledText,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
