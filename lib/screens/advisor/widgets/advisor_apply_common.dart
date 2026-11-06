import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 진행 막대의 아직 안 간 칸, 입력칸 테두리(포커스 없을 때).
const Color advisorFieldBorder = Color(0xFFE2E4E8);

/// 입력칸 바탕.
const Color advisorFieldBackground = Color(0xFFFAFAFD);

/// "상담 신청" 탭의 단계 카드들이 공통으로 쓰는 뼈대 위젯 모음(흰 카드,
/// 진행 점, 단계 헤더, 파란 주 버튼, 이전/다음 버튼이 달린 입력형 단계).
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
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
    // v7 시안: 켜졌을 때는 파랑(모서리 16·그림자), 꺼졌을 때는 옅은 회색
    // (모서리 12·그림자 없음·글자 15/800).
    final radius = BorderRadius.circular(enabled ? 16 : 12);
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: enabled ? AppColors.cardShadow : null,
      ),
      child: Pressable.effect(
        enabled: enabled,
        pressedScale: 0.97,
        child: ElevatedButton(
          onPressed: enabled ? onTap : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.fill,
            disabledForegroundColor: AppColors.textMuted,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: enabled ? 16 : 15,
              fontWeight: enabled ? FontWeight.w700 : FontWeight.w800,
            ),
          ),
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
                color: i <= step ? AppColors.blue : advisorFieldBorder,
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
              color: AppColors.textStrong,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.32,
            ),
          ),
        ),
        Text(
          '${step + 1} / $totalSteps',
          style: const TextStyle(
            color: AppColors.textSub,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 2단계 이상의 "입력형" 단계가 공유하는 뼈대: 제목 + 입력 영역, 그
/// 아래 "이전"(옅은 회색) + 다음/제출(파랑, 조건 안 맞으면 비활성) 버튼.
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
        AdvisorApplyStepHeader(
          title: title,
          step: step,
          totalSteps: totalSteps,
        ),
        const SizedBox(height: 15),
        AdvisorApplyProgressDots(step: step, totalSteps: totalSteps),
        const SizedBox(height: 26),
        content,
        const SizedBox(height: 28),
        Row(
          children: [
            Pressable(
              onTap: onBack,
              child: Container(
                width: 84,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 16,
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
