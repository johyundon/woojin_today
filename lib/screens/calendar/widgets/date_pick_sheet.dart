import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'calendar_month_grid.dart';
import 'sheet_buttons.dart';
import 'sheet_header.dart';

/// 날짜를 고르는 바텀시트. 캘린더 화면과 같은 월간 격자(월요일 시작, 한국어 요일,
/// 파란 선택 원)를 쓰고, 위쪽 화살표로 달을 넘긴다. 저장하면 고른 날짜를, 취소하면
/// null을 반환한다. 일정 수정 화면의 시작/끝 날짜 칸에서 쓴다.
///
/// 예전에는 플러터 기본 날짜 창(showDatePicker)을 썼는데, 앱에 한국어 설정이 없고
/// 테마가 어두운 모드라 영어·검은 창으로 떠서 바꿨다(사용자 요청, 2026-10-31).
Future<DateTime?> showDatePickSheet(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  DateTime? today,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _DatePickSheet(
      title: title,
      initialDate: initialDate,
      today: today ?? DateTime.now(),
    ),
  );
}

class _DatePickSheet extends StatefulWidget {
  const _DatePickSheet({
    required this.title,
    required this.initialDate,
    required this.today,
  });

  final String title;
  final DateTime initialDate;
  final DateTime today;

  @override
  State<_DatePickSheet> createState() => _DatePickSheetState();
}

class _DatePickSheetState extends State<_DatePickSheet> {
  late DateTime _selected = DateTime(
    widget.initialDate.year,
    widget.initialDate.month,
    widget.initialDate.day,
  );
  late DateTime _month = DateTime(_selected.year, _selected.month);

  void _moveMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final selectedInMonth =
        _selected.year == _month.year && _selected.month == _month.month;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetGrabber(),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MonthArrow(
                icon: Icons.chevron_left,
                onTap: () => _moveMonth(-1),
              ),
              Expanded(
                child: Text(
                  '${_month.year}년 ${_month.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_right,
                onTap: () => _moveMonth(1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          CalendarMonthGrid(
            focusedMonth: _month,
            events: const [],
            selectedDay: selectedInMonth ? _selected.day : null,
            today: widget.today,
            onDaySelected: (day) => setState(
              () => _selected = DateTime(_month.year, _month.month, day),
            ),
          ),
          const SizedBox(height: 16),
          SheetButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onSave: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

/// 달 넘기기 둥근 버튼(캘린더 화면 헤더의 화살표와 같은 모양, 밝은 바탕용).
class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F1F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.ink, size: 22),
      ),
    );
  }
}
