import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../services/mileage_mock_data.dart';
import 'mileage_rank_bar.dart';

/// "마일리지 현황" 탭 본문 — 내 순위/점수 + 전체 TOP5 카드와, 그 아래
/// 마일리지 지급 내역 영역(목데이터상 0점이라 빈 상태만 구현).
class MileageStatusTab extends StatelessWidget {
  const MileageStatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    final top5 = MileageMockData.top5;
    final maxScore = top5.first.score;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '나의 마일리지 순위',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${MileageMockData.myRank}',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                '위',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          '나의 마일리지',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${MileageMockData.myScore}점',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),
                const Text(
                  '전체 TOP 5',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < top5.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == top5.length - 1 ? 0 : 10,
                    ),
                    child: MileageRankBar(entry: top5[i], maxScore: maxScore),
                  ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '지급 내역이 없어요',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
