import 'package:flutter/material.dart';

import '../campus_map_colors.dart';

/// 경로가 그려졌을 때 지도 위에 뜨는 "도보 N분 · 약 Mm" 알약 배너.
class RouteInfoBanner extends StatelessWidget {
  const RouteInfoBanner({
    required this.walkMinutes,
    required this.distanceMeters,
  });

  final int walkMinutes;
  final double distanceMeters;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CampusMapColors.accent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '도보 $walkMinutes분 · 약 ${distanceMeters.round()}m',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
