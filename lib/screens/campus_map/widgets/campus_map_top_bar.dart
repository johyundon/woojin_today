import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 지도 위쪽 카테고리 칩 하나(이름 + 아이콘).
class CampusMapCategory {
  const CampusMapCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// 시안의 칩 4개. 지금은 지도에 핀을 그리지 않아서 눌러도 고른 모양만 바뀐다.
const List<CampusMapCategory> campusMapCategories = [
  CampusMapCategory('강의동', Icons.school_rounded),
  CampusMapCategory('편의시설', Icons.local_cafe_rounded),
  CampusMapCategory('식당', Icons.restaurant_rounded),
  CampusMapCategory('정류장', Icons.directions_bus_rounded),
];

/// 지도 기본 화면의 위쪽 흰 카드 — 뒤로가기, "어디 가?" 검색창, 카테고리 칩.
///
/// 검색창은 글자를 직접 받지 않고, 누르면 [onTapSearch]로 건물 고르기 패널을
/// 연다.
class CampusMapTopBar extends StatelessWidget {
  const CampusMapTopBar({
    super.key,
    required this.onBack,
    required this.onTapSearch,
    required this.selectedCategory,
    required this.onCategoryTap,
  });

  final VoidCallback onBack;
  final VoidCallback onTapSearch;

  /// 고른 칩의 순서. 아무것도 안 골랐으면 null.
  final int? selectedCategory;
  final ValueChanged<int> onCategoryTap;

  static const String searchHint = '어디 가? (예: 인문관 302호)';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Pressable.icon(
              onTap: onBack,
              child: const SizedBox(
                width: 36,
                height: 52,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textStrong,
                  size: 18,
                  semanticLabel: '뒤로',
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Pressable(
                onTap: onTapSearch,
                pressedScale: 0.98,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.textStrong,
                        size: 22,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          searchHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < campusMapCategories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _CategoryChip(
                  category: campusMapCategories[i],
                  selected: selectedCategory == i,
                  onTap: () => onCategoryTap(i),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CampusMapCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : CampusMapColors.textPrimary;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.inkNavy : AppColors.fill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 17, color: foreground),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                color: foreground,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
