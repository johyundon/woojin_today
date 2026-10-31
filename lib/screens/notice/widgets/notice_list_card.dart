import 'package:flutter/material.dart';

import '../../../services/notice_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../../mileage/widgets/mileage_target_confirm_dialog.dart';
import '../models/notice_item.dart';
import '../notice_detail_screen.dart';
import 'notice_tag_chips.dart';

/// 공지 카드 한 건 — 분류 칩(필독/학사/장학...) + 새 글 점 + 북마크, 제목,
/// "발행처 · MM.DD".
///
/// [NoticeItem.scholarshipNotice]가 있으면(마일리지 "대상자" 공지) 카드를
/// 눌렀을 때 기존 마일리지 화면의 "대상자 확인" 다이얼로그가 열리고, 없으면
/// [NoticeDetailScreen]으로 이동한다.
class NoticeListCard extends StatelessWidget {
  const NoticeListCard({
    required this.notice,
    required this.bookmarked,
    required this.unread,
    required this.onBookmarkTap,
    required this.onOpened,
    this.detailService,
    super.key,
  });

  final NoticeItem notice;
  final bool bookmarked;

  /// 아직 안 읽은 새 글이면 true — 분류 칩 옆에 빨간 점을 그린다.
  final bool unread;
  final VoidCallback onBookmarkTap;

  /// 카드를 눌러 공지를 열 때(상세 화면/대상자 확인 창 이동 직전) 호출된다.
  final VoidCallback onOpened;

  /// 상세 화면이 본문을 받을 때 쓸 서비스(테스트에서 가짜를 넘긴다).
  final NoticeServiceBase? detailService;

  static const _mutedText = Color(0xFF6B6B70);

  /// "2026.10.08" → "10.08".
  String get _shortDate {
    final parts = notice.date.split('.');
    return parts.length == 3 ? '${parts[1]}.${parts[2]}' : notice.date;
  }

  void _open(BuildContext context) {
    onOpened();
    final scholarship = notice.scholarshipNotice;
    if (scholarship != null) {
      showMileageTargetConfirmDialog(context, notice: scholarship);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NoticeDetailScreen(notice: notice, service: detailService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => _open(context),
      pressedScale: 0.97,
      pressedOpacity: 0.85,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      NoticeTagChips(notice: notice),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4D4F),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notice.title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${notice.author} · $_shortDate',
                    style: const TextStyle(color: _mutedText, fontSize: 12),
                  ),
                ],
              ),
            ),
            Pressable.icon(
              onTap: onBookmarkTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    key: ValueKey(bookmarked),
                    color: bookmarked
                        ? AppColors.cobalt
                        : const Color(0xFFB5B5BC),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
