import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';

/// 캘린더를 아래로 끌어 펼쳤을 때의 월간 격자. 날짜 숫자 아래에 일정 제목을 색
/// 막대로 그리고, 여러 날에 걸친 일정은 한 주 안에서 막대 하나로 잇는다(주가
/// 바뀌면 다음 줄에서 새 막대로 이어 그린다). 한 주에 막대는 최대 [maxLanes]줄
/// (칸 높이가 모자라면 그보다 적게)이고, 못 그린 일정은 그 날짜 칸 아래에 "+N"으로
/// 남은 개수만 보여 준다.
///
/// 날짜 고르기 시트들이 같이 쓰는 [CalendarMonthGrid]의 모양을 바꾸지 않으려고
/// 따로 만든 위젯이다.
class CalendarExpandedGrid extends StatelessWidget {
  const CalendarExpandedGrid({
    required this.focusedMonth,
    required this.events,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
    this.onEventTap,
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

  /// 일정 막대를 눌렀을 때(그 일정의 상세 팝업 열기). null이면 막대는 누름을
  /// 받지 않고 아래 날짜 칸이 받는다.
  final ValueChanged<CalendarEvent>? onEventTap;

  /// 한 주에 그리는 막대 줄 수의 최대값.
  static const int maxLanes = 3;

  static const double _numberHeight = 28;
  static const double _barHeight = 17;
  static const double _barGap = 2;
  static const double _moreHeight = 14;

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
        const SizedBox(height: 4),
        Expanded(
          child: Column(
            children: [
              for (var week = 0; week < weekCount; week++)
                Expanded(
                  child: _buildWeek(
                    firstDay: week * 7 - leadingBlanks + 1,
                    daysInMonth: daysInMonth,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 한 주 줄. [firstDay]는 이 줄 맨 왼쪽(일요일) 칸의 일(달 밖이면 0 이하이거나
  /// [daysInMonth]보다 크다).
  Widget _buildWeek({required int firstDay, required int daysInMonth}) {
    final segments = _layoutWeek(firstDay, daysInMonth);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / 7;
        // 칸 높이에 들어가는 만큼만(최대 maxLanes줄) 막대를 그린다.
        final room =
            constraints.maxHeight - _numberHeight - _moreHeight + _barGap;
        final lanes = math.min(
          maxLanes,
          math.max(0, (room / (_barHeight + _barGap)).floor()),
        );
        final hiddenPerColumn = List.filled(7, 0);
        for (final s in segments) {
          if (s.lane < lanes) continue;
          for (var col = s.startCol; col <= s.endCol; col++) {
            hiddenPerColumn[col]++;
          }
        }

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _buildCell(
                      day: firstDay + col,
                      daysInMonth: daysInMonth,
                      hidden: hiddenPerColumn[col],
                      moreTop: _numberHeight + lanes * (_barHeight + _barGap),
                    ),
                  ),
              ],
            ),
            // 막대를 누르면 그 일정의 상세가 열리고, 막대 밖(날짜 숫자·빈 곳)을
            // 누르면 날짜 칸이 받는다(사용자 요청, 2026-11-14).
            IgnorePointer(
              ignoring: onEventTap == null,
              child: Stack(
                children: [
                  for (final s in segments)
                    if (s.lane < lanes)
                      Positioned(
                        top: _numberHeight + s.lane * (_barHeight + _barGap),
                        left:
                            s.startCol * columnWidth +
                            (s.continuesBefore ? 0 : 1),
                        width:
                            (s.endCol - s.startCol + 1) * columnWidth -
                            (s.continuesBefore ? 0 : 1) -
                            (s.continuesAfter ? 0 : 1),
                        height: _barHeight,
                        child: onEventTap == null
                            ? _EventBar(segment: s)
                            : Pressable(
                                onTap: () => onEventTap!(s.event),
                                pressedScale: 0.96,
                                child: _EventBar(segment: s),
                              ),
                      ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCell({
    required int day,
    required int daysInMonth,
    required int hidden,
    required double moreTop,
  }) {
    if (day < 1 || day > daysInMonth) return const SizedBox.shrink();
    final selected = day == selectedDay;
    final isToday =
        today.year == focusedMonth.year &&
        today.month == focusedMonth.month &&
        today.day == day;

    return Pressable(
      onTap: () => onDaySelected(day),
      pressedScale: 0.94,
      child: Container(
        // 투명 바탕이라도 칸 전체가 눌리도록 색을 깐다.
        color: Colors.transparent,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: selected ? AppColors.blue : Colors.transparent,
                    border: !selected && isToday
                        ? Border.all(color: AppColors.blue, width: 1.5)
                        : null,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textStrong,
                      fontSize: 13,
                      fontWeight: selected || isToday
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (hidden > 0)
              Positioned(
                top: moreTop,
                left: 0,
                right: 0,
                height: _moreHeight,
                child: Center(
                  child: Text(
                    '+$hidden',
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 이 주에 걸친 일정을 칸 범위로 자르고, 겹치지 않게 막대 줄(lane)을 정한다.
  /// 먼저 시작하는 일정, 같은 날 시작이면 긴 일정이 위 줄을 차지한다.
  List<_WeekSegment> _layoutWeek(int firstDay, int daysInMonth) {
    final firstVisible = math.max(1, firstDay);
    final lastVisible = math.min(daysInMonth, firstDay + 6);
    if (firstVisible > lastVisible) return const [];
    final rangeStart = _date(firstVisible);
    final rangeEnd = _date(lastVisible);

    final sorted =
        events.where((e) {
          return !_dateOnly(e.endDate).isBefore(rangeStart) &&
              !_dateOnly(e.startDate).isAfter(rangeEnd);
        }).toList()..sort((a, b) {
          final byStart = _dateOnly(a.startDate)
              .compareTo(_dateOnly(b.startDate));
          if (byStart != 0) return byStart;
          final aDays = _dateOnly(a.endDate).difference(_dateOnly(a.startDate));
          final bDays = _dateOnly(b.endDate).difference(_dateOnly(b.startDate));
          final byLength = bDays.compareTo(aDays);
          if (byLength != 0) return byLength;
          return a.title.compareTo(b.title);
        });

    final laneEnds = <int>[]; // 줄마다 마지막으로 차지한 칸.
    final segments = <_WeekSegment>[];
    for (final event in sorted) {
      final start = _dateOnly(event.startDate);
      final end = _dateOnly(event.endDate);
      final clippedStart = start.isBefore(rangeStart) ? rangeStart : start;
      final clippedEnd = end.isAfter(rangeEnd) ? rangeEnd : end;
      final startCol = clippedStart.day - firstDay;
      final endCol = clippedEnd.day - firstDay;
      var lane = laneEnds.indexWhere((last) => last < startCol);
      if (lane == -1) {
        lane = laneEnds.length;
        laneEnds.add(endCol);
      } else {
        laneEnds[lane] = endCol;
      }
      segments.add(
        _WeekSegment(
          event: event,
          startCol: startCol,
          endCol: endCol,
          lane: lane,
          continuesBefore: start.isBefore(clippedStart),
          continuesAfter: end.isAfter(clippedEnd),
        ),
      );
    }
    return segments;
  }

  DateTime _date(int day) =>
      DateTime(focusedMonth.year, focusedMonth.month, day);
}

class _WeekSegment {
  const _WeekSegment({
    required this.event,
    required this.startCol,
    required this.endCol,
    required this.lane,
    required this.continuesBefore,
    required this.continuesAfter,
  });

  final CalendarEvent event;
  final int startCol;
  final int endCol;
  final int lane;

  /// 이 주(또는 이 달) 앞에서 이어져 온 일정이면 왼쪽 모서리를 각지게 붙인다.
  final bool continuesBefore;

  /// 다음 주(또는 다음 달)로 이어지면 오른쪽 모서리를 각지게 붙인다.
  final bool continuesAfter;
}

/// 일정 색 막대. 제목이 길면 끝을 "…"로 자른다.
class _EventBar extends StatelessWidget {
  const _EventBar({required this.segment});

  final _WeekSegment segment;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: segment.event.color,
        borderRadius: BorderRadius.horizontal(
          left: segment.continuesBefore ? Radius.zero : radius,
          right: segment.continuesAfter ? Radius.zero : radius,
        ),
      ),
      child: Text(
        segment.event.title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          height: 1.2,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
