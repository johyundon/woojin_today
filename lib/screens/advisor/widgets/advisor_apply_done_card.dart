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
        Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.cobalt,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '상담 신청이 완료됐어요',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              '교수님이 확인하면 알림으로 알려드릴게요',
              textAlign: TextAlign.center,
              style: TextStyle(color: _mutedText, fontSize: 14, height: 1.4),
            ),
          ],
        ),
        const SizedBox(height: 18),
        AdvisorApplyPrimaryButton(
          label: '상담 현황 보기',
          enabled: true,
          onTap: onViewStatus,
        ),
      ],
    );
  }
}
