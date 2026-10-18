import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'advisor_apply_common.dart';

const Color _fieldFill = Color(0xFFFAFAFD);
const Color _fieldBorder = Color(0xFFE4E3EC);

/// 3단계(온라인 전용): 이메일 입력.
class AdvisorEmailStep extends StatelessWidget {
  const AdvisorEmailStep({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.controller,
    required this.emailValid,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final TextEditingController controller;
  final bool emailValid;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AdvisorApplyFormStep(
      title: '이메일을 입력해주세요',
      step: step,
      totalSteps: totalSteps,
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: AppColors.ink, fontSize: 16),
        decoration: InputDecoration(
          filled: true,
          fillColor: _fieldFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
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
      nextEnabled: emailValid,
      onBack: onBack,
      onNext: onNext,
    );
  }
}
