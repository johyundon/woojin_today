import 'package:flutter/material.dart';

import '../models/calendar_event.dart';
import 'calendar_day_cell.dart';
import 'calendar_event_bar.dart';

/// 한 주(일~토) 블록: 날짜 숫자 7칸 + 그 주와 겹치는 일정 막대들.
///
/// 막대는 겹치는 일정끼리는 줄을 나눠 쌓고(interval packing), 겹치지 않으면
/// 같은 줄에 나란히 놓는다(구글 캘린더 월간뷰 방식). 줄 수는 그 주에 겹치는
/// 일정 수에 따라 동적으로 늘어난다.
class CalendarWeekRow extends StatelessWidget {
  const CalendarWeekRow({
    required this.weekFirstDay,
    required this.daysInMonth,
    required this.focusedMonth,
    required this.events,
    required this.selectedDay,
    required this.expanded,
    required this.onDaySelected,
    super.key,
  });

  /// 이 주 일요일 칸이 가리키는 "월 중 며칠째"(1 미만/daysInMonth 초과일 수
  /// 있음 — 그런 칸은 빈 칸으로 렌더링된다).
  final int weekFirstDay;
  final int daysInMonth;
  final DateTime focusedMonth;

  /// 보고 있는 달과 겹치는 일정 전체(호출부에서 필터링 완료).
  final List<CalendarEvent> events;

  final int? selectedDay;

  /// false(압축, 기본)면 날짜 박스 안에 얇은 색 줄로 일정을 요약하고, true
  /// (확장)면 박스 없이 숫자만 그리고 그 아래 긴 이름표 막대로 일정을 그린다.
  final bool expanded;

  final ValueChanged<int> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final weekLastDay = weekFirstDay + 6;
    final segments = _packWeekEvents(
      events: events,
      focusedMonth: focusedMonth,
      daysInMonth: daysInMonth,
      weekFirstDay: weekFirstDay,
      weekLastDay: weekLastDay,
    );
    final rowCount = segments.isEmpty
        ? 0
        : segments.map((s) => s.row).reduce((a, b) => a > b ? a : b) + 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(child: _buildDayCell(col, segments)),
            ],
          ),
          if (expanded)
            for (var row = 0; row < rowCount; row++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: _buildBarRow(segments, row)),
              ),
        ],
      ),
    );
  }

  Widget _buildDayCell(int col, List<_EventSegment> segments) {
    final day = weekFirstDay + col;
    final visible = day >= 1 && day <= daysInMonth;
    return CalendarDayCell(
      day: visible ? day : null,
      isSelected: visible && day == selectedDay,
      expanded: expanded,
      eventColors: visible && !expanded
          ? _lineColorsForCol(segments, col)
          : const [],
      onTap: visible ? () => onDaySelected(day) : null,
    );
  }

  /// [col](요일 0~6)에 겹치는 일정들의 색을, 그 주 안에서 배정된 줄(row)
  /// 순서대로 반환한다 — 압축 뷰에서 날짜 박스 안 색 줄로 쓰인다.
  List<Color> _lineColorsForCol(List<_EventSegment> segments, int col) {
    final matches = segments.where((s) => s.startCol <= col && col <= s.endCol)
        .toList()
      ..sort((a, b) => a.row.compareTo(b.row));
    return [for (final s in matches) s.event.color];
  }

  List<Widget> _buildBarRow(List<_EventSegment> segments, int row) {
    final rowSegments = segments.where((s) => s.row == row).toList()
      ..sort((a, b) => a.startCol.compareTo(b.startCol));

    final children = <Widget>[];
    var cursor = 0;
    for (final seg in rowSegments) {
      if (seg.startCol > cursor) {
        children.add(
          Expanded(flex: seg.startCol - cursor, child: const SizedBox.shrink()),
        );
      }
      final span = seg.endCol - seg.startCol + 1;
      children.add(
        Expanded(
          flex: span,
          child: CalendarEventBar(
            event: seg.event,
            onTap: () => onDaySelected(weekFirstDay + seg.startCol),
          ),
        ),
      );
      cursor = seg.endCol + 1;
    }
    if (cursor < 7) {
      children.add(Expanded(flex: 7 - cursor, child: const SizedBox.shrink()));
    }
    return children;
  }
}

class _RawSegment {
  const _RawSegment(this.event, this.startCol, this.endCol);
  final CalendarEvent event;
  final int startCol;
  final int endCol;
}

class _EventSegment {
  const _EventSegment({
    required this.event,
    required this.startCol,
    required this.endCol,
    required this.row,
  });

  final CalendarEvent event;
  final int startCol;
  final int endCol;
  final int row;
}

/// 이 주와 겹치는 일정들을 열(요일, 0~6) 구간으로 자르고, 겹치는 구간끼리
/// 줄을 나눠 배정한다(그리디 interval packing: 시작 칸이 빠르고 긴 일정부터
/// 먼저 배정하며, 각 일정은 이미 배정된 줄 중 안 겹치는 첫 줄을 차지한다).
List<_EventSegment> _packWeekEvents({
  required List<CalendarEvent> events,
  required DateTime focusedMonth,
  required int daysInMonth,
  required int weekFirstDay,
  required int weekLastDay,
}) {
  final raw = <_RawSegment>[];
  for (final event in events) {
    final startDay = _dayNumberInMonth(
      event.startDate,
      focusedMonth,
      daysInMonth,
    );
    final endDay = _dayNumberInMonth(event.endDate, focusedMonth, daysInMonth);
    final overlapStart = [
      startDay,
      weekFirstDay,
      1,
    ].reduce((a, b) => a > b ? a : b);
    final overlapEnd = [
      endDay,
      weekLastDay,
      daysInMonth,
    ].reduce((a, b) => a < b ? a : b);
    if (overlapStart > overlapEnd) continue;
    raw.add(
      _RawSegment(
        event,
        overlapStart - weekFirstDay,
        overlapEnd - weekFirstDay,
      ),
    );
  }
  raw.sort((a, b) {
    final byStart = a.startCol.compareTo(b.startCol);
    if (byStart != 0) return byStart;
    return (b.endCol - b.startCol).compareTo(a.endCol - a.startCol);
  });

  final rowLastCol = <int>[];
  final result = <_EventSegment>[];
  for (final seg in raw) {
    var row = rowLastCol.indexWhere((lastCol) => lastCol < seg.startCol);
    if (row == -1) {
      row = rowLastCol.length;
      rowLastCol.add(seg.endCol);
    } else {
      rowLastCol[row] = seg.endCol;
    }
    result.add(
      _EventSegment(
        event: seg.event,
        startCol: seg.startCol,
        endCol: seg.endCol,
        row: row,
      ),
    );
  }
  return result;
}

/// [date]가 [focusedMonth]보다 이르면 0(월 시작보다 이른 것으로 클램프),
/// 늦으면 daysInMonth+1(월 끝보다 늦은 것으로 클램프)을 반환해 월/주 경계를
/// 넘는 일정도 자연스럽게 잘려 보이게 한다.
int _dayNumberInMonth(DateTime date, DateTime focusedMonth, int daysInMonth) {
  final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
  final monthEnd = DateTime(focusedMonth.year, focusedMonth.month, daysInMonth);
  if (date.isBefore(monthStart)) return 0;
  if (date.isAfter(monthEnd)) return daysInMonth + 1;
  return date.day;
}
