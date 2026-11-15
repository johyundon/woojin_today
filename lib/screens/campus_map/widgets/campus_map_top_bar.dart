import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 지도 위쪽 카테고리 칩 하나(이름 + 아이콘 + 누르면 핀으로 띄울 장소).
class CampusMapCategory {
  const CampusMapCategory(this.label, this.icon, this.places);

  final String label;
  final IconData icon;

  /// [campusBuildings]의 건물 이름들.
  final List<String> places;
}

/// 위쪽에 보이는 칩. 누르면 지도에 그 종류 장소만 핀으로 띄운다. 사용자
/// 요청으로 지금은 하나도 없어서 칩 줄 자체가 안 보인다.
const List<CampusMapCategory> campusMapCategories = [];

/// 사용자 요청으로 지금은 숨겨 둔 칩. 다시 보이려면 [campusMapCategories]로
/// 옮긴다.
///
/// *** 미검증 *** 식당은 학식이 있는 학생회관과 에그2000만 넣었다. 기숙사
/// 식당 등 건물 목록에 없는 곳은 빠져 있다.
const List<CampusMapCategory> hiddenCampusMapCategories = [
  // 정류장은 학교 안 정류장만. 정문(짭정문) 정류장은 학생회관에서 2km 넘게
  // 떨어져 있어 뺐다.
  CampusMapCategory('정류장', Icons.directions_bus_rounded, ['학생회관(교내순환)']),
  CampusMapCategory('편의시설', Icons.local_cafe_rounded, [
    '학생회관 CU',
    '여자기숙사 CU',
    '남자기숙사 CU',
    '학생회관 그라찌에',
    '중앙도서관 그라찌에',
    '공차 대진대점',
    '행복베이커리',
    '학생회관 서점',
    '학생회관 안경점',
    '구내안경원',
    '국민은행 대진대점',
  ]),
  CampusMapCategory('식당', Icons.restaurant_rounded, ['학생회관', '학생회관 에그2000']),
];

/// 지도 기본 화면의 위쪽 흰 카드 — 뒤로가기와 가운데 "캠퍼스 지도" 제목,
/// 그 아래 검색창, 카테고리 칩(지금은 없음).
///
/// 검색창은 글자를 직접 받지 않고, 누르면 [onTapSearch]로 검색 화면을 연다.
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

  static const String title = '캠퍼스 지도';
  static const String searchHint = '어디를 가시나요? (예: 인문관 302호)';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Text(
                title,
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Pressable.icon(
                  onTap: onBack,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textStrong,
                        size: 22,
                        semanticLabel: '뒤로',
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Pressable(
          onTap: onTapSearch,
          pressedScale: 0.98,
          child: Container(
            height: 44,
            padding: const EdgeInsets.only(left: 12, right: 10),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Text(
                    searchHint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.search_rounded, color: AppColors.textSub, size: 24),
              ],
            ),
          ),
        ),
        if (campusMapCategories.isNotEmpty) ...[
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
