import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 코너별 메뉴 카드(디자인 "07 학식") — 식당 이름 태그(식당마다 색이 다름), 코너 이름, 메뉴 구성,
/// 가격. 두 장씩 나란히 놓는다. 높이는 디자인의 178이 최소이고, 메뉴 구성이
/// 길면 잘라내지 않고 카드가 그만큼 길어진다.
class SmallMenuCard extends StatelessWidget {
  const SmallMenuCard({required this.item, super.key});

  final CafeteriaMenuItem item;

  static const double minHeight = 178;

  @override
  Widget build(BuildContext context) {
    final (tagBackground, tagText) = CafeteriaColors.tagColors(item.venue);
    return Container(
      constraints: const BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CafeteriaColors.cardBorder),
        boxShadow: CafeteriaColors.cardShadow,
      ),
      // 위(태그·코너·메뉴 구성)와 아래(가격)를 양 끝에 붙여, 옆 카드가 더 길어
      // 높이가 늘어나도 가격은 맨 아래에 온다.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
              // 세부 메뉴는 자르지 않고 전부 보여준다.
              Text(
                item.dishesText,
                style: const TextStyle(
                  color: CafeteriaColors.gray700,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
