import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/time_format.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/mascot_sticker.dart';
import '../grid_layout.dart';
import '../models/ai_recommend_answers.dart';
import '../models/planned_course.dart';
import '../timetable_colors.dart';

const List<String> _weekdayFullNames = ['월요일', '화요일', '수요일', '목요일', '금요일'];
const double _hourLabelColumnWidth = 22;

/// "AI 시간표 자동 생성" 결과 미리보기 (Figma node 6:59, node-id 6:65 — 스크린샷
/// 6장 중 마지막 1장).
///
/// 이 노드는 실제 Figma 벡터 레이어가 아니라 앱 스크린샷이 평탄화된 상태라
/// `get_design_context`로 쓸만한 코드를 뽑을 수 없었다. 스크린샷을 눈으로 보고
/// 레이아웃/색상/간격을 근사해 재현했다. 추천 알고리즘/데이터 조회는 이 화면의
/// 책임이 아니라 [onRegenerate]/[onConfirm] 콜백으로 호출부에 위임한다.
class AiRecommendResultScreen extends StatefulWidget {
  const AiRecommendResultScreen({
    required this.candidates,
    required this.answers,
    required this.onRegenerate,
    required this.onConfirm,
    super.key,
  });

  /// 생성된 후보 시간표 목록(보통 3개). 각 원소가 "시간표 하나"(과목 리스트).
  final List<List<PlannedCourse>> candidates;

  /// 설문 답변. "금요일 공강"/"오후 위주"/"전공 100%" 같은 조건 요약 칩과,
  /// 그리드의 공강 요일 강조 표시에 쓴다.
  final AiRecommendAnswers answers;

  /// "다시 추천" 탭 — 새 후보들을 다시 받아와야 해서 호출부로 위임한다
  /// (이 화면은 스스로 재생성 로직을 모른다). 비동기로 새 후보 리스트를
  /// 돌려주면 이 화면이 그걸로 내부 상태(candidates)를 교체해서 다시
  /// 보여준다.
  final Future<List<List<PlannedCourse>>> Function() onRegenerate;

  /// "이 시간표 할래요" 탭 — 지금 보고 있는 페이지의 후보(`List<PlannedCourse>`)를
  /// 넘겨준다. 실제로 메인 시간표에 반영하는 건 호출부 책임이다.
  final ValueChanged<List<PlannedCourse>> onConfirm;

  @override
  State<AiRecommendResultScreen> createState() =>
      _AiRecommendResultScreenState();
}

class _AiRecommendResultScreenState extends State<AiRecommendResultScreen> {
  late List<List<PlannedCourse>> _candidates;
  final _pageController = PageController();
  int _currentIndex = 0;
  bool _regenerating = false;

