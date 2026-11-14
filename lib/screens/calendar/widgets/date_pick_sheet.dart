import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import 'calendar_colors.dart';
import 'calendar_month_grid.dart';
import 'sheet_buttons.dart';
import 'sheet_header.dart';

/// 날짜를 고르는 바텀시트. 캘린더 화면과 같은 월간 격자(일요일 시작, 한국어 요일,
/// 파란 선택 칸)를 쓰고, 위쪽 화살표로 달을 넘긴다. 저장하면 고른 날짜를, 취소하면
/// null을 반환한다. 일정 수정 화면의 시작/끝 날짜 칸에서 쓴다.
///
/// [firstDate]·[lastDate]를 주면 그 밖의 날은 흐리게 막고, 그 밖의 달로는 넘어가지
/// 않는다(알림 날짜 고르기에서 씀).
///
/// 예전에는 플러터 기본 날짜 창(showDatePicker)을 썼는데, 앱에 한국어 설정이 없고
/// 테마가 어두운 모드라 영어·검은 창으로 떠서 바꿨다(사용자 요청, 2026-10-31).
Future<DateTime?> showDatePickSheet(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  DateTime? today,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _DatePickSheet(
      title: title,
      initialDate: initialDate,
      today: today ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

class _DatePickSheet extends StatefulWidget {
  const _DatePickSheet({
    required this.title,
    required this.initialDate,
    required this.today,
    this.firstDate,
    this.lastDate,
  });

  final String title;
  final DateTime initialDate;
  final DateTime today;
  final DateTime? firstDate;
  final DateTime? lastDate;

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

  bool _isEnabled(DateTime date) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null &&
        date.isBefore(DateTime(first.year, first.month, first.day))) {
      return false;
    }
    if (last != null &&
        date.isAfter(DateTime(last.year, last.month, last.day))) {
      return false;
    }
    return true;
  }

  /// [first]가 있는 달보다 앞으로/[last]가 있는 달보다 뒤로는 못 넘긴다.
  bool get _canGoBack {
    final first = widget.firstDate;
    return first == null || DateTime(first.year, first.month).isBefore(_month);
  }

  bool get _canGoForward {
    final last = widget.lastDate;
    return last == null || DateTime(last.year, last.month).isAfter(_month);
  }

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
              color: AppColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MonthArrow(
                icon: Icons.chevron_left_rounded,
                onTap: _canGoBack ? () => _moveMonth(-1) : null,
              ),
              Expanded(
                child: Text(
                  '${_month.year}년 ${_month.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_right_rounded,
                onTap: _canGoForward ? () => _moveMonth(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          CalendarMonthGrid(
            focusedMonth: _month,
            events: const [],
            selectedDay: selectedInMonth ? _selected.day : null,
            today: widget.today,
            isEnabled: _isEnabled,
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

/// 날짜를 여러 개 고르는 바텀시트(알림 받을 날 고르기). 날짜를 누를 때마다
/// 골라지고 다시 누르면 풀린다. 날짜 위를 손가락으로 끌면 처음 칸부터 지금 칸까지
/// 연속으로 골라진다(골라진 칸에서 시작하면 풀린다)(사용자 요청, 2026-11-14). [firstDate]~[lastDate] 밖은 흐리게 막고,
/// [maxCount]개까지만 고를 수 있다. 저장하면 고른 날들(날짜 순)을, 취소하면 null을
/// 반환한다. 하나도 안 고르면 저장이 비활성이다.
Future<List<DateTime>?> showMultiDatePickSheet(
  BuildContext context, {
  required String title,
  required DateTime initialMonth,
  required DateTime firstDate,
  required DateTime lastDate,
  required int maxCount,
  DateTime? today,
}) {
  return showModalBottomSheet<List<DateTime>>(
    context: context,
    isScrollControlled: true,
    // 날짜 위를 아래로 끌어 고를 때 창이 같이 내려가 닫히지 않게 한다.
    enableDrag: false,
    backgroundColor: Colors.white,
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _MultiDatePickSheet(
      title: title,
      initialMonth: initialMonth,
      firstDate: firstDate,
      lastDate: lastDate,
      maxCount: maxCount,
      today: today ?? DateTime.now(),
    ),
  );
}

class _MultiDatePickSheet extends StatefulWidget {
  const _MultiDatePickSheet({
    required this.title,
    required this.initialMonth,
    required this.firstDate,
    required this.lastDate,
    required this.maxCount,
    required this.today,
  });

  final String title;
  final DateTime initialMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final int maxCount;
  final DateTime today;

  @override
  State<_MultiDatePickSheet> createState() => _MultiDatePickSheetState();
}

class _MultiDatePickSheetState extends State<_MultiDatePickSheet> {
  late DateTime _month = DateTime(
    widget.initialMonth.year,
    widget.initialMonth.month,
  );
  final Set<DateTime> _picked = {};

  DateTime get _first => DateTime(
    widget.firstDate.year,
    widget.firstDate.month,
    widget.firstDate.day,
  );

  DateTime get _last => DateTime(
    widget.lastDate.year,
    widget.lastDate.month,
    widget.lastDate.day,
  );

  bool _isEnabled(DateTime date) =>
      !date.isBefore(_first) && !date.isAfter(_last);

  void _moveMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  /// 끌기 시작할 때의 고른 날들과 시작 칸. 끄는 동안 시작 칸~지금 칸을 이
  /// 상태 위에 다시 칠해서, 되돌아 끌면 줄어든다.
  Set<DateTime>? _dragBase;
  DateTime? _dragAnchor;
  bool _dragAdds = true;

  void _onDrag(int day) {
    final date = DateTime(_month.year, _month.month, day);
    setState(() {
      if (_dragBase == null) {
        _dragBase = {..._picked};
        _dragAnchor = date;
        _dragAdds = !_picked.contains(date);
      }
      final from = date.isBefore(_dragAnchor!) ? date : _dragAnchor!;
      final to = date.isBefore(_dragAnchor!) ? _dragAnchor! : date;
      _picked
        ..clear()
        ..addAll(_dragBase!);
      for (
        var d = from;
        !d.isAfter(to);
        d = DateTime(d.year, d.month, d.day + 1)
      ) {
        if (!_isEnabled(d)) continue;
        if (!_dragAdds) {
          _picked.remove(d);
        } else if (_picked.length < widget.maxCount) {
          _picked.add(d);
        }
      }
    });
  }

  void _endDrag() {
    _dragBase = null;
    _dragAnchor = null;
  }

  void _toggle(int day) {
    final date = DateTime(_month.year, _month.month, day);
    setState(() {
      if (!_picked.remove(date) && _picked.length < widget.maxCount) {
        _picked.add(date);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final full = _picked.length >= widget.maxCount;
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
              color: AppColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _picked.isEmpty
                ? '누르거나 끌어서 여러 날을 고를 수 있어요'
                : full
                ? '${_picked.length}일 골랐어요 · 더는 고를 수 없어요'
                : '${_picked.length}일 골랐어요',
            style: TextStyle(
              color: full ? CalendarColors.deleteRed : AppColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MonthArrow(
                icon: Icons.chevron_left_rounded,
                onTap: DateTime(_first.year, _first.month).isBefore(_month)
                    ? () => _moveMonth(-1)
                    : null,
              ),
              Expanded(
                child: Text(
                  '${_month.year}년 ${_month.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_right_rounded,
                onTap: DateTime(_last.year, _last.month).isAfter(_month)
                    ? () => _moveMonth(1)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 14),
          CalendarMonthGrid(
            focusedMonth: _month,
            events: const [],
            selectedDay: null,
            today: widget.today,
            isEnabled: _isEnabled,
            isSelected: _picked.contains,
            onDaySelected: _toggle,
            onDayDragged: _onDrag,
            onDragEnd: _endDrag,
          ),
          const SizedBox(height: 16),
          SheetButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onSave: _picked.isEmpty
                ? null
                : () => Navigator.of(context).pop(_picked.toList()..sort()),
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
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
              color: AppColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: TextStyle(
              color: end == null ? AppColors.blue : AppColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MonthArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => _moveMonth(-1),
              ),
              Expanded(
                child: Text(
                  '${_month.year}년 ${_month.month}월',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _MonthArrow(
                icon: Icons.chevron_right_rounded,
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

/// 달 넘기기 둥근 사각 버튼(흰 시트 위라 연한 회색 바탕).
class _MonthArrow extends StatelessWidget {
  const _MonthArrow({required this.icon, required this.onTap});

  final IconData icon;

  /// null이면 더 넘길 수 없는 쪽이라 흐리게 보이고 눌리지 않는다.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable.icon(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.3 : 1,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textStrong, size: 22),
        ),
      ),
    );
  }
}
