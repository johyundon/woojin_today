import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/mascot_sticker.dart';
import '../services/mileage_mock_data.dart';

/// 1,240 같은 천 단위 쉼표 표기.
String formatPoints(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

/// 검은 "내 마일리지" 카드 — 총 포인트, 다음 등급까지 남은 포인트와 진행 바,
/// 오른쪽 아래에 걸쳐 앉은 마스코트.
///
/// 등급 문구·진행 바는 학교 API에 등급 기준이 없어 기본으로 숨긴다
/// ([showNextTier]). 코드는 기준을 알게 되면 다시 켤 수 있게 남겨 두었다.
class MileageTotalCard extends StatelessWidget {
  const MileageTotalCard({
    required this.total,
    this.showNextTier = false,
    super.key,
  });

  /// 내 마일리지 점수.
  final int total;

  /// 다음 등급까지 남은 포인트와 진행 바(목데이터 기준)를 보여줄지.
  final bool showNextTier;

  @override
  Widget build(BuildContext context) {
    const target = MileageMockData.nextTierPoints;
    final remaining = target - total;
    final ratio = (total / target).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars, size: 14, color: AppColors.lime),
                  SizedBox(width: 6),
                  Text(
                    '내 마일리지',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
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
                        fontSize: 56,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -2,
                      ),
                    ),
                    const Text(
                      'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (showNextTier) ...[
                const SizedBox(height: 8),
                Text(
                  '${MileageMockData.nextTierName}까지 ${formatPoints(remaining)}P',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  // 오른쪽 아래 마스코트와 바가 겹치지 않게 비워둔다.
                  padding: const EdgeInsets.only(right: 70),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF3A3A3E),
                      color: AppColors.blushPink,
                    ),
                  ),
                ),
              ] else
                // 마스코트가 카드 아래로 걸쳐 앉을 자리를 남긴다.
                const SizedBox(height: 22),
            ],
          ),
        ),
        const Positioned(
          right: 6,
          bottom: -6,
          child: MascotSticker(width: 76, angle: 0.08),
        ),
      ],
    );
  }
}
