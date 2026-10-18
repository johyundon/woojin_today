import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../grid_layout.dart';
import '../models/planned_course.dart';
import '../timetable_colors.dart';
import 'course_block.dart';

const double _hourLabelColumnWidth = 28;

/// 빈 셀 탭으로 만든 "미확정" 시간 선택. 탭 하나 = 1시간 블록으로 단순화했다
/// (Figma의 드래그 리사이즈 핸들은 구현하지 않음 — course_block.dart 참고).
class PendingSlot {
  const PendingSlot({required this.day, required this.startHour});

  final Weekday day;
  final int startHour;

  int get startMinutes => startHour * 60;
  int get endMinutes => (startHour + 1) * 60;
}

/// 월~금 × 8~22시 주간 시간표 그리드.
class TimetableGrid extends StatelessWidget {
  const TimetableGrid({
    required this.courses,
    required this.pendingSlot,
    required this.onEmptyCellTap,
    required this.onRemoveCourse,
    required this.onCourseTap,
    this.today,
    this.viewportHeight = 320,
  });

  final List<PlannedCourse> courses;
  final PendingSlot? pendingSlot;
  final void Function(Weekday day, int startHour) onEmptyCellTap;
  final ValueChanged<PlannedCourse> onRemoveCourse;
  final ValueChanged<PlannedCourse> onCourseTap;

  /// 오늘 요일. 월~금 밖(주말)이면 null — 요일 헤더에서 오늘 칸만 강조
  /// 표시하는 데 쓴다.
  final Weekday? today;

  /// 그리드(8~22시 전체 896px)에서 실제로 보여줄 스크롤 뷰포트 높이. 핸들
  /// 드래그로 조절하는 값을 받는다 — 기본값 320은 기존 고정값과 동일.
  final double viewportHeight;

  static const int _hourCount = gridEndHour - gridStartHour;
  static const double _gridHeight = _hourCount * gridHourRowHeight;

  @override
  Widget build(BuildContext context) {
    final layouts = buildBlockLayouts(courses);

    return _buildGridColumn(layouts);
  }

  Widget _buildGridColumn(List<CourseBlockLayout> layouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: _hourLabelColumnWidth),
            for (var i = 0; i < gridWeekdays.length; i++)
              Expanded(
                child: Center(
                  child: _WeekdayLabel(
                    label: weekdayLabelsWeekdaysOnly[i],
                    isToday: gridWeekdays[i] == today,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: viewportHeight,
          child: SingleChildScrollView(
            child: SizedBox(
              height: _gridHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columnWidth =
                      (constraints.maxWidth - _hourLabelColumnWidth) / 5;
                  return Stack(
                    children: [
                      _buildHourLabelsAndLines(columnWidth),
                      Positioned(
                        left: _hourLabelColumnWidth,
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTapUp: (details) => _handleTap(
                            details.localPosition,
                            columnWidth,
                            layouts,
                          ),
                        ),
                      ),
                      for (final layout in layouts)
                        _positionedBlock(layout, columnWidth),
                      if (pendingSlot != null)
                        _positionedPreview(pendingSlot!, columnWidth),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHourLabelsAndLines(double columnWidth) {
    return Column(
      children: [
        for (var hour = gridStartHour; hour < gridEndHour; hour++)
          SizedBox(
            height: gridHourRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _hourLabelColumnWidth,
                  child: Text(
                    '$hour',
                    style: const TextStyle(
                      color: TimetableColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: TimetableColors.gridLine),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _positionedBlock(CourseBlockLayout layout, double columnWidth) {
    final columnIndex = gridColumnIndexOf(layout.day)!;
    final top = _minutesToY(layout.startMinutes);
    final height = _minutesToY(layout.endMinutes) - top;
    return Positioned(
      left: _hourLabelColumnWidth + columnIndex * columnWidth,
      top: top,
      width: columnWidth,
      height: height,
      child: CourseBlock(
        layout: layout,
        onRemove: () => onRemoveCourse(layout.course),
        onTap: () => onCourseTap(layout.course),
      ),
    );
  }

  Widget _positionedPreview(PendingSlot slot, double columnWidth) {
    final columnIndex = gridColumnIndexOf(slot.day);
    if (columnIndex == null) return const SizedBox.shrink();
    final top = _minutesToY(slot.startMinutes);
    final height = _minutesToY(slot.endMinutes) - top;
    return Positioned(
      left: _hourLabelColumnWidth + columnIndex * columnWidth,
      top: top,
      width: columnWidth,
      height: height,
      child: const CourseBlockPreview(),
    );
  }

  double _minutesToY(int minutes) {
    return (minutes - gridStartHour * 60) / 60 * gridHourRowHeight;
  }

  void _handleTap(
    Offset localPosition,
    double columnWidth,
    List<CourseBlockLayout> layouts,
  ) {
    if (columnWidth <= 0) return;
    final columnIndex = (localPosition.dx / columnWidth).floor();
    if (columnIndex < 0 || columnIndex >= gridWeekdays.length) return;
    final day = gridWeekdays[columnIndex];

    final hour = gridStartHour + (localPosition.dy / gridHourRowHeight).floor();
    if (hour < gridStartHour || hour >= gridEndHour) return;

    final tapStart = hour * 60;
    final tapEnd = tapStart + 60;
    final overlapsExisting = layouts.any(
      (l) => l.day == day && l.startMinutes < tapEnd && l.endMinutes > tapStart,
    );
    // 이미 확정된 블록이 있는 칸이면 무시한다 — 지우려면 블록의 ×를 써야 한다.
    if (overlapsExisting) return;

    onEmptyCellTap(day, hour);
  }
}

/// 요일 헤더 글자 하나. 오늘이면 잉크색 알약 배경 + 라임색 글자로 강조한다.
class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.label, required this.isToday});

  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    if (!isToday) {
      return Text(
        label,
        style: const TextStyle(
          color: TimetableColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.ink,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.lime,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
