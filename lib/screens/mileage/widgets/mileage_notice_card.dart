import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/mileage_models.dart';

/// 장학 대상자 공지 카드 하나 — 제목/작성자·날짜·조회수 + "대상자 확인" 버튼.
class MileageNoticeCard extends StatelessWidget {
  const MileageNoticeCard({
    super.key,
    required this.notice,
    required this.onCheck,
  });

  final MileageNotice notice;

  /// "대상자 확인" 버튼을 눌렀을 때.
  final VoidCallback onCheck;

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
                  notice.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${notice.author} · ${notice.date} · 조회 ${notice.viewCount}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: onCheck,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              '대상자 확인',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
