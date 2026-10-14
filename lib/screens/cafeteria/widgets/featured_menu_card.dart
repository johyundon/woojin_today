import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/mascot_sticker.dart';
import '../models/cafeteria_menu.dart';

/// 큰 라임색 대표 메뉴 카드 — 분류/인기 칩, 즐겨찾기 하트, 대표 메뉴 두 줄, 곁들임
/// 칩, 가격(오른쪽 아래), 마스코트.
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
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (item.category != null) ...[
                    _Chip(
                      label: item.category!,
                      background: AppColors.ink,
                      foreground: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (item.popularRank != null)
                    _Chip(
                      label: '인기 ${item.popularRank}위',
                      icon: Icons.local_fire_department,
                      background: Colors.white,
                      foreground: AppColors.ink,
                    ),
                  const Spacer(),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onFavoriteTap,
                    child: Icon(
                      favorite ? Icons.favorite : Icons.favorite_border,
                      color: AppColors.ink,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(right: 90),
                child: Text(
                  mains.join('\n'),
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (sides.isNotEmpty) ...[
                const SizedBox(height: 14),
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
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          side,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.payments,
                    size: 16,
                    color: AppColors.ink.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.venue.priceLabel,
                    style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.priceText,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Positioned(
            right: 4,
            top: 38,
            child: MascotSticker(width: 84, angle: 0.08),
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
        borderRadius: BorderRadius.circular(99),
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
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
