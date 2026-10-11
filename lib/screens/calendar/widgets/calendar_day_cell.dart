import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 날짜 그리드 한 칸.
///
/// 두 가지 뷰가 있다(Figma node 6:40 ↔ 6:44, [CalendarExpandHandle]로 전환):
/// - 압축 뷰(기본, [expanded]=false): 숫자를 박스로 감싸고, 그 아래 이
///   날짜에 겹치는 일정 수만큼 얇은 색 줄을 쌓아 그린다(이름표 없음).
/// - 확장 뷰([expanded]=true): 박스 없이 숫자만 그린다(선택된 날짜만 원형
///   강조). 겹치는 일정은 [CalendarWeekRow]가 그 아래 별도 줄에 긴 이름표
///   막대로 그린다.
///
/// [day]가 null이면 이번 달에 속하지 않는 빈 칸(월 시작/끝의 여백)이다.
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.expanded,
    required this.eventColors,
    required this.lineSlotCount,
    required this.onTap,
    super.key,
  });

  final int? day;
  final bool isSelected;
  final bool expanded;

  /// 압축 뷰에서만 쓰인다 — 이 날짜에 겹치는 일정들의 색, 주(week) 안에서
  /// 배정된 줄(row) 순서대로.
  final List<Color> eventColors;

  /// 압축 뷰에서만 쓰인다 — 이 주(week)에서 가장 많이 겹치는 일정 수. 실제
  /// 일정 수가 이보다 적은 날짜는 투명한 줄로 자리만 채워서, 같은 주 안의
  /// 날짜 박스 높이가 전부 같아지게 만든다.
  final int lineSlotCount;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final day = this.day;
    if (day == null) return const SizedBox(height: 32);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: expanded
            ? _ExpandedDayCell(
                key: const ValueKey('expanded'),
                day: day,
                isSelected: isSelected,
              )
            : _CompactDayCell(
                key: const ValueKey('compact'),
                day: day,
                isSelected: isSelected,
                eventColors: eventColors,
                lineSlotCount: lineSlotCount,
              ),
      ),
    );
  }
}

class _ExpandedDayCell extends StatelessWidget {
  const _ExpandedDayCell({
    required this.day,
    required this.isSelected,
    super.key,
  });

  final int day;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Center(
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: _DayNumber(day: day, isSelected: isSelected),
        ),
      ),
    );
  }
}

class _CompactDayCell extends StatelessWidget {
  const _CompactDayCell({
    required this.day,
    required this.isSelected,
    required this.eventColors,
    required this.lineSlotCount,
    super.key,
  });

  final int day;
  final bool isSelected;
  final List<Color> eventColors;
  final int lineSlotCount;

  @override
  Widget build(BuildContext context) {
    final dayNumber = _DayNumber(day: day, isSelected: isSelected);

    // 예약된 줄 자리 수([lineSlotCount], 박스 높이를 결정)는 그대로 두고,
    // 그 자리를 숫자 위아래로 나눠서 숫자가 항상 박스 가운데쯤 오도록
    // 만든다. 아래쪽 자리는 실제 일정 수만큼 색 줄로, 남는 자리는 투명한
    // 줄로 채운다.
    final topSlots = lineSlotCount ~/ 2;
    final bottomSlots = lineSlotCount - topSlots;
    final children = [
      for (var i = 0; i < topSlots; i++) const _BlankSlot(),
      dayNumber,
      for (var i = 0; i < bottomSlots; i++)
        _EventSlot(color: i < eventColors.length ? eventColors[i] : null),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _EventSlot extends StatelessWidget {
  const _EventSlot({required this.color});

  /// null이면 투명(자리만 차지).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 3),
      height: 2.5,
      decoration: BoxDecoration(
        color: color ?? Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _BlankSlot extends StatelessWidget {
  const _BlankSlot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 5.5);
  }
}

class _DayNumber extends StatelessWidget {
  const _DayNumber({required this.day, required this.isSelected});

  final int day;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$day',
      style: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontSize: 14,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
      ),
    );
  }
}
