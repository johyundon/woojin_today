import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 지도 기본 화면 아래쪽 시트 — 고른 건물 이름, 걷는 시간·거리, 안내 문구,
/// "층별 안내" + "길 알려줘" 버튼.
///
/// 값이 없는 줄(현재 위치를 몰라 걷는 거리를 못 구했을 때, 오늘 수업 수·안내
/// 문구처럼 아직 데이터가 없는 것)은 그리지 않는다.
class BuildingSheet extends StatelessWidget {
  const BuildingSheet({
    super.key,
    required this.buildingName,
    required this.onFloorGuide,
    required this.onDirections,
    this.walkMinutes,
    this.distanceMeters,
    this.badge,
    this.note,
  });

  final String buildingName;
  final int? walkMinutes;
  final double? distanceMeters;

  /// 오른쪽 위 파란 배지(예: "오늘 수업 2개"). null이면 숨긴다.
  final String? badge;

  /// 구분선 아래 안내 문구. null이면 구분선째 숨긴다.
  final String? note;

  final VoidCallback onFloorGuide;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final walk = walkMinutes;
    final distance = distanceMeters;
    final badge = this.badge;
    final note = this.note;

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
                  buildingName,
                  style: const TextStyle(
                    color: CampusMapColors.buildingName,
                    fontSize: 24,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                  ),
                ),
              ),
              if (badge != null)
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
                    badge,
                    style: const TextStyle(
                      color: AppColors.blueText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (walk != null && distance != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.directions_walk_rounded,
                  size: 17,
                  color: CampusMapColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '걸어서 $walk분 · ${distance.round()}m',
                  style: const TextStyle(
                    color: CampusMapColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.line),
            const SizedBox(height: 14),
            Text(
              note,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _SheetButton(
                  label: '층별 안내',
                  background: AppColors.fill,
                  foreground: CampusMapColors.secondaryButtonText,
                  onTap: onFloorGuide,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: _SheetButton(
                  label: '길 알려줘',
                  background: AppColors.blue,
                  foreground: Colors.white,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onTap: onDirections,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 시트 아래쪽 버튼(높이 52, 둥글기 18).
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.trailingIcon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.96,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 6),
              Icon(trailingIcon, size: 18, color: foreground),
            ],
          ],
        ),
      ),
    );
  }
}
