import 'package:flutter/material.dart';

import '../grid_layout.dart';
import '../timetable_colors.dart';

/// 그리드 위의 색깔 강의 블록 하나. 우상단 ×로 (로컬) 삭제.
///
/// 주의: 이 ×는 "내가 짜고 있는 시간표 초안"에서만 빼는 것이다 — 실제 수강신청
/// 내역을 바꾸는 API는 명세서에 없어 호출하지 않는다.
class CourseBlock extends StatelessWidget {
  const CourseBlock({required this.layout, required this.onRemove});

  final CourseBlockLayout layout;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = colorForCourseKey(layout.course.key);
    return Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  layout.course.courseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${layout.course.room} · ${layout.course.section}분반',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

/// 빈 셀을 탭했을 때 보여주는 점선 테두리 미리보기 블록(상태 10 단순화).
/// 드래그로 리사이즈하는 파란 핸들은 구현하지 않는다 — 탭 하나로 1시간
/// 미리보기를 만들고, 검색 결과에서 "시간표에 추가"를 눌러야 실제 블록으로
/// 확정된다.
class CourseBlockPreview extends StatelessWidget {
  const CourseBlockPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TimetableColors.accent, width: 1.5),
        color: TimetableColors.accent.withValues(alpha: 0.12),
      ),
    );
  }
}
