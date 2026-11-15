import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 길안내 화면 아래쪽 시트(시안 3번) — 도착지 이름, "여유 시간 N분" 배지,
/// "걸어서 N분 · Nm · HH:MM 도착 예정", "안내 시작" 버튼.
class RouteSheet extends StatelessWidget {
  const RouteSheet({
    super.key,
    required this.destinationName,
    required this.walkMinutes,
    required this.distanceMeters,
    required this.arrivalTime,
    required this.onStart,
    this.spareMinutes,
  });

  final String destinationName;
  final int walkMinutes;
  final double distanceMeters;

  /// "12:22" 같은 도착 예정 시각.
  final String arrivalTime;

  /// 연강 사이 여유 시간. 수업 정보 없이 건물끼리 고른 길이면 null(배지 숨김).
  final int? spareMinutes;

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final spare = spareMinutes;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: CampusMapColors.sheetShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fillDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  destinationName,
                  style: const TextStyle(
                    color: CampusMapColors.buildingName,
                    fontSize: 24,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
              ),
              if (spare != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '여유 시간 $spare분',
                    style: const TextStyle(
                      color: AppColors.blueText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.directions_walk_rounded,
                size: 17,
                color: CampusMapColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '걸어서 $walkMinutes분 · ${distanceMeters.round()}m · '
                  '$arrivalTime 도착 예정',
                  style: const TextStyle(
                    color: CampusMapColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Pressable(
            onTap: onStart,
            pressedScale: 0.97,
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '안내 시작',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
