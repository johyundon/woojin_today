import 'package:flutter/material.dart';

import '../../services/course_catalog_service.dart';
import 'timetable_colors.dart';

/// "강의계획서" 화면(상태 7).
///
/// *** 중요: 실제 강의계획서 API 미연동 ***
/// API 명세서(daejin-api-spec-reference)에 강의계획서 상세 조회 엔드포인트가
/// 언급돼 있지만, 이 작업 범위에서는 그 서비스가 아직 구현/제공되지 않았다
/// (lib/services/에 해당 서비스 파일 없음). 그래서 메타 정보 표는
/// [CourseCatalogItem]에 이미 있는 필드만 채우고, 거기 없는 값(영문 과목명/
/// 연구실/이메일/면담시간/강의/실습 시수 등)은 지어내지 않고 "정보 없음"으로
/// 표시한다. 아래 아코디언 섹션들도 실제 강의계획서 본문 데이터가 없어
/// placeholder로만 남겨둔다.
class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({required this.course});

  final CourseCatalogItem course;

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  int? _expandedIndex = 0;

  static const _sections = [
    '1. 수업의 개요와 유용성',
    '2. 선행학습 및 선수과목 요건',
    '3. 핵심역량 및 수업목표',
    '4. 수업 운영 및 평가 방법',
  ];

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      backgroundColor: TimetableColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: TimetableColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    '강의계획서',
                    style: TextStyle(
                      color: TimetableColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TimetableColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _MetaRow('교과목명(국문)', course.courseName),
                        _MetaRow('교과목명(영문)', '정보 없음'),
                        _MetaRow('교과구분', course.courseType),
                        _MetaRow(
                          '교과번호-분반',
                          '${course.courseCode}-${course.section}',
                        ),
                        _MetaRow('수업시간', course.rawSchedule),
                        _MetaRow('수업장소', course.room),
                        _MetaRow('수강대상', course.targetGrade),
                        _MetaRow(
                          '학점/강의/실습',
                          '${_formatCredit(course.credit)}/정보 없음/정보 없음',
                        ),
                        _MetaRow('담당교수', course.professor),
                        _MetaRow('연구실', '정보 없음'),
                        _MetaRow('연락처 Email', '정보 없음'),
                        _MetaRow('수업관련 면담시간', '정보 없음'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < _sections.length; i++) ...[
                    _AccordionSection(
                      title: _sections[i],
                      expanded: _expandedIndex == i,
                      onTap: () => setState(() {
                        _expandedIndex = _expandedIndex == i ? null : i;
                      }),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
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

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.title,
    required this.expanded,
    required this.onTap,
  });

  final String title;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TimetableColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: TimetableColors.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: TimetableColors.textSecondary,
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              const Text(
                '강의계획서 상세 조회 API가 아직 연동되지 않아 실제 본문을 '
                '보여줄 수 없어요.',
                style: TextStyle(
                  color: TimetableColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
