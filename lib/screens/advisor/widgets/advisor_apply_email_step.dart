import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'advisor_apply_common.dart';

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
        style: const TextStyle(color: AppColors.textStrong, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: advisorFieldBackground,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: advisorFieldBorder, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.blue, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: advisorFieldBorder, width: 2),
          ),
        ),
      ),
      nextEnabled: emailValid,
      onBack: onBack,
      onNext: onNext,
    );
  }
}
