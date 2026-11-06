import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 학생식당/교직원식당 탭. 선택한 탭은 남색 바탕에 흰 글자, 나머지는 연한 회색.
class CafeteriaVenueTabs extends StatelessWidget {
  const CafeteriaVenueTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CafeteriaVenue selected;
  final ValueChanged<CafeteriaVenue> onChanged;

  static const _icons = {
    CafeteriaVenue.student: Icons.restaurant_rounded,
    CafeteriaVenue.staff: Icons.badge_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final venue in CafeteriaVenue.values) ...[
            if (venue.index > 0) const SizedBox(width: 6),
            Pressable(
              onTap: () => onChanged(venue),
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: venue == selected ? AppColors.inkNavy : AppColors.fill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[venue],
                      size: 15,
                      color: venue == selected
                          ? Colors.white
                          : CafeteriaColors.tabText,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      venue.label,
                      style: TextStyle(
                        color: venue == selected
                            ? Colors.white
                            : CafeteriaColors.tabText,
                        fontSize: 13,
                        fontWeight: venue == selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
