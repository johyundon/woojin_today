import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/class_schedule_parser.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../../../widgets/primary_button.dart';
import '../models/ai_recommend_answers.dart';
import '../timetable_colors.dart';
import 'ai_recommend_widgets.dart';
import 'second_major_picker_sheet.dart';

const List<Weekday> _weekdayValues = [
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
];

/// "AI 시간표 자동 생성" 5단계 설문 (v7 디자인 17~21 ai_step1~5).
///
/// 거의 흰 바탕 위에 X 닫기·진행바, "n/5" 배지, 제목, 흰 카드 선택지, 하단
/// "이전"/"다음" 버튼을 둔다. 6번째 화면(결과 미리보기)은 이 위젯의 범위 밖이다 — [onSubmit]이 호출된 뒤 어디로
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

    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다(앱 테마는 아직 어두운 테마).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(key: ValueKey(_step), child: steps[_step]),
          ),
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
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Row(
            children: [
              const AiCloseButton(),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < step
                                ? AppColors.blue
                                : AiRecommendColors.progressTrack,
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
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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
                child: Text(
                  '$step/5',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  letterSpacing: -1.04,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
            child: content,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: bottomBar,
        ),
      ],
    );
  }
}

/// 좌측 "< 이전" 흰 버튼 + 우측 꽉 찬 파란 버튼. [onBack]이 null이면(1단계)
/// 다음 버튼만 풀폭으로 보여준다.
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
    final nextButton = PrimaryButton(
      label: nextLabel,
      enabled: true,
      onPressed: onNext,
    );

    final onBack = this.onBack;
    if (onBack == null) return nextButton;

    return Row(
      children: [
        AiBackButton(onTap: onBack),
        const SizedBox(width: 10),
        Expanded(child: nextButton),
      ],
    );
  }
}

/// 흰 카드 모양 선택 버튼의 바탕. 선택되면 연파랑 바탕 + 파란 1px 테두리.
BoxDecoration _choiceDecoration(bool selected) {
  return BoxDecoration(
    color: selected ? AppColors.blueSoft : Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: selected ? Border.all(color: AppColors.blue) : null,
    boxShadow: selected ? null : AppColors.cardShadow,
  );
}

TextStyle _choiceTextStyle(bool selected) {
  return TextStyle(
    color: selected ? AppColors.blueText : AppColors.textStrong,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
}

/// 설문 화면의 흰 카드(학점·비율 슬라이더 상자).
BoxDecoration get _cardDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: AppColors.cardShadow,
);

/// "상관없어요" 위의 옅은 가로줄(좌우 2씩 안쪽).
const Widget _divider = Padding(
  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 12),
  child: SizedBox(
    height: 1,
    width: double.infinity,
    child: ColoredBox(color: AppColors.fillDisabled),
  ),
);

