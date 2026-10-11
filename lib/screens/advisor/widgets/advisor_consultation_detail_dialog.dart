import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';

/// "상세보기" 다이얼로그 — 제목 + 라벨-값 쌍(신청일시/상태/신청내용/답변일시/
/// 답변내용) 세로 나열 + 하단 "확인" 버튼.
Future<void> showAdvisorConsultationDetailDialog(
  BuildContext context, {
  required ConsultationHistory history,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _AdvisorConsultationDetailDialog(history: history),
  );
}

class _AdvisorConsultationDetailDialog extends StatelessWidget {
  const _AdvisorConsultationDetailDialog({required this.history});

  final ConsultationHistory history;

  @override
  Widget build(BuildContext context) {
    final detail = history.detail;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '상세보기',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _buildRow('신청일시', detail.appliedAt),
            const SizedBox(height: 12),
            _buildRow('상태', detail.status),
            const SizedBox(height: 12),
            _buildRow('신청내용', detail.content),
            const SizedBox(height: 12),
            _buildRow('답변일시', detail.answeredAt ?? '-'),
            const SizedBox(height: 12),
            _buildRow('답변내용', detail.answerContent ?? '-'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
