import 'package:flutter/material.dart';

import '../models/department_rank.dart';
import '../rank_colors.dart';

/// 성적 분포 리스트의 한 줄: "N위" 라벨 + 가로 막대그래프 + 평점.
///
/// 내 평점과 같은 줄(동점 포함)은 모두 [RankColors.highlight]로 강조한다.
class RankDistributionRow extends StatelessWidget {
  const RankDistributionRow({
    required this.colors,
    required this.entry,
    required this.myGpa,
    required this.maxGpa,
  });

  final RankColors colors;
  final DepartmentRankEntry entry;
  final double myGpa;
  final double maxGpa;

  bool get _isMine => (entry.gpa - myGpa).abs() < 0.001;

  @override
  Widget build(BuildContext context) {
    final barColor = _isMine ? colors.highlight : colors.barFill;
    final fraction = maxGpa <= 0 ? 0.0 : (entry.gpa / maxGpa).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.rank}위',
              style: TextStyle(
                color: _isMine ? colors.highlight : colors.textSecondary,
                fontSize: 12,
                fontWeight: _isMine ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                children: [
                  Container(height: 14, color: colors.barTrack),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(height: 14, color: barColor),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              entry.gpa.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _isMine ? colors.highlight : colors.textPrimary,
                fontSize: 12,
                fontWeight: _isMine ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
