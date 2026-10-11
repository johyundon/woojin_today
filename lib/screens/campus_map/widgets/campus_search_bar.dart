import 'package:flutter/material.dart';

import '../campus_map_colors.dart';

/// 지도 화면 상단의 출발지/목적지 검색바. 가운데 화살표로 방향을 보여주고,
/// 오른쪽 X로 둘 다 초기화한다.
class CampusSearchBar extends StatelessWidget {
  const CampusSearchBar({
    required this.originName,
    required this.destinationName,
    required this.onTapOrigin,
    required this.onTapDestination,
    required this.onReset,
  });

  final String? originName;
  final String? destinationName;
  final VoidCallback onTapOrigin;
  final VoidCallback onTapDestination;
  final VoidCallback onReset;

  static const String _placeholder = '건물 선택';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _BuildingField(
              caption: '출발지',
              label: originName ?? _placeholder,
              isPlaceholder: originName == null,
              onTap: onTapOrigin,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward,
              color: CampusMapColors.textSecondary,
              size: 18,
            ),
          ),
          Expanded(
            child: _BuildingField(
              caption: '목적지',
              label: destinationName ?? _placeholder,
              isPlaceholder: destinationName == null,
              onTap: onTapDestination,
            ),
          ),
          IconButton(
            onPressed: onReset,
            icon: const Icon(
              Icons.close,
              color: CampusMapColors.danger,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingField extends StatelessWidget {
  const _BuildingField({
    required this.caption,
    required this.label,
    required this.isPlaceholder,
    required this.onTap,
  });

  /// 이 칸이 출발지인지 목적지인지 보여주는 작은 라벨 — 전에는 화살표
  /// 방향만으로 구분해야 해서 헷갈렸다.
  final String caption;
  final String label;

  /// true면 아직 건물을 안 고른 상태(label이 "건물 선택" placeholder)라
  /// 흐린 회색으로, 실제로 고른 건물명이면 흰색으로 보여준다.
  final bool isPlaceholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              caption,
              style: const TextStyle(
                color: CampusMapColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isPlaceholder
                    ? CampusMapColors.textSecondary
                    : CampusMapColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
