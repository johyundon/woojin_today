import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';

const Color _mutedText = Color(0xFF7C7B88);

/// "상세보기" 바텀시트(v4 리디자인) — 화면 아래에서 올라오며, 제목 +
/// 라벨-값 쌍(신청일시/상태/신청 내용/답변일시/답변 내용) 세로 나열 +
/// 하단 "확인" 버튼.
Future<void> showAdvisorConsultationDetailSheet(
  BuildContext context, {
  required ConsultationHistory history,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _AdvisorConsultationDetailSheet(history: history),
  );
}

class _AdvisorConsultationDetailSheet extends StatelessWidget {
  const _AdvisorConsultationDetailSheet({required this.history});

  final ConsultationHistory history;

  @override
  Widget build(BuildContext context) {
    final detail = history.detail;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        22,
        12,
        22,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E3EC),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '상세보기',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 13),
          _buildRow('신청일시', detail.appliedAt),
          _buildRow('상태', detail.status),
          _buildRow('신청 내용', detail.content),
          _buildRow('답변일시', detail.answeredAt ?? '-'),
          _buildRow('답변 내용', detail.answerContent ?? '-'),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _mutedText, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
