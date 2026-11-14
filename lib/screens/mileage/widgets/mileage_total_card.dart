import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../services/mileage_mock_data.dart';

/// 1,240 같은 천 단위 쉼표 표기.
String formatPoints(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// 파란 카드 위 연한 글자색 rgb(220, 234, 255)(v7 디자인 47 mileage).
const _onBlueSoftText = Color(0xFFDCEAFF);

/// 파란 "현재 마일리지" 카드 — 지금 점수, 학기마다 초기화된다는 안내,
/// 다음 등급까지 남은 포인트와 진행 바.
///
/// 등급 문구·진행 바는 학교 API에 등급 기준이 없어 기본으로 숨긴다
/// ([showNextTier]). 코드는 기준을 알게 되면 다시 켤 수 있게 남겨 두었다.
class MileageTotalCard extends StatelessWidget {
  const MileageTotalCard({
    required this.total,
    this.showNextTier = false,
    super.key,
  });

  /// 내 마일리지 점수(학기마다 초기화된다).
  final int total;

  /// 다음 등급까지 남은 포인트와 진행 바(목데이터 기준)를 보여줄지.
  final bool showNextTier;

  @override
  Widget build(BuildContext context) {
    const target = MileageMockData.nextTierPoints;
    final remaining = target - total;
    final ratio = (total / target).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, size: 15, color: _onBlueSoftText),
              SizedBox(width: 5),
              Text(
                '현재 마일리지',
                style: TextStyle(
                  color: _onBlueSoftText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 점수가 길어 칸을 넘으면 글자를 줄여 맞춘다.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatPoints(total),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 45,
                    fontWeight: FontWeight.w800,
                    height: 1.4,
                    letterSpacing: -2.025,
                  ),
                ),
                const SizedBox(width: 2),
                const Text(
                  'P',
                  style: TextStyle(
                    color: _onBlueSoftText,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '학기마다 초기화돼요',
            style: TextStyle(
              color: _onBlueSoftText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showNextTier) ...[
            const SizedBox(height: 14),
            Text(
              '${MileageMockData.nextTierName}까지 ${formatPoints(remaining)}P',
              style: const TextStyle(
                color: _onBlueSoftText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
