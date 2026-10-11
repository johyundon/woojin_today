import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "마일리지 현황" / "장학 대상자 확인" 세그먼트 탭. 한 알약(큰 둥근 사각형)
/// 안에 탭 2개가 나란히 들어있고, 선택된 탭만 주황 배경 + 흰 글씨 pill로
/// 강조된다.
class MileageSegmentedTabs extends StatelessWidget {
  const MileageSegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const List<String> _labels = ['마일리지 현황', '장학 대상자 확인'];

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
