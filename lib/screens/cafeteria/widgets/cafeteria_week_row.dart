import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';

/// 선택한 날짜가 속한 주의 월~금 요일 칩 다섯 개. 선택한 날은 라임색, 오늘에는
/// 숫자 아래에 점을 찍는다. 좌우로 밀면 이전/다음 주로 넘어간다([onWeekChanged]).
class CafeteriaWeekRow extends StatelessWidget {
  const CafeteriaWeekRow({
    required this.selectedDate,
    required this.today,
    required this.onDaySelected,
    required this.onWeekChanged,
    super.key,
  });

  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;

  /// 좌우로 밀었을 때. -1이면 이전 주, 1이면 다음 주.
  final ValueChanged<int> onWeekChanged;

  /// [date]가 속한 주의 월요일(주말이면 그 주 월요일 — 지난 월~금이 보인다).
  static DateTime mondayOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final monday = mondayOf(selectedDate);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -200) onWeekChanged(1); // 왼쪽으로 밀기 = 다음 주
        if (v > 200) onWeekChanged(-1);
      },
      child: Row(
        children: [
          for (var i = 0; i < 5; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _DayChip(
                label: weekdayLabelsWeekdaysOnly[i],
                date: monday.add(Duration(days: i)),
                selectedDate: selectedDate,
                today: today,
                onTap: onDaySelected,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.date,
    required this.selectedDate,
    required this.today,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onTap;

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final selected = _same(date, selectedDate);
    final isToday = _same(date, today);
    final foreground = selected ? AppColors.ink : Colors.white;

    return GestureDetector(
      onTap: () => onTap(date),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.cobaltDeep,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground.withValues(alpha: selected ? 0.7 : 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: foreground,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday ? foreground : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
