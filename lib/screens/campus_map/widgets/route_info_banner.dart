import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../campus_map_colors.dart';

/// 경로가 그려졌을 때 지도 위에 뜨는 "도보 N분 · 약 Mm" 흰 띠(v7).
class RouteInfoBanner extends StatelessWidget {
  const RouteInfoBanner({
    super.key,
    required this.walkMinutes,
    required this.distanceMeters,
  });

  final int walkMinutes;
  final double distanceMeters;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_walk_rounded,
            color: CampusMapColors.accent,
            size: 15,
          ),
          const SizedBox(width: 4),
          Text(
            '도보 $walkMinutes분 · 약 ${distanceMeters.round()}m',
            style: const TextStyle(
              color: CampusMapColors.textPrimary,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
