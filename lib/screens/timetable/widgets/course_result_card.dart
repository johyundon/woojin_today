import 'package:flutter/material.dart';

import '../../../services/course_catalog_service.dart';
import '../../../utils/credit_format.dart';
import '../timetable_colors.dart';

/// 과목 추가 패널의 검색 결과 한 줄.
///
/// 오른쪽 "담기" 버튼이 시간표에 바로 추가([onAdd])하고, 줄 자체를 탭하면
/// 상세 정보([onViewDetail])가 열린다.
class CourseResultCard extends StatelessWidget {
  const CourseResultCard({
    super.key,
    required this.course,
    required this.onAdd,
    required this.onViewDetail,
  });

  final CourseCatalogItem course;
  final VoidCallback onAdd;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onViewDetail,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TimetableColors.gridLine)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseName,
                    style: const TextStyle(
                      color: TimetableColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${course.professor} · ${formatCredit(course.credit)}학점 · ${course.courseType}',
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '담은인원 ${course.enrollmentRatio}',
                  style: const TextStyle(
                    color: TimetableColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCE6FF),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      '담기',
                      style: TextStyle(
                        color: TimetableColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
