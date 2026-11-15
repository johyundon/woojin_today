import 'package:flutter/material.dart';

import '../../../services/course_catalog_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/credit_format.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// "시간표 만들기" 시트의 과목 한 줄(Figma 2272-19176, 2026-11-16).
///
/// 왼쪽에 과목명·교수·학점·영역·시간·강의실, 오른쪽에 담은인원·경쟁률. 줄을
/// 누르면 팝업 대신 그 자리에서 펼쳐져 "담기"·"강의계획서" 버튼이 나온다.
class CourseResultTile extends StatelessWidget {
  const CourseResultTile({
    super.key,
    required this.course,
    required this.expanded,
    required this.alreadyAdded,
    required this.onTap,
    required this.onAdd,
    required this.onViewSyllabus,
    this.highlighted = false,
  });

  final CourseCatalogItem course;
  final bool expanded;

  /// 이미 시간표에 담긴 과목이면 "담기" 대신 "담음"(누를 수 없음).
  final bool alreadyAdded;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onViewSyllabus;

  /// 시간표 격자에서 눌러 고른 과목이면 회색 바탕으로 눈에 띄게 한다
  /// (사용자 요청, 2026-11-16).
  final bool highlighted;

  /// 경쟁률(담은 인원 ÷ 정원). 정원을 모르면 null.
  String? get _competition {
    if (course.capacity <= 0) return null;
    return '${(course.waitlistCount / course.capacity).toStringAsFixed(1)}:1';
  }

  @override
  Widget build(BuildContext context) {
    const sub = TextStyle(
      color: AppColors.textSub,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
    final competition = _competition;
    // 개설과목 목록 값이 있으면 그걸, 없으면(내 시간표 과목) 담은 인원/정원으로.
    final enrollment = course.enrollmentRatio.trim().isNotEmpty
        ? course.enrollmentRatio
        : course.capacity > 0
        ? '${course.waitlistCount}/${course.capacity}명'
        : null;
    return Container(
      decoration: highlighted
          ? BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(12),
            )
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: TimetableColors.rowLine),
              ),
            ),
      padding: highlighted
          ? const EdgeInsets.all(14)
          : const EdgeInsets.symmetric(vertical: 14),
      margin: highlighted ? const EdgeInsets.only(top: 8) : EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Pressable(
            pressedScale: 0.98,
            onTap: onTap,
            child: Container(
              color: Colors.transparent,
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
                            color: AppColors.textStrong,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${course.professor} · '
                          '${formatCredit(course.credit)}학점 · '
                          '${course.courseType}',
                          style: sub,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.rawSchedule} · ${course.room}',
                          style: sub.copyWith(color: AppColors.textBody),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (enrollment != null)
                        Text('담은인원 $enrollment', style: sub),
                      if (competition != null)
                        Text('경쟁률 $competition', style: sub),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Pressable(
                  key: const ValueKey('course-tile-add'),
                  enabled: !alreadyAdded,
                  pressedScale: 0.93,
                  onTap: alreadyAdded ? null : onAdd,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: alreadyAdded
                          ? AppColors.fillDisabled
                          : AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alreadyAdded ? '담음' : '담기',
                      style: TextStyle(
                        color: alreadyAdded
                            ? AppColors.textMuted
                            : AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Pressable(
                  key: const ValueKey('course-tile-syllabus'),
                  pressedScale: 0.93,
                  onTap: onViewSyllabus,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.checkLine),
                    ),
                    child: const Text(
                      '강의계획서',
                      style: TextStyle(
                        color: AppColors.textBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
