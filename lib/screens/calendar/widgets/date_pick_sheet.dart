import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
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

/// 시작~끝 날짜를 한 번에 고르는 바텀시트. 처음엔 지금 기간이 표시되고, 날짜를
/// 누르면 그 날이 새 시작일이 되며, 이어서 다른 날을 누르면 끝나는 날이 된다
/// (시작보다 앞 날을 누르면 그 날이 새 시작일). 달을 넘겨 고를 수도 있다. 시작만
/// 고르고 저장하면 하루짜리로 본다. 저장하면 기간을, 취소하면 null을 반환한다.
Future<DateTimeRange?> showDateRangePickSheet(
  BuildContext context, {
  required DateTime initialStart,
  required DateTime initialEnd,
  DateTime? today,
}) {
  return showModalBottomSheet<DateTimeRange>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _DateRangePickSheet(
      initialStart: initialStart,
      initialEnd: initialEnd,
      today: today ?? DateTime.now(),
    ),
  );
}

class _DateRangePickSheet extends StatefulWidget {
  const _DateRangePickSheet({
    required this.initialStart,
    required this.initialEnd,
    required this.today,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime today;

  @override
  State<_DateRangePickSheet> createState() => _DateRangePickSheetState();
}

class _DateRangePickSheetState extends State<_DateRangePickSheet> {
  late DateTime _start = _dateOnly(widget.initialStart);

  /// null이면 시작일만 고른 상태(끝나는 날을 고르는 중).
  late DateTime? _end = _dateOnly(widget.initialEnd);
  late DateTime _month = DateTime(_start.year, _start.month);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _moveMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _onDay(int day) {
    final date = DateTime(_month.year, _month.month, day);
    setState(() {
      if (_end != null || date.isBefore(_start)) {
        _start = date;
        _end = null;
      } else {
        _end = date;
      }
    });
  }

  String _label(DateTime d) => '${d.month}월 ${d.day}일';

  @override
  Widget build(BuildContext context) {
    final end = _end;
    final summary = end == null
        ? '${_label(_start)} ~ 끝나는 날짜를 골라 주세요'
        : end == _start
        ? _label(_start)
        : '${_label(_start)} ~ ${_label(end)}';
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
          const Text(
            '날짜 고르기',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: TextStyle(
              color: end == null ? AppColors.cobalt : const Color(0xFF6B6B70),
              fontSize: 13,
              fontWeight: FontWeight.w700,
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
            selectedDay: null,
            today: widget.today,
            onDaySelected: _onDay,
            rangeStart: _start,
            rangeEnd: end ?? _start,
          ),
          const SizedBox(height: 16),
          SheetButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onSave: () =>
                Navigator.of(context)
                    .pop(DateTimeRange(start: _start, end: end ?? _start)),
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
    return Pressable.icon(
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
