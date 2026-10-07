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
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          // ×가 오른쪽 위에 떠 있는 배지라 과목명 폭을 뺏지 않는다(겹치는
          // 부분만큼만 오른쪽 여백을 둔다) — 과목명이 길면 2줄까지 보인다.
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 짧은 시간대로 블록 높이가 아주 작을 때 Text가 고정 크기를
                // 요구하면 RenderFlex가 넘친다 — Flexible로 감싸 남는
                // 공간만큼만 쓰게 한다.
                Flexible(
                  child: Text(
                    layout.course.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    '${layout.course.room} · ${layout.course.section}분반',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 10,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
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
