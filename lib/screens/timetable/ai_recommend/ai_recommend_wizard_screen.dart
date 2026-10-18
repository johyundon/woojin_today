import 'package:flutter/material.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../models/ai_recommend_answers.dart';

const List<Weekday> _weekdayValues = [
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
];

/// "AI 시간표 자동 생성" 5단계 설문 (Figma node 6:59, node-id 6:60~6:64).
///
/// 이 노드는 실제 Figma 벡터 레이어가 아니라 앱 스크린샷 6장이 평탄화된
/// 상태라 `get_design_context`로 쓸만한 코드를 뽑을 수 없었다. 스크린샷을
/// 눈으로 보고 레이아웃/색상/간격을 근사해 재현했다. 6번째 화면(결과
/// 미리보기)은 이 위젯의 범위 밖이다 — [onSubmit]이 호출된 뒤 어디로
/// 이동할지는 호출부가 결정한다.
class AiRecommendWizardScreen extends StatefulWidget {
  const AiRecommendWizardScreen({required this.onSubmit, super.key});

  /// 5단계 "시간표 만들기" 버튼을 눌렀을 때 호출된다. 호출부(이 위젯 밖)가
  /// 이 콜백 안에서 실제 추천 결과 화면으로 네비게이션한다 — 이 위젯은
  /// 그 이후 어떤 화면으로 가는지 몰라도 된다.
  final Future<void> Function(BuildContext context, AiRecommendAnswers answers)
  onSubmit;

  @override
  State<AiRecommendWizardScreen> createState() =>
      _AiRecommendWizardScreenState();
}

class _AiRecommendWizardScreenState extends State<AiRecommendWizardScreen> {
  final _answers = AiRecommendAnswers();
  int _step = 0;

  void _goNext() {
    if (_step < 4) setState(() => _step++);
  }

  void _goBack() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    await widget.onSubmit(context, _answers);
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      _CreditStep(answers: _answers, onNext: _goNext),
      _FreeDayStep(answers: _answers, onNext: _goNext, onBack: _goBack),
      _TimePreferenceStep(answers: _answers, onNext: _goNext, onBack: _goBack),
      _MajorRatioStep(answers: _answers, onNext: _goNext, onBack: _goBack),
      _ExtraOptionStep(answers: _answers, onSubmit: _submit, onBack: _goBack),
    ];

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(_step), child: steps[_step]),
        ),
      ),
    );
  }
}

/// 5개 단계 화면 전부가 공유하는 뼈대: X 닫기 + 진행바, "n/5" 배지, 제목,
/// 내용, 하단 버튼.
class _StepChrome extends StatelessWidget {
  const _StepChrome({
    required this.step,
    required this.title,
    required this.content,
    required this.bottomBar,
  });

  final int step;
  final String title;
  final Widget content;
  final Widget bottomBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.cobaltDeep,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < step
                                ? AppColors.lime
                                : AppColors.cobaltDeep,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
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
                  '$step/5',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.02,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: content,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: bottomBar,
        ),
      ],
    );
  }
}

/// 좌측 "< 이전" + 우측 꽉 찬 라임 버튼. [onBack]이 null이면(1단계) 다음
/// 버튼만 풀폭으로 보여준다.
class _StepBottomBar extends StatelessWidget {
  const _StepBottomBar({
    required this.nextLabel,
    required this.onNext,
    this.onBack,
  });

  final String nextLabel;
  final VoidCallback? onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final nextButton = SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          nextLabel,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );

    if (onBack == null) {
      return SizedBox(width: double.infinity, child: nextButton);
    }

    return Row(
      children: [
        SizedBox(
          width: 92,
          height: 56,
          child: OutlinedButton(
            onPressed: onBack,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white54),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              '< 이전',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: nextButton),
      ],
    );
  }
}

