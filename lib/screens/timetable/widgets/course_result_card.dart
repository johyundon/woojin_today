import 'package:flutter/material.dart';

import '../../../services/course_catalog_service.dart';
import '../timetable_colors.dart';

/// 검색 결과 카드 하나.
///
/// 카드 전체를 탭하면 [onAdd](시간표에 바로 추가)가 실행된다. 상세 정보는
/// 별도로 둔 정보 아이콘([onViewDetail])으로 들어간다.
///
/// [showAddButtons]가 true면(그리드 빈 셀을 탭해 특정 요일/시간을 선택한
/// 상태에서 그 시간대와 겹치는 과목일 때) 하단에도 "시간표에 추가"/"상세보기"
/// 버튼을 보여준다(상태 10).
class CourseResultCard extends StatelessWidget {
  const CourseResultCard({
    required this.course,
    required this.onAdd,
    required this.onViewDetail,
    required this.showAddButtons,
  });

  final CourseCatalogItem course;
  final VoidCallback onAdd;
  final VoidCallback onViewDetail;
  final bool showAddButtons;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TimetableColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    course.courseName,
                    style: const TextStyle(
                      color: TimetableColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '담은인원 ${course.enrollmentRatio}',
                  style: const TextStyle(
                    color: TimetableColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onViewDetail,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: TimetableColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${course.professor} · ${_formatCredit(course.credit)}학점 · ${course.courseType}',
              style: const TextStyle(
                color: TimetableColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${course.rawSchedule} · ${course.room}',
              style: const TextStyle(
                color: TimetableColors.textSecondary,
                fontSize: 12,
              ),
            ),
            if (showAddButtons) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAdd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TimetableColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '시간표에 추가',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onViewDetail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TimetableColors.textPrimary,
                        side: const BorderSide(color: TimetableColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        '상세보기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formatCredit(double credit) {
  return credit == credit.roundToDouble()
      ? credit.toInt().toString()
      : credit.toString();
}
