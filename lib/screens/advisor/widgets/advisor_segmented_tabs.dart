import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "지도교수 상담 현황" / "지도교수 상담 신청" 세그먼트 탭.
/// mileage_segmented_tabs.dart와 같은 스타일(알약 안에 선택된 탭만 주황
/// 배경 + 흰 글씨 pill로 강조)을 그대로 재현했다.
class AdvisorSegmentedTabs extends StatelessWidget {
  const AdvisorSegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const List<String> _labels = ['지도교수 상담 현황', '지도교수 상담 신청'];

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.accent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == selectedIndex
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
