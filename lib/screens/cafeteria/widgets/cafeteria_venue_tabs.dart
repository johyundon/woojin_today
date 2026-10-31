import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../models/cafeteria_menu.dart';

/// 학생식당/교직원식당 탭. 선택한 탭은 흰색 알약, 나머지는 어두운 파랑.
class CafeteriaVenueTabs extends StatelessWidget {
  const CafeteriaVenueTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CafeteriaVenue selected;
  final ValueChanged<CafeteriaVenue> onChanged;

  static const _icons = {
    CafeteriaVenue.student: Icons.restaurant,
    CafeteriaVenue.staff: Icons.work,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final venue in CafeteriaVenue.values) ...[
            Pressable(
              onTap: () => onChanged(venue),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: venue == selected
                      ? Colors.white
                      : AppColors.cobaltDeep,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[venue],
                      size: 16,
                      color: venue == selected ? AppColors.ink : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      venue.label,
                      style: TextStyle(
                        color: venue == selected ? AppColors.ink : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
