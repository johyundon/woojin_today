import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

const Color _trackBackground = Color(0xFFEDEFF2);
const Color _trackBorder = Color(0xFFE1E4E9);

/// "상담 현황" / "상담 신청" 세그먼트 탭(v7). 옅은 회색 상자 안에서 선택된
/// 쪽만 남색(inkNavy) 바탕 + 흰 글씨로 떠오른다.
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
        color: _trackBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _trackBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < _labels.length; i++)
            Expanded(
              child: Pressable(
                onTap: () => onChanged(i),
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? AppColors.inkNavy
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == selectedIndex
                          ? Colors.white
                          : AppColors.textBody,
                      fontSize: 13,
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
