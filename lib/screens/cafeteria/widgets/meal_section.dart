import 'package:flutter/material.dart';

import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';
import 'menu_item_card.dart';

/// 아침/점심/저녁 섹션 하나(아코디언). 제목 오른쪽 화살표를 눌러 이 섹션만
/// 독립적으로 펼치거나 접는다(다른 섹션 상태와 무관 — 한 번에 여러 섹션을
/// 동시에 펼쳐둘 수 있다).
class MealSection extends StatelessWidget {
  const MealSection({
    super.key,
    required this.title,
    required this.items,
    required this.expanded,
    required this.onToggle,
  });

  final String title;
  final List<CafeteriaMenuItem> items;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CafeteriaColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: CafeteriaColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: items.isEmpty
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      '등록된 메뉴가 없어요',
                      style: TextStyle(
                        color: CafeteriaColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (final item in items) MenuItemCard(item: item),
                    ],
                  ),
          ),
      ],
    );
  }
}
