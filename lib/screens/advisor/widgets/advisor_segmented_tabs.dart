import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// "상담 현황" / "상담 신청" 세그먼트 탭(v4 리디자인). 진한 남색(cobaltDeep)
/// 알약 안에서 선택된 쪽만 라임 배경 + 잉크 글씨로 떠오른다.
class AdvisorSegmentedTabs extends StatelessWidget {
  const AdvisorSegmentedTabs({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const List<String> _labels = ['상담 현황', '상담 신청'];

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cobaltDeep,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.lime
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == selectedIndex
                          ? AppColors.ink
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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
