import 'package:flutter/material.dart';

import '../../../services/course_catalog_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/credit_format.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// 과목 상세 팝업(v7 디자인 25). "닫기"(파랑) / "강의계획서 보기"(회색 바탕) 두 버튼.
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
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.courseName,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${course.courseCode}-${course.section}',
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            _Row('교수', course.professor),
            _Row('이수구분', course.courseType),
            if (course.department case final department?
                when department.isNotEmpty)
              _Row('학과', department),
            _Row('학점', formatCredit(course.credit)),
            _Row('학년', course.targetGrade),
            _Row('시간', course.rawSchedule),
            _Row('강의실', course.room),
            _Row('담은인원', course.enrollmentRatio),
            _Row('비고', course.note ?? '-'),
            const SizedBox(height: 13),
            _DialogButton(
              label: '닫기',
              background: AppColors.blue,
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 8),
            _DialogButton(
              label: '강의계획서 보기',
              background: AppColors.fill,
              textStyle: const TextStyle(
                color: AppColors.blue,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              onTap: onViewSyllabus,
            ),
          ],
        ),
      ),
    );
  }
}

/// 팝업 아래 큰 버튼(높이 52, 모서리 16).
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.textStyle,
    required this.onTap,
  });

  final String label;
  final Color background;
  final TextStyle textStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.97,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}

/// 표 한 줄: 왼쪽 이름(12/600 회색) · 오른쪽 값(12/700 진한 글자), 아래 옅은 줄.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TimetableColors.detailRowLine),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
