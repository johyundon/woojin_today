import 'package:flutter/material.dart';

import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 메뉴 카드 하나 — 왼쪽 주황 pill 배지(식당/코너 이름) + 오른쪽 메뉴 구성/가격.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.item});

  final CafeteriaMenuItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CafeteriaColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: CafeteriaColors.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item.restaurant,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dishesText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: CafeteriaColors.textPrimary,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.priceText,
                  style: const TextStyle(
                    color: CafeteriaColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
