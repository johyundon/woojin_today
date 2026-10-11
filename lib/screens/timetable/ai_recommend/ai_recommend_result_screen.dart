import 'package:flutter/material.dart';

import '../grid_layout.dart';
import '../models/planned_course.dart';
import '../timetable_colors.dart';

const List<String> _weekdayLabels = ['월', '화', '수', '목', '금'];
const double _hourLabelColumnWidth = 28;

/// "AI 시간표 자동 생성" 결과 미리보기 (Figma node 6:59, node-id 6:65 — 스크린샷
/// 6장 중 마지막 1장).
///
/// 이 노드는 실제 Figma 벡터 레이어가 아니라 앱 스크린샷이 평탄화된 상태라
/// `get_design_context`로 쓸만한 코드를 뽑을 수 없었다(캘린더 화면,
/// [TimetableColors], 앞 5단계 설문 화면과 같은 선례). 스크린샷을 눈으로 보고
/// 레이아웃/색상/간격을 근사해 재현했다. 추천 알고리즘/데이터 조회는 이 화면의
/// 책임이 아니라 [onRegenerate]/[onConfirm] 콜백으로 호출부에 위임한다.
class AiRecommendResultScreen extends StatefulWidget {
  const AiRecommendResultScreen({
    required this.candidates,
    required this.onRegenerate,
    required this.onConfirm,
    super.key,
  });

  /// 생성된 후보 시간표 목록(보통 3개). 각 원소가 "시간표 하나"(과목 리스트).
  final List<List<PlannedCourse>> candidates;

  /// "다시 주세요!" 탭 — 새 후보들을 다시 받아와야 해서 호출부로 위임한다
  /// (이 화면은 스스로 재생성 로직을 모른다). 비동기로 새 후보 리스트를
  /// 돌려주면 이 화면이 그걸로 내부 상태(candidates)를 교체해서 다시
  /// 보여준다.
  final Future<List<List<PlannedCourse>>> Function() onRegenerate;

  /// "이 시간표로 할래요" 탭 — 지금 보고 있는 페이지의 후보(`List<PlannedCourse>`)를
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

  @override
  Widget build(BuildContext context) {
    final hasCandidates = _candidates.isNotEmpty;

    return Scaffold(
      backgroundColor: TimetableColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              currentIndex: _currentIndex,
              total: _candidates.length,
              regenerating: _regenerating,
              onRegenerate: _onRegenerate,
            ),
            if (!hasCandidates)
              const Expanded(
                child: Center(
                  child: Text(
                    '조건에 맞는 시간표를 찾지 못했어요',
                    style: TextStyle(
                      color: TimetableColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '총 ${_formatCredit(_totalCredit(_candidates[_currentIndex]))}학점 · '
                    '${_candidates[_currentIndex].length}과목',
                    style: const TextStyle(
                      color: TimetableColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _candidates.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) =>
                      _CandidateGrid(courses: _candidates[index]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: TimetableColors.border),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          '< 이전',
                          style: TextStyle(
                            color: TimetableColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TimetableColors.accent,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          child: const Text(
                            '이 시간표로 할래요',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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

/// X 닫기 + "n/m" 페이지 표시 + "다시 주세요!" 버튼으로 이뤄진 상단 바.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.currentIndex,
    required this.total,
    required this.regenerating,
    required this.onRegenerate,
  });

  final int currentIndex;
  final int total;
  final bool regenerating;
  final VoidCallback onRegenerate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: TimetableColors.textPrimary),
          ),
          Expanded(
            child: Center(
              child: total > 0
                  ? Text(
                      '${currentIndex + 1}/$total',
                      style: const TextStyle(
                        color: TimetableColors.textSecondary,
                        fontSize: 13,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          _RegenerateButton(loading: regenerating, onTap: onRegenerate),
        ],
      ),
    );
  }
}

class _RegenerateButton extends StatelessWidget {
  const _RegenerateButton({required this.loading, required this.onTap});

  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: TimetableColors.accent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '다시 주세요!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

/// 후보 시간표 하나(요일 헤더 + 그리드)를 보여주는 PageView 페이지.
class _CandidateGrid extends StatelessWidget {
  const _CandidateGrid({required this.courses});

  final List<PlannedCourse> courses;

  static const int _hourCount = gridEndHour - gridStartHour;
  static const double _gridHeight = _hourCount * gridHourRowHeight;

  @override
  Widget build(BuildContext context) {
    final layouts = buildBlockLayouts(courses);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: _hourLabelColumnWidth),
              for (final label in _weekdayLabels)
                Expanded(
                  child: Center(
                    child: Text(
                      label,
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
                height: _gridHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final columnWidth =
                        (constraints.maxWidth - _hourLabelColumnWidth) / 5;
                    return Stack(
                      children: [
                        _buildHourLabelsAndLines(),
                        for (final layout in layouts)
                          _positionedBlock(layout, columnWidth),
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

  Widget _buildHourLabelsAndLines() {
    return Column(
      children: [
        for (var hour = gridStartHour; hour < gridEndHour; hour++)
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

  Widget _positionedBlock(CourseBlockLayout layout, double columnWidth) {
    final columnIndex = gridColumnIndexOf(layout.day)!;
    final top = _minutesToY(layout.startMinutes);
    final height = _minutesToY(layout.endMinutes) - top;
    return Positioned(
      left: _hourLabelColumnWidth + columnIndex * columnWidth,
      top: top,
      width: columnWidth,
      height: height,
      child: _LockedCourseBlock(layout: layout),
    );
  }

  double _minutesToY(int minutes) {
    return (minutes - gridStartHour * 60) / 60 * gridHourRowHeight;
  }
}

/// 그리드 위의 읽기 전용 강의 블록. [CourseBlock](widgets/course_block.dart)과
/// 달리 삭제(×) 버튼이 없고, 그 자리에 장식용 자물쇠 배지만 떠 있다(탭해도
/// 동작 없음 — 이 화면은 결과를 보여주기만 할 뿐 편집은 할 수 없다).
class _LockedCourseBlock extends StatelessWidget {
  const _LockedCourseBlock({required this.layout});

  final CourseBlockLayout layout;

  @override
  Widget build(BuildContext context) {
    final color = colorForCourseKey(layout.course.key);
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 20, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    layout.course.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    '${layout.course.room} · ${layout.course.section}분반',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock, color: Colors.white, size: 10),
            ),
          ),
        ],
      ),
    );
  }
}
