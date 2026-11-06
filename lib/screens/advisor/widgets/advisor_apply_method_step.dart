import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../models/advisor_consultation_models.dart';
import 'advisor_apply_common.dart';
import 'advisor_apply_visit_schedule_picker.dart';

const Color _methodBorder = Color(0xFFD5D9E0);
const Color _methodText = Color(0xFF3F4558);

/// 1단계: 상담교수 방식 선택(온라인/방문). 온라인 흐름에서만 쓰인다 —
/// 방문이면 [AdvisorMethodAndScheduleStep]이 같은 자리에서 시간 선택까지
/// 함께 보여준다.
class AdvisorMethodStep extends StatelessWidget {
  const AdvisorMethodStep({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.selectedMethod,
    required this.methodStepValid,
    required this.onSelectMethod,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final ConsultationMethod selectedMethod;
  final bool methodStepValid;
  final ValueChanged<ConsultationMethod> onSelectMethod;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return AdvisorApplyCard(
      children: [
        AdvisorApplyStepHeader(
          title: '무슨 상담을 원하세요?',
          step: step,
          totalSteps: totalSteps,
        ),
        const SizedBox(height: 15),
        AdvisorApplyProgressDots(step: step, totalSteps: totalSteps),
        const SizedBox(height: 26),
        _MethodToggle(
          selectedMethod: selectedMethod,
          onSelectMethod: onSelectMethod,
        ),
        const SizedBox(height: 28),
        AdvisorApplyPrimaryButton(
          label: '다음',
          enabled: methodStepValid,
          onTap: onNext,
        ),
      ],
    );
  }
}

/// 1단계(방문 흐름): 상담교수 방식 선택 + 방문 날짜·시간 선택을 한 카드에서
/// 처리한다. 그 뒤 전화번호 → 이메일 → 상담 내용은 온라인과 같다(학교 방문
/// 신청에도 전화번호·이메일이 들어간다).
class AdvisorMethodAndScheduleStep extends StatelessWidget {
  const AdvisorMethodAndScheduleStep({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.selectedMethod,
    required this.methodStepValid,
    required this.onSelectMethod,
    required this.onNext,
    required this.selectedVisitDate,
    required this.selectedVisitTime,
    required this.onSelectVisitDate,
    required this.onSelectVisitTime,
    required this.times,
    required this.timesLoading,
    required this.timesError,
    required this.onRetryTimes,
  });

  final int step;
  final int totalSteps;
  final ConsultationMethod selectedMethod;
  final bool methodStepValid;
  final ValueChanged<ConsultationMethod> onSelectMethod;
  final VoidCallback onNext;
  final DateTime? selectedVisitDate;
  final String? selectedVisitTime;
  final ValueChanged<DateTime> onSelectVisitDate;
  final ValueChanged<String> onSelectVisitTime;

  /// 고른 날짜의 상담 가능 시간과 그 조회 상태.
  final List<String> times;
  final bool timesLoading;
  final String? timesError;
  final VoidCallback onRetryTimes;

  @override
  Widget build(BuildContext context) {
    return AdvisorApplyCard(
      children: [
        AdvisorApplyStepHeader(
          title: '무슨 상담을 원하세요?',
          step: step,
          totalSteps: totalSteps,
        ),
        const SizedBox(height: 15),
        AdvisorApplyProgressDots(step: step, totalSteps: totalSteps),
        const SizedBox(height: 26),
        _MethodToggle(
          selectedMethod: selectedMethod,
          onSelectMethod: onSelectMethod,
        ),
        const SizedBox(height: 14),
        const Text(
          '상담 시간',
          style: TextStyle(
            color: AppColors.textSub,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        AdvisorVisitSchedulePicker(
          times: times,
          timesLoading: timesLoading,
          timesError: timesError,
          onRetryTimes: onRetryTimes,
          selectedVisitDate: selectedVisitDate,
          selectedVisitTime: selectedVisitTime,
          onSelectVisitDate: onSelectVisitDate,
          onSelectVisitTime: onSelectVisitTime,
        ),
        const SizedBox(height: 28),
        AdvisorApplyPrimaryButton(
          label: '다음',
          enabled: methodStepValid,
          onTap: onNext,
        ),
      ],
    );
  }
}

class _MethodToggle extends StatelessWidget {
  const _MethodToggle({
    required this.selectedMethod,
    required this.onSelectMethod,
  });

  final ConsultationMethod selectedMethod;
  final ValueChanged<ConsultationMethod> onSelectMethod;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MethodButton(
            method: ConsultationMethod.online,
            selectedMethod: selectedMethod,
            onSelectMethod: onSelectMethod,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MethodButton(
            method: ConsultationMethod.visit,
            selectedMethod: selectedMethod,
            onSelectMethod: onSelectMethod,
          ),
        ),
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.method,
    required this.selectedMethod,
    required this.onSelectMethod,
  });

  final ConsultationMethod method;
  final ConsultationMethod selectedMethod;
  final ValueChanged<ConsultationMethod> onSelectMethod;

  @override
  Widget build(BuildContext context) {
    final selected = selectedMethod == method;
    return Pressable(
      onTap: () => onSelectMethod(method),
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppColors.blue : _methodBorder),
        ),
        child: Text(
          method.label,
          style: TextStyle(
            color: selected ? AppColors.blueText : _methodText,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