  @override
  void initState() {
    super.initState();
    _candidates = widget.candidates;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onRegenerate() async {
    if (_regenerating) return;
    setState(() => _regenerating = true);
    try {
      final result = await widget.onRegenerate();
      if (!mounted) return;
      setState(() {
        _candidates = result;
        _currentIndex = 0;
      });
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  void _onConfirm() {
    widget.onConfirm(_candidates[_currentIndex]);
  }

  /// [freeDayMode]가 특정 요일 지정이면 그 요일, 아니면 null(그리드에서
  /// "공강" 강조를 안 한다).
  Weekday? get _freeDay {
    final answers = widget.answers;
    return answers.freeDayMode == FreeDayMode.specificDay
        ? answers.specificFreeDay
        : null;
  }

  /// 상단 조건 요약 칩("금요일 공강"/"오후 위주"/"전공 100%"). "상관없어요"로
  /// 답한 항목은 보여줄 조건이 없어 칩에서 뺀다.
  List<String> get _conditionChips {
    final answers = widget.answers;
    final chips = <String>[];

    switch (answers.freeDayMode) {
      case FreeDayMode.specificDay:
        final day = answers.specificFreeDay;
        final index = day == null ? -1 : Weekday.values.indexOf(day);
        if (index >= 0 && index < _weekdayFullNames.length) {
          chips.add('${_weekdayFullNames[index]} 공강');
        }
      case FreeDayMode.anyDaysCount:
        chips.add('공강 ${answers.anyFreeDaysCount}일');
      case FreeDayMode.any:
        break;
    }

    switch (answers.timePreference) {
      case TimePreference.morning:
        chips.add('오전 위주');
      case TimePreference.afternoon:
        chips.add('오후 위주');
      case TimePreference.mixed:
        chips.add('오전/오후 섞어서');
      case TimePreference.any:
        break;
    }

    if (!answers.majorRatioAny) {
      chips.add('전공 ${answers.majorRatio.round()}%');
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final hasCandidates = _candidates.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: _TopBar(
                hasCandidates: _candidates.isNotEmpty,
                regenerating: _regenerating,
                onRegenerate: _onRegenerate,
              ),
            ),
            if (!hasCandidates)
              const Expanded(
                child: Center(
                  child: Text(
                    '조건에 맞는 시간표를 찾지 못했어요',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '총 ${_formatCredit(_totalCredit(_candidates[_currentIndex]))}학점 · '
                            '${_candidates[_currentIndex].length}과목',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.only(right: 90),
                          child: Text(
                            '이 시간표\n어때?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.02,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Positioned(
                      right: 0,
                      top: -4,
                      child: MascotSticker(width: 76, angle: 0.08),
                    ),
                  ],
                ),
              ),
              if (_conditionChips.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final chip in _conditionChips) ...[
                          _ConditionChip(chip),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: ColoredBox(
                      color: Colors.white,
                      child: Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: _candidates.length,
                              onPageChanged: (index) =>
                                  setState(() => _currentIndex = index),
                              itemBuilder: (context, index) => _CandidateGrid(
                                courses: _candidates[index],
                                freeDay: _freeDay,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              20,
                              16,
                              20,
                              20 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 92,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cobaltDeep.withValues(
                                          alpha: 0.35,
                                        ),
                                        offset: const Offset(0, 6),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cobaltDeep,
                                      shape: const StadiumBorder(),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      '< 이전',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(26),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.ink.withValues(
                                            alpha: 0.25,
                                          ),
                                          offset: const Offset(0, 6),
                                          blurRadius: 14,
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _onConfirm,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.lime,
                                        shape: const StadiumBorder(),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        '이 시간표 할래요',
                                        style: TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

double _totalCredit(List<PlannedCourse> courses) {
  return courses.fold(0.0, (sum, course) => sum + course.credit);
}

/// 18.0 같은 정수 학점은 소수점 없이, 18.5처럼 소수가 있으면 한 자리까지.
String _formatCredit(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

/// X 닫기 + "↻ 다시 추천" 버튼으로 이뤄진 상단 바.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.hasCandidates,
    required this.regenerating,
    required this.onRegenerate,
  });

  final bool hasCandidates;
  final bool regenerating;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            child: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ),
        const Spacer(),
        if (hasCandidates)
          _RegenerateButton(
            label: '다시 추천',
            loading: regenerating,
            onTap: onRegenerate,
          ),
      ],
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.lime,
          borderRadius: BorderRadius.circular(99),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.ink,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, color: AppColors.ink, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    label,
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

/// 조건 요약 칩 하나("금요일 공강", "오후 위주" 등).
class _ConditionChip extends StatelessWidget {
  const _ConditionChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cobaltDeep,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 후보 시간표 하나(요일 헤더 + 그리드)를 보여주는 PageView 페이지.
class _CandidateGrid extends StatelessWidget {
  const _CandidateGrid({required this.courses, this.freeDay});

  final List<PlannedCourse> courses;

  /// 설문에서 고른 공강 요일. 월~금 밖이거나 null이면 강조하지 않는다.
  final Weekday? freeDay;

  /// 이 후보의 실제 수업 시간대만 보이도록(스크롤 없이 한눈에 들어오게),
  /// 수업이 걸쳐 있는 시간 앞뒤로 1시간씩만 여유를 두고 보여준다. 수업이
  /// 없거나 범위가 너무 좁으면(예: 1교시만) 최소 6시간은 보이게 한다.
  (int start, int end) _displayHourRange(List<CourseBlockLayout> layouts) {
    if (layouts.isEmpty) return (9, 18);

    var minHour = gridEndHour;
    var maxHour = gridStartHour;
    for (final layout in layouts) {
      minHour = minHour < layout.startMinutes ~/ 60
          ? minHour
          : layout.startMinutes ~/ 60;
      final endHour = (layout.endMinutes / 60).ceil();
      maxHour = maxHour > endHour ? maxHour : endHour;
    }

    var start = (minHour - 1).clamp(gridStartHour, gridEndHour);
    var end = (maxHour + 1).clamp(gridStartHour, gridEndHour);
    while (end - start < 6 && (start > gridStartHour || end < gridEndHour)) {
      if (start > gridStartHour) start--;
      if (end - start < 6 && end < gridEndHour) end++;
    }
    return (start, end);
  }

  @override
  Widget build(BuildContext context) {
    final layouts = buildBlockLayouts(courses);
    final freeDayIndex = freeDay == null ? null : gridColumnIndexOf(freeDay!);
    final (displayStartHour, displayEndHour) = _displayHourRange(layouts);
    final gridHeight = (displayEndHour - displayStartHour) * gridHourRowHeight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: _hourLabelColumnWidth),
              for (var i = 0; i < weekdayLabelsWeekdaysOnly.length; i++)
                Expanded(
                  child: Center(
                    child: i == freeDayIndex
                        ? Column(
                            children: [
                              Text(
                                weekdayLabelsWeekdaysOnly[i],
                                style: const TextStyle(
                                  color: AppColors.cobalt,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Text(
                                '공강',
                                style: TextStyle(
                                  color: AppColors.cobalt,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            weekdayLabelsWeekdaysOnly[i],
                            style: const TextStyle(
                              color: TimetableColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: gridHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columnWidth =
                        (constraints.maxWidth - _hourLabelColumnWidth) / 5;
                    return Stack(
                      children: [
                        if (freeDayIndex != null)
                          Positioned(
                            left:
                                _hourLabelColumnWidth +
                                freeDayIndex * columnWidth,
                            top: 0,
                            bottom: 0,
                            width: columnWidth,
                            child: ColoredBox(
                              color: AppColors.cobalt.withValues(alpha: 0.05),
                            ),
                          ),
                        _buildHourLabelsAndLines(
                          displayStartHour,
                          displayEndHour,
                        ),
                        for (final layout in layouts)
                          _positionedBlock(
                            layout,
                            columnWidth,
                            displayStartHour,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourLabelsAndLines(int startHour, int endHour) {
    return Column(
      children: [
        for (var hour = startHour; hour < endHour; hour++)
          SizedBox(
            height: gridHourRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: _hourLabelColumnWidth,
                  child: Text(
                    '$hour',
                    style: const TextStyle(
                      color: TimetableColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: TimetableColors.gridLine),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _positionedBlock(
    CourseBlockLayout layout,
    double columnWidth,
    int startHour,
  ) {
    final columnIndex = gridColumnIndexOf(layout.day)!;
    final top = _minutesToY(layout.startMinutes, startHour);
    final height = _minutesToY(layout.endMinutes, startHour) - top;
    return Positioned(
      left: _hourLabelColumnWidth + columnIndex * columnWidth,
      top: top,
      width: columnWidth,
      height: height,
      child: _LockedCourseBlock(layout: layout),
    );
  }

  double _minutesToY(int minutes, int startHour) {
    return (minutes - startHour * 60) / 60 * gridHourRowHeight;
  }
}

/// 그리드 위의 읽기 전용 강의 블록. [CourseBlock](widgets/course_block.dart)과
/// 달리 삭제(×) 버튼이 없다(탭해도 동작 없음 — 이 화면은 결과를 보여주기만
/// 할 뿐 편집은 할 수 없다).
class _LockedCourseBlock extends StatelessWidget {
  const _LockedCourseBlock({required this.layout});

  final CourseBlockLayout layout;

  @override
  Widget build(BuildContext context) {
    final color = colorForCourseKey(layout.course.key);
    final textColor = textColorOnBlock(color);
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.all(1.5),
      padding: const EdgeInsets.fromLTRB(5, 4, 3, 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              layout.course.courseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
          Flexible(
            child: Text(
              layout.course.room,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 9,
                height: 1.2,
              ),
            ),
          ),
          Flexible(
            child: Text(
              '${formatMinutesAsTime(layout.startMinutes)}–'
              '${formatMinutesAsTime(layout.endMinutes)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.9),
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
