import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/cafeteria_menu.dart';

/// 코너별 작은 메뉴 카드 — 코너 이름, 메뉴 두 줄, 가격. 두 장씩 나란히 놓는다.
class SmallMenuCard extends StatelessWidget {
  const SmallMenuCard({
    required this.item,
    required this.background,
    super.key,
  });

  final CafeteriaMenuItem item;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.18),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                // 분류가 있으면 코너 이름 뒤에 함께 보여준다("파스타랩 · 양식").
                child: Text(
                  item.category == null
                      ? item.restaurant
                      : '${item.restaurant} · ${item.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(Icons.restaurant, size: 16, color: AppColors.ink),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.dishes.take(2).join('\n'),
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.priceText,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
