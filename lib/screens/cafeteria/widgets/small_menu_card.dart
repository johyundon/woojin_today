import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 코너별 메뉴 카드(디자인 "07 학식") — 식당 이름 태그(식당마다 색이 다름), 코너 이름, 메뉴 구성,
/// 가격. 두 장씩 나란히 놓고 높이는 178로 고정한다.
class SmallMenuCard extends StatelessWidget {
  const SmallMenuCard({required this.item, super.key});

  final CafeteriaMenuItem item;

  static const double height = 178;

  @override
  Widget build(BuildContext context) {
    final (tagBackground, tagText) = CafeteriaColors.tagColors(item.venue);
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CafeteriaColors.cardBorder),
        boxShadow: CafeteriaColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: tagBackground,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item.venue.label,
              style: TextStyle(
                color: tagText,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.restaurant,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // 남는 높이만큼만 보여주고 넘치면 말줄임표로 자른다.
          Expanded(
            child: Text(
              item.dishesText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: CafeteriaColors.gray700,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
          Text(
            item.priceText,
            style: const TextStyle(
              color: CafeteriaColors.gray700,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
