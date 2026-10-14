import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/notice_item.dart';

/// 공지의 분류 칩 묶음 — "필독"(있으면, 검정) + 분류(학사/장학/학과/행사).
/// 목록 카드와 상세 화면이 같은 모양을 쓴다.
class NoticeTagChips extends StatelessWidget {
  const NoticeTagChips({required this.notice, super.key});

  final NoticeItem notice;

  static Color _tagBackground(NoticeTag tag) => switch (tag) {
    NoticeTag.academic => AppColors.cobalt,
    NoticeTag.scholarship => AppColors.blushPink,
    NoticeTag.department => AppColors.lime,
    NoticeTag.event => const Color(0xFFF1EEE9),
  };

  static Color _tagForeground(NoticeTag tag) =>
      tag == NoticeTag.academic ? Colors.white : AppColors.ink;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (notice.isRequired) ...[
          const _TagChip(
            label: '필독',
            background: AppColors.ink,
            foreground: Colors.white,
          ),
          const SizedBox(width: 6),
        ],
        _TagChip(
          label: notice.tag.label,
          background: _tagBackground(notice.tag),
          foreground: _tagForeground(notice.tag),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
