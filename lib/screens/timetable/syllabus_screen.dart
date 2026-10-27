import 'package:flutter/material.dart';

import '../../services/course_catalog_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';

/// "강의계획서" 화면(상태 7).
///
/// *** 중요: 실제 강의계획서 API 미연동 ***
/// API 명세서(daejin-api-spec-reference)에 강의계획서 상세 조회 엔드포인트가
/// 언급돼 있지만, 이 작업 범위에서는 그 서비스가 아직 구현/제공되지 않았다
/// (lib/services/에 해당 서비스 파일 없음). 그래서 메타 정보는
/// [CourseCatalogItem]에 이미 있는 필드만 채우고, 거기 없는 값(학과/연구실/
/// 이메일/면담시간 등)은 지어내지 않고 아예 보여주지 않는다. 아래 아코디언 섹션들도 실제 강의계획서 본문 데이터가 없어
/// placeholder로만 남겨둔다.
class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key, required this.course});

  final CourseCatalogItem course;

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  int? _expandedIndex = 0;

  static const _sections = [
    ('수업의 개요와 유형', '수업 개요와 운영 방식이 들어가는 영역입니다.'),
    ('선수과목 및 선수과목 요건', '선수과목과 요건이 들어가는 영역입니다.'),
    ('핵심역량 및 수업목표', '핵심역량과 수업목표가 들어가는 영역입니다.'),
    ('주차별 수업계획', '주차별 수업계획이 들어가는 영역입니다.'),
    ('평가방법', '평가방법이 들어가는 영역입니다.'),
  ];

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.cobaltDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            '강의계획서',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 90),
                          child: Text(
                            course.courseName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.04,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${course.courseCode}-${course.section} · '
                          '${course.courseType} · '
                          '${_formatCredit(course.credit)}학점',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: MascotSticker(width: 76, angle: 0.08),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: ColoredBox(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      20,
                      20,
                      20 + MediaQuery.of(context).padding.bottom,
                    ),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _MetaCell('교수', course.professor),
                                _MetaCell('수업시간', course.rawSchedule),
                                _MetaCell(
                                  '학점 · 학년',
                                  '${_formatCredit(course.credit)}학점 · '
                                      '${course.targetGrade}',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _MetaCell('이수구분', course.courseType),
                                _MetaCell('강의실', course.room),
                                _MetaCell('정원', '${course.capacity}명'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _sections.length; i++) ...[
                        _AccordionSection(
                          number: i + 1,
                          title: _sections[i].$1,
                          body: _sections[i].$2,
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
      ? credit.toStringAsFixed(1)
      : credit.toString();
}

class _MetaCell extends StatelessWidget {
  const _MetaCell(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFF6B6B70), fontSize: 11),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccordionSection extends StatelessWidget {
  const _AccordionSection({
    required this.number,
    required this.title,
    required this.body,
    required this.expanded,
    required this.onTap,
  });

  final int number;
  final String title;
  final String body;
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
          color: expanded ? const Color(0xFFDCE6FB) : const Color(0xFFF1F1F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: expanded ? AppColors.cobalt : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: expanded ? Colors.white : AppColors.cobalt,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF6B6B70),
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  body,
                  style: const TextStyle(
                    color: Color(0xFF6B6B70),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
