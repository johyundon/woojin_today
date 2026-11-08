import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// 검색 결과 묶음 위의 머리말(모아보기의 파란 작은 라벨과 같은 모양).
class SearchSectionHeading extends StatelessWidget {
  const SearchSectionHeading({super.key, required this.label, this.count});

  final String label;

  /// 결과 개수. null이면 보여 주지 않는다.
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.blueText,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '$count',
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 결과 줄들을 담는 흰 카드(모아보기 "학교생활" 카드와 같은 모양).
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

/// 검색 결과 한 줄: 아이콘 상자 + 제목·부제 + 오른쪽 화살표.
/// 모아보기 "학교생활" 목록 줄과 같은 크기·글자다.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
    this.titleMaxLines = 1,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  /// 제목 최대 줄 수(공지 제목처럼 긴 글은 2줄).
  final int titleMaxLines;

  static const _divider = Color(0xFFE8EAEE);

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: _divider))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.blueText, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: titleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 16,
                      height: 1.4,
                      letterSpacing: -0.32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textBody,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
