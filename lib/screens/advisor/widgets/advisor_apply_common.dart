import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _fieldBorder = Color(0xFFE4E3EC);
const Color _chipBackground = Color(0xFFF1F0F7);
const Color _disabledText = Color(0xFFB3B2C0);

/// "상담 신청" 탭의 단계 카드들이 공통으로 쓰는 뼈대 위젯 모음(흰 카드,
/// 진행 점, 단계 헤더, 라임 주 버튼, 이전/다음 버튼이 달린 입력형 단계).
class AdvisorApplyCard extends StatelessWidget {
  const AdvisorApplyCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class AdvisorApplyPrimaryButton extends StatelessWidget {
  const AdvisorApplyPrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lime,
          foregroundColor: AppColors.ink,
          disabledBackgroundColor: _chipBackground,
          disabledForegroundColor: _disabledText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class AdvisorApplyProgressDots extends StatelessWidget {
  const AdvisorApplyProgressDots({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < totalSteps; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i == totalSteps - 1 ? 0 : 4),
              decoration: BoxDecoration(
                color: i <= step ? AppColors.cobalt : _fieldBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class AdvisorApplyStepHeader extends StatelessWidget {
  const AdvisorApplyStepHeader({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
  });

  final String title;
  final int step;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${step + 1} / $totalSteps',
          style: const TextStyle(
            color: _mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 2단계 이상의 "입력형" 단계가 공유하는 뼈대: 제목 + 입력 영역, 그
/// 아래 "이전"(연보라) + 다음/제출(라임, 조건 안 맞으면 비활성) 버튼.
class AdvisorApplyFormStep extends StatelessWidget {
  const AdvisorApplyFormStep({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
    required this.content,
    required this.nextEnabled,
    required this.onBack,
    required this.onNext,
    this.nextLabel = '다음',
  });

  final String title;
  final int step;
  final int totalSteps;
  final Widget content;
  final bool nextEnabled;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    return AdvisorApplyCard(
      children: [
        AdvisorApplyStepHeader(title: title, step: step, totalSteps: totalSteps),
        const SizedBox(height: 14),
        AdvisorApplyProgressDots(step: step, totalSteps: totalSteps),
        const SizedBox(height: 14),
        content,
        const SizedBox(height: 14),
        Row(
          children: [
            GestureDetector(
              onTap: onBack,
              child: Container(
                width: 84,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _chipBackground,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AdvisorApplyPrimaryButton(
                label: nextLabel,
                enabled: nextEnabled,
                onTap: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
