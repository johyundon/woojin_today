import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';
import '../services/advisor_consultation_mock_data.dart';
import 'advisor_apply_common.dart';
import 'advisor_apply_visit_schedule_picker.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _chipBackground = Color(0xFFF1F0F7);

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
        const SizedBox(height: 12),
        AdvisorApplyProgressDots(step: step, totalSteps: totalSteps),
        const SizedBox(height: 14),
        _MethodToggle(
          selectedMethod: selectedMethod,
          onSelectMethod: onSelectMethod,
        ),
        const SizedBox(height: 20),
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
/// 처리한다(방문은 전화/이메일 단계를 거치지 않는다).
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

  @override
  Widget build(BuildContext context) {
    final times = AdvisorConsultationMockData.visitAvailableTimes;

    return AdvisorApplyCard(
      children: [
        AdvisorApplyStepHeader(
          title: '무슨 상담을 원하세요?',
          step: step,
          totalSteps: totalSteps,
        ),
        const SizedBox(height: 12),
        AdvisorApplyProgressDots(step: step, totalSteps: totalSteps),
        const SizedBox(height: 14),
        _MethodToggle(
          selectedMethod: selectedMethod,
          onSelectMethod: onSelectMethod,
        ),
        const SizedBox(height: 16),
        const Text(
          '상담 시간',
          style: TextStyle(
            color: _mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        if (times.isEmpty)
          const AdvisorNoVisitSlotsNotice()
        else
          AdvisorVisitSchedulePicker(
            times: times,
            selectedVisitDate: selectedVisitDate,
            selectedVisitTime: selectedVisitTime,
            onSelectVisitDate: onSelectVisitDate,
            onSelectVisitTime: onSelectVisitTime,
          ),
        const SizedBox(height: 20),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _chipBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MethodButton(
              method: ConsultationMethod.online,
              selectedMethod: selectedMethod,
              onSelectMethod: onSelectMethod,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _MethodButton(
              method: ConsultationMethod.visit,
              selectedMethod: selectedMethod,
              onSelectMethod: onSelectMethod,
            ),
          ),
        ],
      ),
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
    final icon = method == ConsultationMethod.online
        ? Icons.videocam_rounded
        : Icons.meeting_room_rounded;
    return GestureDetector(
      onTap: () => onSelectMethod(method),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: selected ? AppColors.cobalt : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : _mutedText),
            const SizedBox(width: 6),
            Text(
              method.label,
              style: TextStyle(
                color: selected ? Colors.white : _mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
