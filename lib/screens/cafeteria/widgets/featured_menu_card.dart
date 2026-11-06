import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 맨 앞 메뉴를 크게 보여주는 대표 카드 — 분류/인기 배지, 즐겨찾기 하트, 대표 메뉴
/// 두 줄, 곁들임 칩, 가격. v7 디자인 48에는 대표 카드가 따로 없어서, 같은 화면의
/// 메뉴 카드 모양(흰 바탕·테두리·옅은 그림자·파란 배지와 가격)을 넓게 늘려 썼다.
class FeaturedMenuCard extends StatelessWidget {
  const FeaturedMenuCard({
    required this.item,
    required this.favorite,
    required this.onFavoriteTap,
    super.key,
  });

  final CafeteriaMenuItem item;
  final bool favorite;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    // 앞의 두 가지가 대표 메뉴(큰 글씨), 나머지는 곁들임 칩.
    final mains = item.dishes.take(2).toList();
    final sides = item.dishes.skip(2).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CafeteriaColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (item.category != null) ...[
                _Chip(
                  label: item.category!,
                  background: AppColors.blueSoft,
                  foreground: AppColors.blueText,
                ),
                const SizedBox(width: 6),
              ],
              if (item.popularRank != null)
                _Chip(
                  label: '인기 ${item.popularRank}위',
                  icon: Icons.local_fire_department_rounded,
                  background: AppColors.fill,
                  foreground: AppColors.textBody,
                ),
              const Spacer(),
              Pressable.icon(
                onTap: onFavoriteTap,
                child: Icon(
                  favorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: favorite ? AppColors.blue : AppColors.textSub,
                  size: 24,
                  semanticLabel: favorite ? '즐겨찾기 해제' : '즐겨찾기',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            mains.join('\n'),
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: -0.66,
            ),
          ),
          if (sides.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final side in sides)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      side,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.payments_rounded,
                size: 16,
                color: AppColors.textSub,
              ),
              const SizedBox(width: 6),
              Text(
                item.venue.priceLabel,
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                item.priceText,
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
