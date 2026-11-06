import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/course_catalog_service.dart';
import '../../services/department_codes.dart';
import '../../services/service_factory.dart';
import '../../services/session_cache.dart';
import '../../services/student_info_service.dart';
import '../../services/syllabus_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import 'timetable_colors.dart';

/// "강의계획서" 화면(상태 7).
///
/// [SyllabusService]로 학교 강의계획서를 불러와 위쪽 정보와 5칸(개요,
/// 선수과목, 핵심역량·수업목표, 주별 수업계획, 평가방법)을 채운다. 불러오기
/// 전에는 [CourseCatalogItem]에 있는 값만 보여준다. 다른 학과 전공처럼 강의계획서를
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
    this.studentInfoService,
  });

  final CourseCatalogItem course;
  final int year;
  final int semester;
  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  /// 테스트에서 가짜 서비스를 넣기 위한 옵션.
  final SyllabusServiceBase? syllabusService;

  /// 테스트에서 가짜 학생 정보(내 학과)를 넣기 위한 옵션.
  final StudentInfoServiceBase? studentInfoService;

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
    final myDepartment = await _myDepartmentIfNeeded(userId2);
    final course = myDepartment == null
        ? widget.course
        : widget.course.withDepartment(myDepartment);
    try {
      final detail = await _service.fetchSyllabus(
        course: course,
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
        // 내 학과 목록에서 찾았는데 없으면 다른 학과 전공 과목이다.
        _error = myDepartment == null
            ? e.message
            : '$myDepartment 전공 목록에 없는 과목이에요.\n'
                  '다른 학과 전공 과목은 아직 강의계획서를 열 수 없어요.';
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

  /// 개설학과를 모르는 전공 과목("과목 추가" 목록에서 고른 과목)이면, 로그인한
  /// 학생의 학과 이름을 돌려준다. 학생들이 주로 고르는 과목이 자기 전공이라
  /// 그 학과 전공 목록에서 먼저 찾는다. 해당 없거나 못 읽으면 null.
  ///
  /// 학생 정보는 홈에서 이미 불러와 [SessionCache]에 있으므로 보통 새 요청이 없다.
  Future<String?> _myDepartmentIfNeeded(String userId2) async {
    final course = widget.course;
    final hasDepartment = (course.department?.trim() ?? '').isNotEmpty;
    if (hasDepartment || !course.courseType.trim().startsWith('전')) {
      return null;
    }
    try {
      final info = await SessionCache.getStudentInfo(
        widget.studentInfoService ?? ServiceFactory.studentInfo(),
        userId2: userId2,
      );
      return matchDepartmentName(info.department);
    } catch (e) {
      debugPrint('[Syllabus] 내 학과 읽기 실패: $e');
      return null;
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
            child: CircularProgressIndicator(color: AppColors.blue),
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
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
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
        const SizedBox(height: 12),
      ],
    ];
  }

  /// 위쪽 정보 칸들. 디자인 순서(교수·이수구분 / 학과·학점학년 / 수업시간·강의실)로
  /// 두 칸씩 놓는다. 학과는 값이 있을 때만, 정원은 내 시간표에서 온 과목(0)이
  /// 아닐 때만 보여준다.
  List<Widget> _metaRows(CourseCatalogItem course) {
    final department = course.department?.trim() ?? '';
    final cells = [
      _MetaCell('교수', _detail?.info('담당교수') ?? course.professor),
      _MetaCell('이수구분', course.courseType),
      if (department.isNotEmpty) _MetaCell('학과', department),
      _MetaCell('학점 · 학년', _creditAndGrade(course)),
      _MetaCell('수업시간', _detail?.info('수업시간') ?? course.rawSchedule),
      _MetaCell('강의실', _detail?.info('수업장소') ?? course.room),
      if (course.capacity > 0) _MetaCell('정원', '${course.capacity}명'),
    ];
    return [
      for (var i = 0; i < cells.length; i += 2)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: cells[i]),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < cells.length
                    ? cells[i + 1]
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                child: Pressable.icon(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textStrong,
                      size: 15,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '강의계획서',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.96,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${course.courseCode}-${course.section} · '
                      '${course.courseType} · '
                      '${_formatCredit(course.credit)}학점',
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    boxShadow: TimetableColors.sheetShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(36),
                    ),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        18,
                        22,
                        18,
                        20 + MediaQuery.of(context).padding.bottom,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 2, 4, 6),
                          child: Column(children: _metaRows(course)),
                        ),
                        const SizedBox(height: 12),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: TimetableColors.rowLine,
                        ),
                        const SizedBox(height: 12),
                        ..._buildBody(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
  final evaluations = (detail.section('7.')?.evaluations ?? const []).where(
    (e) => e.ratio != '0%',
  );

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
    return Column(
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
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textStrong,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: expanded ? AppColors.blueSoft : AppColors.fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: expanded ? AppColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: expanded ? Colors.white : AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.28,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.textSub,
                  size: 19,
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
                    color: SyllabusColors.bodyText,
                    fontSize: 12.5,
                    height: 1.4,
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
