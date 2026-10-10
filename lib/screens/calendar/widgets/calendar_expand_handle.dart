import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 캘린더 그리드 바로 아래 있는 드래그 핸들. 아래로 당기면 확장 뷰(긴
/// 이름표 막대), 위로 당기면 압축 뷰(날짜 박스 + 요약 줄)로 전환한다(Figma
/// node 6:40 ↔ 6:44). 타임테이블 그리드 핸들과 달리 연속적인 높이 조절이
/// 아니라, 일정 거리 이상 당기면 바로 전환되는 토글 제스처다.
class CalendarExpandHandle extends StatefulWidget {
  const CalendarExpandHandle({
    required this.expanded,
    required this.onChanged,
    super.key,
  });

  final bool expanded;
  final ValueChanged<bool> onChanged;

  @override
  State<CalendarExpandHandle> createState() => _CalendarExpandHandleState();
}

class _CalendarExpandHandleState extends State<CalendarExpandHandle> {
  static const double _dragThreshold = 24;

  double _dragDistance = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onChanged(!widget.expanded),
        onVerticalDragStart: (_) => _dragDistance = 0,
        onVerticalDragUpdate: (details) {
          _dragDistance += details.delta.dy;
          if (!widget.expanded && _dragDistance > _dragThreshold) {
            _dragDistance = 0;
            widget.onChanged(true);
          } else if (widget.expanded && _dragDistance < -_dragThreshold) {
            _dragDistance = 0;
            widget.onChanged(false);
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: _HandleBar(),
        ),
      ),
    );
  }
}

class _HandleBar extends StatelessWidget {
  const _HandleBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
