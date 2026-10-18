import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';
import 'advisor_consultation_detail_dialog.dart';

const Color _rowBackground = Color(0xFFF1F0F7);
const Color _mutedText = Color(0xFF7C7B88);
const Color _cancelChipBackground = Color(0xFFECEBF3);

/// 상담 이력 한 줄(v4 리디자인) — 연보라색 행 안에 날짜 + "{상담방식} ·
/// {상태}" 2줄, 상태 배지("취소"는 회색, 그 외는 코발트 톤), "상세보기" 링크.
class AdvisorConsultationHistoryCard extends StatelessWidget {
  const AdvisorConsultationHistoryCard({super.key, required this.history});

  final ConsultationHistory history;

  bool get _isCancelled => history.status.contains('취소');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _rowBackground,
        borderRadius: BorderRadius.circular(18),
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
                    color: AppColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${history.method} · ${history.status}',
                  style: const TextStyle(color: _mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _isCancelled
                  ? _cancelChipBackground
                  : AppColors.cobalt.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _isCancelled ? '취소' : '완료',
              style: TextStyle(
                color: _isCancelled ? _mutedText : AppColors.cobalt,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () =>
                showAdvisorConsultationDetailSheet(context, history: history),
            child: const Text(
              '상세보기',
              style: TextStyle(
                color: AppColors.cobalt,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