/// 세로로 쌓이는 풀폭 선택 버튼(56 높이).
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
    return Pressable(
      pressedScale: 0.97,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: _choiceDecoration(selected),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: _choiceTextStyle(selected),
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
  static const _rangeLabelStyle = TextStyle(
    color: AppColors.textSub,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return _StepChrome(
      step: 1,
      title: '이번학기 몇학점\n들으실건가요?',
      content: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: _cardDecoration,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${widget.answers.credit.round()}',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 35,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    letterSpacing: -1.4,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '학점',
                  style: TextStyle(
                    color: TimetableColors.headerButtonText,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AiSlider(
              value: widget.answers.credit,
              min: 5,
              max: 22,
              divisions: 17,
              onChanged: (value) {
                setState(() => widget.answers.credit = value);
              },
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5학점', style: _rangeLabelStyle),
                Text('22학점', style: _rangeLabelStyle),
              ],
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
  static const _rowTextStyle = TextStyle(
    color: AppColors.textStrong,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );

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
          const SizedBox(height: 12),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: _choiceDecoration(false),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('아무 요일이나', style: _rowTextStyle),
                  for (var n = 1; n <= 4; n++) ...[
                    const SizedBox(width: 10),
                    _RoundNumberButton(
                      number: n,
                      selected:
                          answers.freeDayMode == FreeDayMode.anyDaysCount &&
                          answers.anyFreeDaysCount == n,
                      onTap: () => _selectAnyDaysCount(n),
                    ),
                  ],
                  const SizedBox(width: 10),
                  const Text('일이면 돼요', style: _rowTextStyle),
                ],
              ),
            ),
          ),
          _divider,
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
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: _choiceDecoration(selected),
        child: Text(label, style: _choiceTextStyle(selected)),
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
    return Pressable.icon(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : AppColors.blueSoft,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '$number',
          style: TextStyle(
            color: selected ? Colors.white : AppColors.blue,
            fontSize: 13,
            fontWeight: FontWeight.w800,
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
          for (final (i, (value, label)) in _options.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            _SelectableTile(
              label: label,
              selected: widget.answers.timePreference == value,
              onTap: () {
                setState(() => widget.answers.timePreference = value);
              },
            ),
          ],
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
  static const _labelStyle = TextStyle(
    color: AppColors.textStrong,
    fontSize: 13,
    fontWeight: FontWeight.w800,
  );

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: _cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text.rich(
                                TextSpan(
                                  text: '전공(주전공+타전공) ',
                                  children: [
                                    TextSpan(
                                      text: '${answers.majorRatio.round()}%',
                                      style: const TextStyle(
                                        color: AppColors.blue,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                style: _labelStyle,
                              ),
                            ),
                            Text(
                              '교양 ${liberalRatio.round()}%',
                              style: _labelStyle.copyWith(
                                color: AppColors.textSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AiSlider(
                          value: liberalRatio,
                          min: 0,
                          max: 100,
                          onChanged: (value) {
                            setState(() => answers.majorRatio = 100 - value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SecondMajorCard(
                    answers: answers,
                    labelStyle: _labelStyle,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
            ),
          ),
          _divider,
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

/// 4/5의 타전공 카드. 복수전공 학과를 고르기 전에는 고르는 줄만, 고른 뒤에는
/// 주전공/타전공 비율 슬라이더도 보여준다(학과를 모르면 반영할 수 없어서).
class _SecondMajorCard extends StatelessWidget {
  const _SecondMajorCard({
    required this.answers,
    required this.labelStyle,
    required this.onChanged,
  });

  final AiRecommendAnswers answers;
  final TextStyle labelStyle;
  final VoidCallback onChanged;

  Future<void> _pick(BuildContext context) async {
    final picked = await showSecondMajorPickerSheet(
      context,
      current: answers.secondMajorDepartment,
    );
    if (picked == null) return; // 그냥 닫음
    answers.secondMajorDepartment = picked.isEmpty ? null : picked;
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final second = answers.secondMajorDepartment;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Pressable(
            pressedScale: 0.98,
            onTap: () => _pick(context),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    '타전공(복수전공) 학과',
                    style: TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  second ?? '선택 안 함',
                  style: TextStyle(
                    color: second == null ? AppColors.textSub : AppColors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSub,
                  size: 20,
                ),
              ],
            ),
          ),
          if (second != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '주전공 ${answers.majorSubRatio.round()}%',
                  style: labelStyle,
                ),
                Opacity(
                  opacity: 0.8,
                  child: Text(
                    '타전공 ${(100 - answers.majorSubRatio).round()}%',
                    style: labelStyle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AiSlider(
              value: answers.majorSubRatio,
              min: 0,
              max: 100,
              onChanged: (value) {
                answers.majorSubRatio = value;
                onChanged();
              },
            ),
          ],
        ],
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
          for (final (i, (value, label)) in _options.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            _SelectableTile(
              label: label,
              selected: widget.answers.extraOption == value,
              onTap: () {
                setState(() => widget.answers.extraOption = value);
              },
            ),
          ],
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
