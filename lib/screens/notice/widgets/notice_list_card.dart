import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../mileage/widgets/mileage_target_confirm_dialog.dart';
import '../models/notice_item.dart';
import '../notice_detail_screen.dart';

/// 공지 카드 한 건.
///
/// [NoticeItem.scholarshipNotice]가 있으면(마일리지 "대상자" 공지) 기존
/// 마일리지 화면의 "대상자 확인" 버튼 + 다이얼로그를 그대로 재사용한다.
/// 없으면 카드 전체가 탭 가능하고, 누르면 [NoticeDetailScreen]으로 이동한다.
class NoticeListCard extends StatelessWidget {
  const NoticeListCard({super.key, required this.notice});

  final NoticeItem notice;

  @override
  Widget build(BuildContext context) {
    final scholarshipNotice = notice.scholarshipNotice;

    return GestureDetector(
      onTap: scholarshipNotice != null
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NoticeDetailScreen(notice: notice),
              ),
            ),
      child: Container(
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          notice.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (notice.isNew) ...[
                        const SizedBox(width: 6),
                        _NewBadge(),
                      ],
                    ],
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
            if (scholarshipNotice != null) ...[
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () => showMileageTargetConfirmDialog(
                  context,
                  notice: scholarshipNotice,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  '대상자 확인',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'new',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
