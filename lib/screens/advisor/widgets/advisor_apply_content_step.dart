import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'advisor_apply_common.dart';

const Color _fieldFill = Color(0xFFFAFAFD);
const Color _fieldBorder = Color(0xFFE4E3EC);
const Color _disabledText = Color(0xFFB3B2C0);

/// 마지막 단계: 상담 내용 입력(온라인은 4단계째, 방문은 2단계째).
class AdvisorContentStep extends StatelessWidget {
  const AdvisorContentStep({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.controller,
    required this.minContentLength,
    required this.contentValid,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final TextEditingController controller;
  final int minContentLength;
  final bool contentValid;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AdvisorApplyFormStep(
      title: '어떤 이야기를 나누고 싶어요?',
      step: step,
      totalSteps: totalSteps,
      content: TextField(
        controller: controller,
        minLines: 5,
        maxLines: 8,
        style: const TextStyle(color: AppColors.ink, fontSize: 15),
        decoration: InputDecoration(
          hintText: '$minContentLength자 이상 적어주세요',
          hintStyle: const TextStyle(color: _disabledText),
          filled: true,
          fillColor: _fieldFill,
          contentPadding: const EdgeInsets.all(14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _fieldBorder, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.cobalt, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _fieldBorder, width: 2),
          ),
        ),
      ),
      nextLabel: '상담 신청하기',
      nextEnabled: contentValid,
      onBack: onBack,
      onNext: onNext,
    );
  }
}
