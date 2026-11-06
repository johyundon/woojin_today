import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../../../services/advisor_consultation_service.dart';
import 'advisor_consultation_detail_dialog.dart';

const Color _cancelChipBackground = Color(0xFFE8EAEE);

/// 상담 이력 한 줄(v7) — 옅은 회색 행 안에 날짜 + "{상담방식} ·
/// {상태}" 2줄, 상태 배지("취소"는 회색, 그 외는 파랑 톤), "상세보기" 링크.
/// 상세 내용은 "상세보기"를 누를 때 [loadDetail]로 불러온다.
class AdvisorConsultationHistoryCard extends StatelessWidget {
  const AdvisorConsultationHistoryCard({
    super.key,
    required this.record,
    required this.loadDetail,
  });

  final ConsultationRecord record;
  final Future<ConsultationDetailInfo> Function() loadDetail;

  bool get _isCancelled => record.status.contains('취소');

  /// 배지 글자. 서버 상태('상담 완료', '상담 대기' 등)에서 '상담 '을 뗀다.
  String get _badgeLabel =>
      _isCancelled ? '취소' : record.status.replaceFirst('상담 ', '').trim();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  record.appliedAt,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.method} · ${record.status}',
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _isCancelled
                  ? _cancelChipBackground
                  : AppColors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _badgeLabel,
              style: TextStyle(
                color: _isCancelled ? AppColors.textSub : AppColors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Pressable(
            onTap: () => showAdvisorConsultationDetailSheet(
              context,
              loadDetail: loadDetail,
            ),
            child: const Text(
              '상세보기',
              style: TextStyle(
                color: AppColors.blue,
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
