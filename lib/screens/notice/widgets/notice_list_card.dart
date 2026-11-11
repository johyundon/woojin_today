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
    this.matchSnippet,
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

  /// 검색어가 제목이 아니라 본문에 있을 때 보여줄 본문 한 줄. null이면 안 보인다.
  final String? matchSnippet;

  /// v7 시안의 새 글 점(빨강)과 꺼진 북마크 아이콘(따뜻한 회색).
  static const _unreadDot = Color(0xFFE64343);
  static const _bookmarkOff = Color(0xFFC9C5BD);

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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 25,
              child: Row(
                children: [
                  NoticeTagChips(notice: notice),
                  if (unread) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _unreadDot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // 아이콘은 17이지만 누르기 쉽게 왼쪽으로 넓힌 영역을 받는다.
                  Pressable.icon(
                    onTap: onBookmarkTap,
                    child: SizedBox(
                      width: 40,
                      height: 25,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            bookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            key: ValueKey(bookmarked),
                            size: 17,
                            color: bookmarked ? AppColors.blue : _bookmarkOff,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Text(
              notice.title,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              '${notice.author} · $_shortDate',
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (matchSnippet != null) ...[
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: '본문  ',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: matchSnippet),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
