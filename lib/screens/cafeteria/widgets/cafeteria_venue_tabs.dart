import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../cafeteria_colors.dart';
import '../models/cafeteria_menu.dart';

/// 전체/학생식당/생활관식당/교직원식당 탭. [selected]가 null이면 "전체"다. 선택한 탭은
/// 남색 바탕에 흰 글자, 나머지는 연한 회색(디자인 "07 학식").
class CafeteriaVenueTabs extends StatelessWidget {
  const CafeteriaVenueTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final CafeteriaVenue? selected;
  final ValueChanged<CafeteriaVenue?> onChanged;

  /// 탭에서 숨기는 식당. 카페는 학교 사이트에 메뉴가 없어 늘 비어 있었다.
  static const hidden = {CafeteriaVenue.cafe};

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _tab(null, '전체'),
          for (final venue in CafeteriaVenue.values)
            if (!hidden.contains(venue)) ...[
              const SizedBox(width: 8),
              _tab(venue, venue.label),
            ],
        ],
      ),
    );
  }

  Widget _tab(CafeteriaVenue? venue, String label) {
    final isSelected = venue == selected;
    return Pressable(
      onTap: () => onChanged(venue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.inkNavy : AppColors.fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : CafeteriaColors.tabText,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
