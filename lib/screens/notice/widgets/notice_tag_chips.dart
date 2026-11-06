import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/notice_item.dart';

/// 공지의 분류 칩 묶음 — "필독"(있으면, 파랑) + 분류(학사/장학/시간표/학과/행사).
/// 목록 카드가 쓴다(v7: 둥글기 8, 12px 굵은 글자).
class NoticeTagChips extends StatelessWidget {
  const NoticeTagChips({required this.notice, super.key});

  final NoticeItem notice;

  /// v7 시안의 "행사" 칩 바탕(베이지 회색).
  static const _eventBackground = Color(0xFFEDEAE4);

  static Color _tagBackground(NoticeTag tag) => switch (tag) {
    NoticeTag.academic => AppColors.blue,
    NoticeTag.scholarship => AppColors.blueSoft,
    NoticeTag.timetable => AppColors.blueSoft,
    NoticeTag.department => AppColors.blueSoft,
    NoticeTag.event => _eventBackground,
  };

  static Color _tagForeground(NoticeTag tag) => switch (tag) {
    NoticeTag.academic => Colors.white,
    NoticeTag.timetable || NoticeTag.department => AppColors.blue,
    NoticeTag.scholarship || NoticeTag.event => AppColors.textStrong,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (notice.isRequired) ...[
          const _TagChip(
            label: '필독',
            background: AppColors.blue,
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
