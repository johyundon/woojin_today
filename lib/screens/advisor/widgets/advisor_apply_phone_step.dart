import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'advisor_apply_common.dart';

const Color _fieldFill = Color(0xFFFAFAFD);
const Color _fieldBorder = Color(0xFFE4E3EC);

/// 2단계(온라인 전용): 전화번호 입력(010-XXXX-XXXX 3칸).
class AdvisorPhoneStep extends StatelessWidget {
  const AdvisorPhoneStep({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.firstController,
    required this.middleController,
    required this.lastController,
    required this.firstFocus,
    required this.middleFocus,
    required this.lastFocus,
    required this.phoneValid,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final TextEditingController firstController;
  final TextEditingController middleController;
  final TextEditingController lastController;
  final FocusNode firstFocus;
  final FocusNode middleFocus;
  final FocusNode lastFocus;
  final bool phoneValid;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AdvisorApplyFormStep(
      title: '전화번호를 입력해주세요',
      step: step,
      totalSteps: totalSteps,
      content: Row(
        children: [
          Expanded(
            child: _PhoneBox(
              controller: firstController,
              focusNode: firstFocus,
              nextFocusNode: middleFocus,
              maxLength: 3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PhoneBox(
              controller: middleController,
              focusNode: middleFocus,
              nextFocusNode: lastFocus,
              maxLength: 4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _PhoneBox(
              controller: lastController,
              focusNode: lastFocus,
              // 마지막 칸이라 다 채우면 다음 칸으로 넘기는 대신 키보드를 내린다.
              nextFocusNode: null,
              maxLength: 4,
            ),
          ),
        ],
      ),
      nextEnabled: phoneValid,
      onBack: onBack,
      onNext: onNext,
    );
  }
}

class _PhoneBox extends StatelessWidget {
  const _PhoneBox({
    required this.controller,
    required this.focusNode,
    required this.nextFocusNode,
    this.maxLength,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.ink, fontSize: 16),
      onChanged: (value) {
        final maxLength = this.maxLength;
        if (maxLength == null || value.length < maxLength) return;
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          FocusScope.of(context).unfocus();
        }
      },
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: _fieldFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
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
    );
  }
}
