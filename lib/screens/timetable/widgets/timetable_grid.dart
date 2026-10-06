import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../grid_layout.dart';
import '../models/planned_course.dart';
import '../timetable_colors.dart';
import 'course_block.dart';

const List<String> _weekdayLabels = ['월', '화', '수', '목', '금'];
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
    required this.onAutoFill,
    this.viewportHeight = 320,
  });

  final List<PlannedCourse> courses;
  final PendingSlot? pendingSlot;
  final void Function(Weekday day, int startHour) onEmptyCellTap;
  final ValueChanged<PlannedCourse> onRemoveCourse;

  /// 그리드(8~22시 전체 896px)에서 실제로 보여줄 스크롤 뷰포트 높이. 핸들
  /// 드래그로 조절하는 값을 받는다 — 기본값 320은 기존 고정값과 동일.
  final double viewportHeight;

  /// 그리드 우상단(금요일 열 위)에 뜨는 플로팅 반짝이(AI) 버튼 탭 콜백 —
  /// 규칙 기반 자동 시간표 추천을 실행한다.
  final VoidCallback onAutoFill;

  static const int _hourCount = gridEndHour - gridStartHour;
  static const double _gridHeight = _hourCount * gridHourRowHeight;

  static const double _autoFillButtonSize = 40;

  @override
  Widget build(BuildContext context) {
    final layouts = buildBlockLayouts(courses);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildGridColumn(layouts),
        Positioned(
          // 요일 헤더 줄 바로 아래, 그리드 오른쪽(금요일 열) 위에
          // 뜨는 플로팅 버튼 — 스크롤돼도 같이 움직이지 않고 늘 같은 자리에
          // 떠 있어야 해서(사용자 피드백) 스크롤 영역 밖(이 Stack)에 둔다.
          top: 30,
          right: 0,
          child: _AutoFillFloatingButton(
            size: _autoFillButtonSize,
            onTap: onAutoFill,
          ),
        ),
      ],
    );
  }

  Widget _buildGridColumn(List<CourseBlockLayout> layouts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: _hourLabelColumnWidth),
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: TimetableColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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

/// 자동 시간표 추천을 실행하는 플로팅 버튼. Figma 시안처럼 배경 도형 없이,
/// 흰색→보라 그라데이션 큰 반짝이(+글리프에 포함된 겹치는 작은 별)와
/// 파랑/핑크 작은 반짝이 포인트 2개만 띄운다.
class _AutoFillFloatingButton extends StatelessWidget {
  const _AutoFillFloatingButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Icons.auto_awesome 글리프 자체가 "큰 별 + 겹치는 작은 별"
            // 묶음이라 하나만 써도 Figma의 주 반짝이 모양과 같다. ShaderMask로
            // 흰색(왼쪽 위)->보라(오른쪽 아래) 그라데이션을 입힌다.
            Positioned(
              right: 0,
              top: 2,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFB39DDB)],
                ).createShader(bounds),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            // 작은 포인트 2개는 Icons.auto_awesome(큰별+작은별 묶음) 대신
            // 직접 그린 단일 4각 별로 — 묶음 글리프는 작게 쓰면 보조 별이
            // 덧붙어 보여서 원본의 "얇은 별 1개" 느낌과 달라진다.
            const Positioned(
              right: 25,
              top: 0,
              child: _SparkleStar(size: 10, color: Color(0xFF4FC3F7)),
            ),
            const Positioned(
              right: 11,
              top: 27,
              child: _SparkleStar(size: 8, color: Color(0xFFFF5C8A)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 얇고 뾰족한 4각 별(sparkle) 한 개. Icons.auto_awesome은 큰별+작은별
/// 묶음 글리프라 아주 작게 쓰면 원본과 실루엣이 달라져서, 꼭짓점 4개를
/// 오목한 곡선으로 잇는 별 하나를 직접 그린다.
class _SparkleStar extends StatelessWidget {
  const _SparkleStar({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _SparkleStarPainter(color),
    );
  }
}

class _SparkleStarPainter extends CustomPainter {
  const _SparkleStarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    // 중심 쪽으로 오목하게 들어가는 정도 — 작을수록 꼭짓점이 더 얇고 뾰족함.
    final pinch = size.width * 0.04;

    final path = Path()
      ..moveTo(cx, 0)
      ..quadraticBezierTo(cx + pinch, cy - pinch, size.width, cy)
      ..quadraticBezierTo(cx + pinch, cy + pinch, cx, size.height)
      ..quadraticBezierTo(cx - pinch, cy + pinch, 0, cy)
      ..quadraticBezierTo(cx - pinch, cy - pinch, cx, 0)
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkleStarPainter oldDelegate) =>
      oldDelegate.color != color;
}
