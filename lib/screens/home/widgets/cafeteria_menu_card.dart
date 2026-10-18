import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../cafeteria/services/cafeteria_menu_mock_data.dart';
import 'home_mini_card.dart';

/// 분홍색 "오늘 학식" 카드. 학식 데이터는 목데이터([CafeteriaMenuMockData])라
/// 오늘 점심 메뉴가 등록돼 있으면 첫 번째 식당의 메뉴 두 가지와 가격을, 없으면
/// 안내 문구를 보여준다.
class CafeteriaMenuCard extends StatelessWidget {
  const CafeteriaMenuCard({super.key, required this.now, required this.onTap});

  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lunch = CafeteriaMenuMockData.menuFor(now)?.lunch ?? const [];
    final item = lunch.isEmpty ? null : lunch.first;
    final title = item == null
        ? '오늘의 메뉴는\n무엇일까?'
        : item.dishes.take(2).join('\n');
    return HomeMiniCard(
      icon: Icons.restaurant,
      iconBackground: Colors.white,
      iconColor: AppColors.ink,
      label: '오늘 점심',
      title: title,
      footer: item == null
          ? Text(
              '학식을 조회할 수 있어요',
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    item.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.priceText,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
      backgroundColor: AppColors.blushPink,
      textColor: AppColors.ink,
      onTap: onTap,
    );
  }
}