/// 세로로 쌓이는 풀폭 선택 버튼(3/5, 5/5 화면에서 공용). 파란 배경 위에
/// 직접 놓이므로 미선택 상태는 반투명 흰 오버레이, 선택 상태는 라임색.
class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        margin: const EdgeInsets.only(bottom: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lime
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.ink : Colors.white,
            fontSize: 15,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 1/5 — 학점 슬라이더.
class _CreditStep extends StatefulWidget {
  const _CreditStep({required this.answers, required this.onNext});

  final AiRecommendAnswers answers;
  final VoidCallback onNext;

  @override
  State<_CreditStep> createState() => _CreditStepState();
}

class _CreditStepState extends State<_CreditStep> {
  @override
  Widget build(BuildContext context) {
    return _StepChrome(
      step: 1,
      title: '이번학기 몇학점\n들으실건가요?',
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '${widget.answers.credit.round()}',
                    style: const TextStyle(
                      color: AppColors.cobalt,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const TextSpan(
                    text: '학점',
                    style: TextStyle(
                      color: AppColors.cobalt,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.cobalt,
                inactiveTrackColor: AppColors.cobalt.withValues(alpha: 0.15),
                thumbColor: AppColors.cobalt,
                overlayColor: AppColors.cobalt.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: widget.answers.credit,
                min: 5,
                max: 22,
                divisions: 17,
                onChanged: (value) {
                  setState(() => widget.answers.credit = value);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '5학점',
                    style: TextStyle(color: Color(0xFF9A978F), fontSize: 12),
                  ),
                  Text(
                    '22학점',
                    style: TextStyle(color: Color(0xFF9A978F), fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomBar: _StepBottomBar(nextLabel: '다음', onNext: widget.onNext),
    );
  }
}

/// 2/5 — 공강 요일.
class _FreeDayStep extends StatefulWidget {
  const _FreeDayStep({
    required this.answers,
    required this.onNext,
    required this.onBack,
  });

  final AiRecommendAnswers answers;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_FreeDayStep> createState() => _FreeDayStepState();
}

class _FreeDayStepState extends State<_FreeDayStep> {
  void _selectSpecificDay(Weekday day) {
    setState(() {
      widget.answers.freeDayMode = FreeDayMode.specificDay;
      widget.answers.specificFreeDay = day;
    });
  }

  void _selectAnyDaysCount(int count) {
    setState(() {
      widget.answers.freeDayMode = FreeDayMode.anyDaysCount;
      widget.answers.anyFreeDaysCount = count;
    });
  }

  void _selectAny() {
    setState(() => widget.answers.freeDayMode = FreeDayMode.any);
  }

  @override
  Widget build(BuildContext context) {
    final answers = widget.answers;

    return _StepChrome(
      step: 2,
      title: '공강은 언제로\n할까요?',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 0; i < _weekdayValues.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _WeekdayChip(
                    label: weekdayLabelsWeekdaysOnly[i],
                    selected:
                        answers.freeDayMode == FreeDayMode.specificDay &&
                        answers.specificFreeDay == _weekdayValues[i],
                    onTap: () => _selectSpecificDay(_weekdayValues[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Text(
                  '아무 요일이나',
                  style: TextStyle(color: AppColors.ink, fontSize: 14),
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var n = 1; n <= 4; n++) ...[
                        if (n > 1) const SizedBox(width: 6),
                        _RoundNumberButton(
                          number: n,
                          selected:
                              answers.freeDayMode == FreeDayMode.anyDaysCount &&
                              answers.anyFreeDaysCount == n,
                          onTap: () => _selectAnyDaysCount(n),
                        ),
                      ],
                    ],
                  ),
                ),
                const Text(
                  '일이면\n돼요',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SelectableTile(
            label: '상관없어요',
            selected: answers.freeDayMode == FreeDayMode.any,
            onTap: _selectAny,
          ),
        ],
      ),
      bottomBar: _StepBottomBar(
        nextLabel: '다음',
        onNext: widget.onNext,
        onBack: widget.onBack,
      ),
    );
  }
}

class _WeekdayChip extends StatelessWidget {
  const _WeekdayChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.lime
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.ink : Colors.white,
            fontSize: 14,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _RoundNumberButton extends StatelessWidget {
  const _RoundNumberButton({
    required this.number,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cobalt
              : AppColors.cobalt.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// 3/5 — 오전/오후 선호.
class _TimePreferenceStep extends StatefulWidget {
  const _TimePreferenceStep({
    required this.answers,
    required this.onNext,
    required this.onBack,
  });

  final AiRecommendAnswers answers;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_TimePreferenceStep> createState() => _TimePreferenceStepState();
}

class _TimePreferenceStepState extends State<_TimePreferenceStep> {
  static const _options = [
    (TimePreference.morning, '오전 수업이 좋아요'),
    (TimePreference.afternoon, '오후 수업이 좋아요'),
    (TimePreference.mixed, '적당히 섞어주세요'),
    (TimePreference.any, '상관없어요'),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepChrome(
      step: 3,
      title: '오전 수업, 오후 수업 중\n언제가 좋으세요?',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (value, label) in _options)
            _SelectableTile(
              label: label,
              selected: widget.answers.timePreference == value,
              onTap: () {
                setState(() => widget.answers.timePreference = value);
              },
            ),
        ],
      ),
      bottomBar: _StepBottomBar(
        nextLabel: '다음',
        onNext: widget.onNext,
        onBack: widget.onBack,
      ),
    );
  }
}

/// 4/5 — 전공/교양 비율.
class _MajorRatioStep extends StatefulWidget {
  const _MajorRatioStep({
    required this.answers,
    required this.onNext,
    required this.onBack,
  });

  final AiRecommendAnswers answers;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_MajorRatioStep> createState() => _MajorRatioStepState();
}

class _MajorRatioStepState extends State<_MajorRatioStep> {
  void _toggleAny() {
    setState(() {
      widget.answers.majorRatioAny = !widget.answers.majorRatioAny;
    });
  }

  @override
  Widget build(BuildContext context) {
    final answers = widget.answers;
    final liberalRatio = 100 - answers.majorRatio;

    return _StepChrome(
      step: 4,
      title: '전공과 교양 비율을\n정해주세요',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IgnorePointer(
            ignoring: answers.majorRatioAny,
            child: Opacity(
              opacity: answers.majorRatioAny ? 0.4 : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '전공(주전공+타전공) ${answers.majorRatio.round()}%',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '교양 ${liberalRatio.round()}%',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.cobalt,
                        inactiveTrackColor: AppColors.cobalt.withValues(
                          alpha: 0.15,
                        ),
                        thumbColor: AppColors.cobalt,
                      ),
                      child: Slider(
                        value: liberalRatio,
                        min: 0,
                        max: 100,
                        onChanged: (value) {
                          setState(() => answers.majorRatio = 100 - value);
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cobalt.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '전공 비중 중에서, 주전공과 타전공 비율',
                            style: TextStyle(
                              color: Color(0xFF9A978F),
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '주전공 ${answers.majorSubRatio.round()}%',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '타전공 ${(100 - answers.majorSubRatio).round()}%',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.cobalt,
                              inactiveTrackColor: AppColors.cobalt.withValues(
                                alpha: 0.15,
                              ),
                              thumbColor: AppColors.cobalt,
                            ),
                            child: Slider(
                              value: answers.majorSubRatio,
                              min: 0,
                              max: 100,
                              onChanged: (value) {
                                setState(() => answers.majorSubRatio = value);
                              },
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
          const SizedBox(height: 16),
          _SelectableTile(
            label: '상관없어요',
            selected: answers.majorRatioAny,
            onTap: _toggleAny,
          ),
        ],
      ),
      bottomBar: _StepBottomBar(
        nextLabel: '다음',
        onNext: widget.onNext,
        onBack: widget.onBack,
      ),
    );
  }
}

/// 5/5 — 추가 옵션.
class _ExtraOptionStep extends StatefulWidget {
  const _ExtraOptionStep({
    required this.answers,
    required this.onSubmit,
    required this.onBack,
  });

  final AiRecommendAnswers answers;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  State<_ExtraOptionStep> createState() => _ExtraOptionStepState();
}

class _ExtraOptionStepState extends State<_ExtraOptionStep> {
  static const _options = [
    (ExtraOption.honeyLecturesPreferred, '꿀강의 위주로 담아주세요!'),
    (ExtraOption.any, '상관없어요'),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepChrome(
      step: 5,
      title: '추가로 원하는\n옵션이 있나요?',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (value, label) in _options)
            _SelectableTile(
              label: label,
              selected: widget.answers.extraOption == value,
              onTap: () {
                setState(() => widget.answers.extraOption = value);
              },
            ),
        ],
      ),
      bottomBar: _StepBottomBar(
        nextLabel: '시간표 만들기',
        onNext: widget.onSubmit,
        onBack: widget.onBack,
      ),
    );
  }
}
