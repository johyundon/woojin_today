import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../cafeteria_colors.dart';

/// 가로로 넘기는 날짜 칩 줄(디자인 "07 학식"). 주말까지 포함해 오늘 [daysBefore]일
/// 전부터 [daysAfter]일 뒤까지 보여주고, 처음에는 오늘이 왼쪽 끝에 오게 놓는다. 양쪽
/// 칩이 화면 끝에서 잘려 보이도록 화면 가장자리까지 그린다(넘길 수 있다는 표시).
class CafeteriaDateStrip extends StatefulWidget {
  const CafeteriaDateStrip({
    required this.selectedDate,
    required this.today,
    required this.onDaySelected,
    this.daysBefore = 7,
    this.daysAfter = 13,
    super.key,
  });

  final DateTime selectedDate;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;
  final int daysBefore;
  final int daysAfter;

  /// 칩 너비와 칩 사이 간격, 줄 왼쪽 여백(디자인 64 / 8 / 16).
  static const double chipWidth = 64;
  static const double gap = 8;
  static const double sidePadding = 16;

  @override
  State<CafeteriaDateStrip> createState() => _CafeteriaDateStripState();
}

class _CafeteriaDateStripState extends State<CafeteriaDateStrip> {
  // 오늘 칩이 왼쪽 여백 바로 뒤에 오도록 처음 스크롤 위치를 잡는다.
  late final ScrollController _controller = ScrollController(
    initialScrollOffset:
        widget.daysBefore *
        (CafeteriaDateStrip.chipWidth + CafeteriaDateStrip.gap),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final first = widget.today.subtract(Duration(days: widget.daysBefore));
    final count = widget.daysBefore + widget.daysAfter + 1;

    return SizedBox(
      // 칩 높이(54) + 그림자가 잘리지 않게 위아래 여유.
      height: 62,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: CafeteriaDateStrip.sidePadding,
          vertical: 4,
        ),
        itemCount: count,
        separatorBuilder: (_, _) =>
            const SizedBox(width: CafeteriaDateStrip.gap),
        itemBuilder: (context, i) {
          // DST 등으로 시각이 어긋나지 않게 날짜만으로 만든다.
          final date = DateTime(first.year, first.month, first.day + i);
          return _DayChip(
            date: date,
            selected: DateUtils.isSameDay(date, widget.selectedDate),
            onTap: () => widget.onDaySelected(date),
          );
        },
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      child: Container(
        width: CafeteriaDateStrip.chipWidth,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? null : CafeteriaColors.chipShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              weekdayLabelsMonFirst[date.weekday - 1],
              style: TextStyle(
                color: selected ? AppColors.blue : CafeteriaColors.gray700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? AppColors.blue : AppColors.textStrong,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
