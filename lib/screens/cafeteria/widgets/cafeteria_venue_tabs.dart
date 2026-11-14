import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 전체/학생식당/교직원식당/카페 탭. [selected]가 null이면 "전체"다. 선택한 탭은
/// 남색 바탕에 흰 글자, 나머지는 연한 회색.
class CafeteriaVenueTabs extends StatelessWidget {
  const CafeteriaVenueTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CafeteriaVenue? selected;
  final ValueChanged<CafeteriaVenue?> onChanged;

  static const _icons = {
    CafeteriaVenue.student: Icons.restaurant_rounded,
    CafeteriaVenue.staff: Icons.badge_rounded,
    CafeteriaVenue.cafe: Icons.coffee_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tab(null, '전체'),
          for (final venue in CafeteriaVenue.values) ...[
            const SizedBox(width: 6),
            _tab(venue, venue.label),
          ],
        ],
      ),
    );
  }

  Widget _tab(CafeteriaVenue? venue, String label) {
    final isSelected = venue == selected;
    final color = isSelected ? Colors.white : CafeteriaColors.tabText;
    return Pressable(
      onTap: () => onChanged(venue),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.inkNavy : AppColors.fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (venue != null) ...[
              Icon(_icons[venue], size: 15, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
