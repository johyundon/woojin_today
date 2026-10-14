import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/mileage_models.dart';

/// 흰 카드 안에 최근 적립 내역을 줄줄이 보여준다("신입생 멘토링 참여 +200").
class MileageHistoryCard extends StatelessWidget {
  const MileageHistoryCard({required this.activities, super.key});

  final List<MileageActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: activities.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '적립 내역이 없어요',
                  style: TextStyle(color: Color(0xFF6B6B70), fontSize: 14),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < activities.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFEDEDF0)),
                  _ActivityRow(activity: activities[i]),
                ],
              ],
            ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final MileageActivity activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EEE9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(activity.icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.date,
                  style: const TextStyle(
                    color: Color(0xFF6B6B70),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '+${activity.points}',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
