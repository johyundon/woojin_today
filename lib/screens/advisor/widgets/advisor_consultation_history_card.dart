import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';
import 'advisor_consultation_detail_dialog.dart';

/// 상담 이력 카드 한 건 — 왼쪽에 날짜 + "{상담방식} · {상태}" 2줄, 오른쪽에
/// 주황 "상세보기" 링크.
class AdvisorConsultationHistoryCard extends StatelessWidget {
  const AdvisorConsultationHistoryCard({super.key, required this.history});

  final ConsultationHistory history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  history.date,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${history.method} · ${history.status}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () =>
                showAdvisorConsultationDetailDialog(context, history: history),
            child: const Text(
              '상세보기',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
