import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
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
                    color: AppColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${notice.author} · ${notice.date} · 조회 ${notice.viewCount}',
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Pressable.effect(
            child: FilledButton(
              onPressed: onCheck,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blueSoft,
                foregroundColor: AppColors.blueText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '대상자 확인',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
