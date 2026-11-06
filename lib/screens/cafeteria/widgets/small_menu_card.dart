import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 코너별 메뉴 카드 — 코너/분류 배지와 아이콘, 메뉴 두 줄, 가격. 두 장씩 나란히
/// 놓는다(v7 디자인 48 cafeteria의 메뉴 카드).
class SmallMenuCard extends StatelessWidget {
  const SmallMenuCard({required this.item, super.key});

  final CafeteriaMenuItem item;

  /// 분류에 맞는 아이콘(디자인: 한식 rice_bowl, 일품 ramen_dining, 분식
  /// lunch_dining, 그 밖 restaurant).
  static IconData _iconFor(String? category) {
    final c = category ?? '';
    if (c.contains('한식')) return Icons.rice_bowl_rounded;
    if (c.contains('일품') || c.contains('일식') || c.contains('중식')) {
      return Icons.ramen_dining_rounded;
    }
    if (c.contains('분식') || c.contains('양식')) {
      return Icons.lunch_dining_rounded;
    }
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CafeteriaColors.cardBorder),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 분류가 있으면 코너 이름 뒤에 함께 보여준다("파스타랩 · 양식").
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category == null
                          ? item.restaurant
                          : '${item.restaurant} · ${item.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.blueText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _iconFor(item.category),
                  size: 22,
                  color: AppColors.textSub,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.dishes.take(2).join('\n'),
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.4,
              letterSpacing: -0.51,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 10),
          Text(
            item.priceText,
            style: const TextStyle(
              color: AppColors.blueText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
