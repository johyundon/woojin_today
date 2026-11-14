import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/mileage_models.dart';

/// 적립 내역 줄 사이 선 rgb(232, 234, 238)(v7 디자인 47 mileage).
const _rowLine = Color(0xFFE8EAEE);

/// 흰 카드 안에 적립 내역(비교과 이수)을 줄줄이 보여준다("취업박람회 현장지도 +9").
class MileageHistoryCard extends StatelessWidget {
  const MileageHistoryCard({required this.activities, super.key});

  final List<MileageActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: activities.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  '적립 내역이 없어요',
                  style: TextStyle(color: AppColors.textSub, fontSize: 14),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < activities.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: _rowLine),
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(activity.icon, size: 18, color: AppColors.textSub),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.date,
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${activity.points}',
              style: const TextStyle(
                color: AppColors.blueText,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
