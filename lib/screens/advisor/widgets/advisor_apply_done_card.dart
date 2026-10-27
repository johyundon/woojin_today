import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'advisor_apply_common.dart';

const Color _mutedText = Color(0xFF7C7B88);

/// 상담 신청이 끝난 뒤 보여주는 완료 카드.
class AdvisorDoneCard extends StatelessWidget {
  const AdvisorDoneCard({super.key, required this.onViewStatus});

  /// "상담 현황 보기"를 눌렀을 때 — 상담 현황 탭으로 전환.
  final VoidCallback onViewStatus;

  @override
  Widget build(BuildContext context) {
    return AdvisorApplyCard(
      children: [
        // 안쪽 Column이 글자 폭만큼만 줄어 왼쪽으로 쏠리지 않도록 카드 폭을 꽉
        // 채운다.
        SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              // 라임 체크 원 + 바깥의 옅은 라임 테두리(후광).
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.ink,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cobalt.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '신청 완료',
                  style: TextStyle(
                    color: AppColors.cobalt,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '상담 신청이 완료됐어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '교수님이 확인하면 알림으로 알려드릴게요',
                textAlign: TextAlign.center,
                style: TextStyle(color: _mutedText, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AdvisorApplyPrimaryButton(
          label: '상담 현황 보기',
          enabled: true,
          onTap: onViewStatus,
        ),
      ],
    );
  }
}
