import 'package:flutter/material.dart';

import '../../../widgets/pressable.dart';
import '../grid_layout.dart';
import '../timetable_colors.dart';

/// 그리드 위의 색깔 강의 블록 하나. 우상단 ×로 (로컬) 삭제.
///
/// 주의: 이 ×는 "내가 짜고 있는 시간표 초안"에서만 빼는 것이다 — 실제 수강신청
/// 내역을 바꾸는 API는 명세서에 없어 호출하지 않는다.
class CourseBlock extends StatelessWidget {
  const CourseBlock({
    super.key,
    required this.layout,
    required this.onRemove,
    required this.onTap,
  });

  final CourseBlockLayout layout;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorForCourseKey(layout.course.key);
    final textColor = textColorOnBlock(color);
    return Pressable(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // 칸이 좁아(약 58) ×를 오른쪽 아래 구석에 띄워 과목명 폭을 뺏지
            // 않는다 — 과목명이 길면 2줄까지 보인다.
            Padding(
              padding: const EdgeInsets.all(5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 짧은 시간대로 블록 높이가 아주 작을 때 Text가 고정
                  // 크기를 요구하면 RenderFlex가 넘친다 — Flexible로 감싸
                  // 남는 공간만큼만 쓰게 한다.
                  Flexible(
                    child: Text(
                      layout.course.courseName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.36,
                        height: 1.4,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Opacity(
                      opacity: 0.9,
                      child: Text(
                        layout.course.room,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.36,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 3,
              right: 3,
              child: Pressable.icon(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 빈 셀을 탭했을 때 보여주는 점선 테두리 미리보기 블록(상태 10 단순화).
/// 드래그로 리사이즈하는 파란 핸들은 구현하지 않는다 — 탭 하나로 1시간
/// 미리보기를 만들고, 검색 결과에서 "시간표에 추가"를 눌러야 실제 블록으로
/// 확정된다.
class CourseBlockPreview extends StatelessWidget {
  const CourseBlockPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TimetableColors.accent, width: 1.5),
        color: TimetableColors.accent.withValues(alpha: 0.12),
      ),
    );
  }
}
