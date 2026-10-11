import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/mileage_models.dart';

/// TOP5 한 줄 — "N위" 라벨 + 점수 비율만큼 채워진 가로 바 + 점수 숫자.
/// 바 길이는 1위 점수([maxScore]) 대비 비율로 계산한다.
class MileageRankBar extends StatelessWidget {
  const MileageRankBar({
    super.key,
    required this.entry,
    required this.maxScore,
  });

  final MileageRankEntry entry;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore == 0 ? 0.0 : entry.score / maxScore;
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '${entry.rank}위',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.disabledButton,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: constraints.maxWidth * ratio,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '${entry.score}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
