import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/time_format.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/mascot_sticker.dart';
import '../../../widgets/pressable.dart';
import '../grid_layout.dart';
import '../models/ai_recommend_answers.dart';
import '../models/planned_course.dart';
import '../timetable_colors.dart';
import 'ai_recommend_widgets.dart';

const List<String> _weekdayFullNames = ['월요일', '화요일', '수요일', '목요일', '금요일'];
const double _hourLabelColumnWidth = 24;

/// 결과 그리드 한 시간 칸 높이(디자인 22의 줄 간격 54). 메인 시간표 그리드와
/// 달리 스크롤 없이 한눈에 보이도록 정해진 값이라 따로 둔다.
const double _hourRowHeight = 54;

/// 가로줄 가운데에 맞춘 시각 글자(17 높이)가 줄 위로 나오는 만큼.
const double _labelOverhang = 8;

const TextStyle _dayLabelStyle = TextStyle(
  color: AppColors.textSub,
  fontSize: 12,
  fontWeight: FontWeight.w800,
  height: 1.4,
);
const TextStyle _freeDayLabelStyle = TextStyle(
  color: AppColors.blue,
  fontSize: 12,
  fontWeight: FontWeight.w800,
  height: 1.4,
);
const TextStyle _hourLabelStyle = TextStyle(
  color: AppColors.textSub,
  fontSize: 12,
  fontWeight: FontWeight.w700,
  height: 1.4,
);

/// "AI 시간표 자동 생성" 결과 미리보기 (v7 디자인 22 ai_result).
///
/// 거의 흰 바탕 위에 학점·과목 수 배지, 제목, 조건 칩을 두고, 그 아래 흰
/// 시트에 후보 시간표 그리드(옆으로 넘겨 다른 후보 보기)를 그린다. 추천 알고리즘/데이터 조회는 이 화면의
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

    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다(앱 테마는 아직 어두운 테마).
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
                      style: TextStyle(
                        color: AppColors.textSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SoftBadge(
                            '총 ${_formatCredit(_totalCredit(_candidates[_currentIndex]))}학점 · '
                            '${_candidates[_currentIndex].length}과목',
                          ),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.only(right: 100),
                            child: Text(
                              '이 시간표\n어때?',
                              style: TextStyle(
                                color: AppColors.textStrong,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                height: 1.4,
                                letterSpacing: -1.04,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Positioned(
                        right: -13,
                        top: -13,
                        child: MascotSticker(width: 97, angle: 0.14),
                      ),
                    ],
                  ),
                ),
                if (_conditionChips.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    // 칩 그림자가 잘리지 않도록 위아래로 여유를 둔다.
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                    child: Row(
                      children: [
                        for (final (i, chip) in _conditionChips.indexed) ...[
                          if (i > 0) const SizedBox(width: 6),
                          _ConditionChip(chip),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 25),
                Expanded(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                      boxShadow: TimetableColors.sheetShadow,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(36),
                            ),
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
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            12,
                            24,
                            16 + MediaQuery.of(context).padding.bottom,
                          ),
                          child: Row(
                            children: [
                              AiBackButton(
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ConfirmButton(onTap: _onConfirm),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
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
        const AiCloseButton(),
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
    return Pressable(
      enabled: !loading,
      pressedScale: 0.93,
      onTap: loading ? null : onTap,
      child: Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.blue,
                ),
              )
            else
              const Icon(
                Icons.refresh_rounded,
                color: AppColors.blue,
                size: 15,
              ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "총 N학점 · M과목" 연파랑 배지.
class _SoftBadge extends StatelessWidget {
  const _SoftBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.4,
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.cardShadow,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textStrong,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          height: 1.4,
        ),
      ),
    );
  }
}

/// "이 시간표 할래요" 파란 그라데이션 버튼(60 높이).
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: AiRecommendColors.confirmGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: const Text(
          '이 시간표 할래요',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
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
    final gridHeight = (displayEndHour - displayStartHour) * _hourRowHeight;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 34,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: _hourLabelColumnWidth),
                for (var i = 0; i < weekdayLabelsWeekdaysOnly.length; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          weekdayLabelsWeekdaysOnly[i],
                          style: i == freeDayIndex
                              ? _freeDayLabelStyle
                              : _dayLabelStyle,
                        ),
                        if (i == freeDayIndex)
                          const Text('공강', style: _freeDayLabelStyle),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              // 줄 위에 걸친 첫/마지막 시각 글자가 잘리지 않도록 위아래 여유.
              padding: const EdgeInsets.only(
                top: _labelOverhang,
                bottom: _labelOverhang + 8,
              ),
              child: SizedBox(
                height: gridHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columnWidth =
                        (constraints.maxWidth - _hourLabelColumnWidth) / 5;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        if (freeDayIndex != null)
                          Positioned(
                            left:
                                _hourLabelColumnWidth +
                                freeDayIndex * columnWidth,
                            top: 0,
                            bottom: 0,
                            width: columnWidth,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ..._buildHourLabelsAndLines(
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

  /// 시각 글자는 디자인처럼 가로줄 높이에 세로 가운데를 맞춘다.
  List<Widget> _buildHourLabelsAndLines(int startHour, int endHour) {
    return [
      for (var hour = startHour; hour <= endHour; hour++) ...[
        if (hour < endHour)
          Positioned(
            left: _hourLabelColumnWidth,
            right: 0,
            top: (hour - startHour) * _hourRowHeight,
            height: 1,
            child: const ColoredBox(color: TimetableColors.gridLine),
          ),
        Positioned(
          left: 0,
          width: _hourLabelColumnWidth,
          top: (hour - startHour) * _hourRowHeight - _labelOverhang,
          child: Text('$hour', style: _hourLabelStyle),
        ),
      ],
    ];
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
    return (minutes - startHour * 60) / 60 * _hourRowHeight;
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
    final subStyle = TextStyle(
      color: textColor.withValues(alpha: 0.9),
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.4,
      letterSpacing: -0.36,
    );
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.all(5),
      clipBehavior: Clip.hardEdge,
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
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.4,
                letterSpacing: -0.36,
              ),
            ),
          ),
          Flexible(
            child: Text(
              layout.course.room,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subStyle,
            ),
          ),
          Flexible(
            child: Text(
              '${formatMinutesAsTime(layout.startMinutes)}–'
              '${formatMinutesAsTime(layout.endMinutes)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: subStyle,
            ),
          ),
        ],
      ),
    );
  }
}
