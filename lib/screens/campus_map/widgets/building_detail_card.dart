import 'package:flutter/material.dart';

import '../campus_map_colors.dart';

/// 지도 마커를 탭했을 때 하단에서 올라오는 건물 상세 카드.
///
/// TODO: 실제 건물 사진/설명 데이터가 없어(명세서 밖) placeholder만 보여준다.
class BuildingDetailCard extends StatelessWidget {
  const BuildingDetailCard({
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: CampusMapColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  buildingName,
                  style: const TextStyle(
                    color: CampusMapColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onClose,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.close,
                    color: CampusMapColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CampusMapColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              '사진 준비 중이에요',
              style: TextStyle(
                color: CampusMapColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '장소 설명은 준비 중이에요',
            style: TextStyle(
              color: CampusMapColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSetOrigin,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CampusMapColors.textPrimary,
                    side: const BorderSide(color: CampusMapColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '출발지로 선택',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSetDestination,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CampusMapColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '도착지로 선택',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
