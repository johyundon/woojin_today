import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'advisor_apply_common.dart';

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
              const SizedBox(height: 14),
              // 연파랑 원 + 파란 테두리 안의 체크.
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.blue, width: 2),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.blue,
                  size: 27,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '상담 신청이 완료됐어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '교수님이 확인하면 알림으로 알려드릴게요',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AdvisorApplyPrimaryButton(
          label: '상담 현황 보기',
          enabled: true,
          onTap: onViewStatus,
        ),
      ],
    );
  }
}
