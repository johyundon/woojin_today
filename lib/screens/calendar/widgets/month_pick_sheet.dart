import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import 'calendar_colors.dart';
import 'sheet_header.dart';

/// 캘린더 상단의 "2026년 11월 ⌄" 칩을 눌렀을 때 뜨는 달 고르기 시트.
/// 위쪽 화살표로 연도를 넘기고, 12달 중 하나를 누르면 그 달(1일)을 돌려준다.
/// 닫으면 null.
Future<DateTime?> showMonthPickSheet(
  BuildContext context, {
  required DateTime initialMonth,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) => _MonthPickSheet(initialMonth: initialMonth),
  );
}

class _MonthPickSheet extends StatefulWidget {
  const _MonthPickSheet({required this.initialMonth});

  final DateTime initialMonth;

  @override
  State<_MonthPickSheet> createState() => _MonthPickSheetState();
}

class _MonthPickSheetState extends State<_MonthPickSheet> {
  late int _year = widget.initialMonth.year;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 16),
          Row(
            children: [
              _arrow(Icons.chevron_left_rounded, () => setState(() => _year--)),
              Expanded(
                child: Text(
                  '$_year년',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _arrow(
                Icons.chevron_right_rounded,
                () => setState(() => _year++),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var row = 0; row < 3; row++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  for (var col = 0; col < 4; col++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _monthCell(row * 4 + col + 1, now),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) => Pressable.icon(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(icon, size: 24, color: AppColors.textStrong),
    ),
  );

  Widget _monthCell(int month, DateTime now) {
    final selected =
        _year == widget.initialMonth.year && month == widget.initialMonth.month;
    final isThisMonth = _year == now.year && month == now.month;
    return Pressable(
      onTap: () => Navigator.of(context).pop(DateTime(_year, month)),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : AppColors.fill,
          borderRadius: BorderRadius.circular(12),
          border: !selected && isThisMonth
              ? Border.all(color: AppColors.blue, width: 1.5)
              : null,
        ),
        child: Text(
          '$month월',
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textStrong,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
