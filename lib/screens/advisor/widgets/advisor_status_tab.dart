import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../services/advisor_consultation_mock_data.dart';
import 'advisor_consultation_history_card.dart';

/// "지도교수 상담 현황" 탭 본문 — 상담 인정 횟수 카드, 학기별 인정 횟수
/// 표, 상담 이력 리스트.
class AdvisorStatusTab extends StatelessWidget {
  const AdvisorStatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _buildApprovedCountCard(),
        const SizedBox(height: 16),
        _buildSemesterTable(),
        const SizedBox(height: 20),
        for (final history in AdvisorConsultationMockData.history)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AdvisorConsultationHistoryCard(history: history),
          ),
      ],
    );
  }

  Widget _buildApprovedCountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '지금까지의 상담 인정 횟수',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${AdvisorConsultationMockData.approvedCount}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '회 / ${AdvisorConsultationMockData.requiredCount}회',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSemesterTable() {
    const header = AdvisorConsultationMockData.semesterStatHeader;
    const rows = AdvisorConsultationMockData.semesterStatRows;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.2),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [for (final h in header) _buildCell(h, isHeader: true)],
          ),
          for (var i = 0; i < rows.length; i++)
            TableRow(
              decoration: i == rows.length - 1
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
              children: [
                _buildCell(rows[i].label),
                for (final v in rows[i].values)
                  _buildCell(v, isTotal: rows[i].label == '합계'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    final color = isHeader
        ? AppColors.textSecondary
        : isTotal
        ? AppColors.accent
        : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: isHeader ? 12 : 13,
          fontWeight: isHeader || isTotal ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }
}
