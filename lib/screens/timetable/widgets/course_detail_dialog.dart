import 'package:flutter/material.dart';

import '../../../services/course_catalog_service.dart';
import '../../../utils/credit_format.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// 과목 상세 다이얼로그(상태 6). "닫기" / "강의계획서 보기" 두 버튼.
///
/// 원본 디자인(상태 6)의 "학과" 행은 개설학과([CourseCatalogItem.department])가
/// 있을 때만 보여준다. 내 시간표에서 불러온 과목에만 있고, 개설과목 검색 결과나
/// 예전에 저장한 시간표에는 없다 — 없는 데이터를 지어내지 않기 위함.
class CourseDetailDialog extends StatelessWidget {
  const CourseDetailDialog({
    super.key,
    required this.course,
    required this.onViewSyllabus,
  });

  final CourseCatalogItem course;
  final VoidCallback onViewSyllabus;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TimetableColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseName,
              style: const TextStyle(
                color: TimetableColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${course.courseCode}-${course.section}',
              style: const TextStyle(
                color: TimetableColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            if (course.department case final department?
                when department.isNotEmpty)
              _Row('학과', department),
            _Row('교수', course.professor),
            _Row('이수구분', course.courseType),
            _Row('학점', formatCredit(course.credit)),
            _Row('학년', course.targetGrade),
            _Row('시간', course.rawSchedule),
            _Row('강의실', course.room),
            _Row('담은인원', course.enrollmentRatio),
            _Row('비고', course.note ?? '-'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Pressable.effect(
                pressedScale: 0.97,
                child: ElevatedButton(
                  onPressed: onViewSyllabus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TimetableColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '강의계획서 보기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Pressable.effect(
                pressedScale: 0.97,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TimetableColors.textPrimary,
                    side: const BorderSide(color: TimetableColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    '닫기',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: TimetableColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: TimetableColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
