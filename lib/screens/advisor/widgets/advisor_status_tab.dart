import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../services/advisor_consultation_mock_data.dart';
import 'advisor_consultation_history_card.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _trackBackground = Color(0xFFE8E7F0);
const Color _divider = Color(0xFFEEEDF4);

/// "상담 현황" 탭 본문(v4 리디자인) — 흰 카드 하나에 상담 인정 횟수 +
/// 진행률 바, 학기별 인정 횟수 표, 구분선, 상담 이력 리스트를 전부 담는다.
class AdvisorStatusTab extends StatelessWidget {
  const AdvisorStatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildApprovedCount(),
              const SizedBox(height: 16),
              _buildSemesterTable(),
              const SizedBox(height: 12),
              const Divider(height: 1, color: _divider),
              const SizedBox(height: 12),
              for (
                var i = 0;
                i < AdvisorConsultationMockData.history.length;
                i++
              )
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == AdvisorConsultationMockData.history.length - 1
                        ? 0
                        : 10,
                  ),
                  child: AdvisorConsultationHistoryCard(
                    history: AdvisorConsultationMockData.history[i],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedCount() {
    const approved = AdvisorConsultationMockData.approvedCount;
    const required = AdvisorConsultationMockData.requiredCount;
    final progress = (approved / required).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '지금까지 상담 인정 횟수',
          style: TextStyle(color: _mutedText, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            const Text(
              '$approved',
              style: TextStyle(
                color: AppColors.cobalt,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '회',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '/ $required회',
              style: TextStyle(color: _mutedText, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: _trackBackground,
            valueColor: const AlwaysStoppedAnimation(AppColors.cobalt),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterTable() {
    const header = AdvisorConsultationMockData.semesterStatHeader;
    const rows = AdvisorConsultationMockData.semesterStatRows;
    final lastColumn = header.length - 2; // '학기' 라벨 칸 제외, 0-based.

    return Table(
      columnWidths: const {0: FlexColumnWidth(0.9)},
      children: [
        TableRow(
          children: [for (final h in header) _buildCell(h, isHeader: true)],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _buildCell(row.label, isHeader: true, alignLeft: true),
              for (var i = 0; i < row.values.length; i++)
                _buildCell(row.values[i], isTotal: i == lastColumn),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isTotal = false,
    bool alignLeft = false,
  }) {
    final color = isTotal
        ? AppColors.cobalt
        : isHeader
        ? _mutedText
        : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: isHeader || isTotal ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
