import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../campus_map_colors.dart';

/// 지도 마커를 탭했을 때 하단에 뜨는 건물 상세 카드(v7) — 건물 이름과 닫기,
/// 회색 "출발지로 선택" + 파란 "도착지로 선택" 버튼.
///
/// 시안의 걸리는 시간·오늘 수업·층별 안내·장소 설명은 건물 데이터에 없어서
/// 그리지 않는다.
class BuildingDetailCard extends StatelessWidget {
  const BuildingDetailCard({
    super.key,
    required this.buildingName,
    required this.onClose,
    required this.onSetOrigin,
    required this.onSetDestination,
  });

  final String buildingName;
  final VoidCallback onClose;
  final VoidCallback onSetOrigin;
  final VoidCallback onSetDestination;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: CampusMapColors.sheetShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  buildingName,
                  style: const TextStyle(
                    color: CampusMapColors.buildingName,
                    fontSize: 22,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.88,
                  ),
                ),
              ),
              Pressable.icon(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: CampusMapColors.textSecondary,
                    size: 18,
                    semanticLabel: '닫기',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                flex: 128,
                child: _CardButton(
                  label: '출발지로 선택',
                  background: AppColors.fill,
                  foreground: CampusMapColors.secondaryButtonText,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  onPressed: onSetOrigin,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 192,
                child: _CardButton(
                  label: '도착지로 선택',
                  background: AppColors.blue,
                  foreground: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: onSetDestination,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 카드 아래쪽 버튼(높이 52, 둥글기 16).
class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.fontSize,
    required this.fontWeight,
    required this.onPressed,
    this.trailingIcon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Pressable.effect(
      pressedScale: 0.96,
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: fontSize, fontWeight: fontWeight),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                Icon(trailingIcon, size: 17),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
