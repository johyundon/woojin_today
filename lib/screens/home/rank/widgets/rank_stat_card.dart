import 'package:flutter/material.dart';

import '../rank_colors.dart';

/// "내 성적" / "{학과명} 평균" 카드 하나.
class RankStatCard extends StatelessWidget {
  const RankStatCard({
    required this.colors,
    required this.label,
    required this.gpa,
  });

  final RankColors colors;
  final String label;
  final double gpa;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            gpa.toStringAsFixed(2),
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
