import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'advisor_apply_common.dart';

const Color _fieldFill = Color(0xFFFAFAFD);
const Color _fieldBorder = Color(0xFFE4E3EC);
const Color _disabledText = Color(0xFFB3B2C0);
const Color _errorColor = Color(0xFFE5484D);

/// 자음·모음 낱글자(ㅋㅋ, ㅏㅏ 등). 완성된 글자가 아니라서 상담 내용 글자
/// 수에 넣지 않는다.
final RegExp _jamoPattern = RegExp(r'[\u1100-\u11FF\u3131-\u318E]');

/// 상담 내용의 유효 글자 수 — 앞뒤 공백과 자음·모음 낱글자는 세지 않는다.
int advisorContentLength(String text) =>
    text.replaceAll(_jamoPattern, '').trim().length;

/// 마지막 단계: 상담 내용 입력(온라인·방문 모두 4단계째).
class AdvisorContentStep extends StatelessWidget {
  const AdvisorContentStep({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.controller,
    required this.minContentLength,
    required this.showError,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final TextEditingController controller;
  final int minContentLength;

  /// 10자 미만인 채로 "상담 신청하기"를 눌렀을 때 입력창에 안내를 띄울지.
  final bool showError;
  final VoidCallback onBack;
  final VoidCallback onNext;

  String get _errorMessage {
    final count = advisorContentLength(controller.text);
    final hasJamo = _jamoPattern.hasMatch(controller.text);
    return hasJamo
        ? '자음·모음만으로는 글자 수에 포함되지 않아요. 완성된 글자로 '
              '$minContentLength자 이상 적어주세요 (현재 $count자)'
        : '$minContentLength자 이상 적어주세요 (현재 $count자)';
  }

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
          errorText: showError ? _errorMessage : null,
          errorStyle: const TextStyle(color: _errorColor, fontSize: 12),
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
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _errorColor, width: 2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _errorColor, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _fieldBorder, width: 2),
          ),
        ),
      ),
      nextLabel: '상담 신청하기',
      // 글자를 하나라도 입력하면 눌리고, 10자 미만이면 눌렀을 때 안내를 띄운다.
      nextEnabled: controller.text.trim().isNotEmpty,
      onBack: onBack,
      onNext: onNext,
    );
  }
}
