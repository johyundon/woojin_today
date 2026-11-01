import 'package:flutter/material.dart';

import '../../services/course_catalog_service.dart';
import '../../services/service_factory.dart';
import '../../services/syllabus_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import '../../widgets/pressable.dart';

/// "강의계획서" 화면(상태 7).
///
/// [SyllabusService]로 학교 강의계획서를 불러와 위쪽 정보와 5칸(개요,
/// 선수과목, 핵심역량·수업목표, 주별 수업계획, 평가방법)을 채운다. 불러오기
/// 전에는 [CourseCatalogItem]에 있는 값만 보여준다. 교양선택처럼 강의계획서를
/// 찾을 방법이 없는 과목은 그 사실만 안내한다(다시 시도 없음).
class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({
    super.key,
    required this.course,
    required this.year,
    required this.semester,
    this.jsessionId,
    this.wmonid,
    this.userId2,
    this.syllabusService,
  });

  final CourseCatalogItem course;
  final int year;
  final int semester;
  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  /// 테스트에서 가짜 서비스를 넣기 위한 옵션.
  final SyllabusServiceBase? syllabusService;

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  int? _expandedIndex = 0;

  late final SyllabusServiceBase _service;
  SyllabusDetail? _detail;
  bool _loading = false;
  String? _error;

  /// true면 다시 시도해도 결과가 같은 실패(교양선택, 세션 없음 등).
  bool _unavailable = false;

  @override
  void initState() {
    super.initState();
    _service = widget.syllabusService ?? ServiceFactory.syllabus();
    _load();
  }

  Future<void> _load() async {
    final jsessionId = widget.jsessionId;
    final wmonid = widget.wmonid;
    final userId2 = widget.userId2;
    if (jsessionId == null || wmonid == null || userId2 == null) {
      setState(() {
        _error = '로그인 정보가 없어 강의계획서를 불러올 수 없어요.';
        _unavailable = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _service.fetchSyllabus(
        course: widget.course,
        year: widget.year,
        semester: widget.semester,
        jsessionId: jsessionId,
        wmonid: wmonid,
        userId2: userId2,
      );
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on SyllabusUnavailableException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
        _unavailable = true;
      });
    } catch (e) {
      debugPrint('[Syllabus] 조회 실패: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '강의계획서를 불러오지 못했어요.';
      });
    }
  }

  /// 학년은 개설과목의 대상학년, 없으면 강의계획서의 수강대상을 쓴다.
  String _creditAndGrade(CourseCatalogItem course) {
    final grade = course.targetGrade.isNotEmpty
        ? course.targetGrade
        : _detail?.info('수강대상');
    final credit = '${_formatCredit(course.credit)}학점';
    return grade == null ? credit : '$credit · $grade';
  }

  List<Widget> _buildBody() {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.cobalt),
          ),
        ),
      ];
    }
    final error = _error;
    if (error != null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B6B70), fontSize: 13),
              ),
              if (!_unavailable) ...[
                const SizedBox(height: 8),
                Pressable.effect(
                  child: TextButton(
                    onPressed: _load,
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ];
    }
    final detail = _detail;
    if (detail == null) return const [];

    final sections = _syllabusSections(detail);
    return [
      for (var i = 0; i < sections.length; i++) ...[
        _AccordionSection(
          number: i + 1,
          title: sections[i].$1,
          body: sections[i].$2,
          expanded: _expandedIndex == i,
          onTap: () => setState(() {
            _expandedIndex = _expandedIndex == i ? null : i;
          }),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

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
                        Pressable.icon(
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
                                _MetaCell(
                                  '교수',
                                  _detail?.info('담당교수') ?? course.professor,
                                ),
                                _MetaCell(
                                  '수업시간',
                                  _detail?.info('수업시간') ?? course.rawSchedule,
                                ),
                                _MetaCell('학점 · 학년', _creditAndGrade(course)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              children: [
                                _MetaCell('이수구분', course.courseType),
                                _MetaCell(
                                  '강의실',
                                  _detail?.info('수업장소') ?? course.room,
                                ),
                                // 내 시간표에서 온 과목은 정원 값이 없다(0).
                                if (course.capacity > 0)
                                  _MetaCell('정원', '${course.capacity}명'),
                                // 연구실은 정원과 상관없이, 강의계획서에 값이
                                // 있으면 항상 보여준다.
                                if (_detail?.info('연구실') case final room?)
                                  _MetaCell('연구실', room),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._buildBody(),
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


/// 디자인의 5칸에 맞춰 강의계획서 절을 고르고 글로 옮긴다. 제목은 실제
/// 강의계획서의 절 제목(번호 제외)을 쓴다. 내용이 없으면 "내용 없음".
List<(String, String)> _syllabusSections(SyllabusDetail detail) {
  String titleOf(String prefix, String fallback) {
    final title = detail.section(prefix)?.title;
    if (title == null) return fallback;
    return title.replaceFirst(RegExp(r'^\d+(-\d+\))?[.)]?\s*'), '');
  }

  String orEmpty(String text) => text.trim().isEmpty ? '내용 없음' : text;

  final competencies = detail.section('3-1)')?.competencies ?? const [];
  final weeks = detail.section('10.')?.weeks ?? const [];
  // 반영비율 0%인 평가요소는 실제로 쓰지 않으므로 뺀다.
  final evaluations = (detail.section('7.')?.evaluations ?? const [])
      .where((e) => e.ratio != '0%');

  return [
    (
      titleOf('1.', '수업의 개요와 유용성'),
      orEmpty(detail.section('1.')?.bodyText ?? ''),
    ),
    (
      titleOf('2.', '선행학습 및 선수과목 요건'),
      orEmpty(detail.section('2.')?.bodyText ?? ''),
    ),
    (
      titleOf('3-1)', '핵심역량 및 수업목표'),
      orEmpty(
        competencies
            .map((c) => '${c.name} · ${c.ratio}\n${c.goal}')
            .join('\n\n'),
      ),
    ),
    (
      titleOf('10.', '주별 수업계획'),
      orEmpty(
        weeks
            .map(
              (w) => [
                '${w.week}주차 · ${w.topic}',
                if (w.content.isNotEmpty) w.content,
              ].join('\n'),
            )
            .join('\n\n'),
      ),
    ),
    (
      titleOf('7.', '학습 평가방법'),
      orEmpty(
        evaluations
            .map(
              (e) => e.detail.isEmpty
                  ? '${e.name} ${e.ratio}'
                  : '${e.name} ${e.ratio} — ${e.detail}',
            )
            .join('\n'),
      ),
    ),
  ];
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
    return Pressable(
      pressedScale: 0.98,
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
