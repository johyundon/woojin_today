import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/mascot_sticker.dart';
import '../models/department_rank.dart';

const _binCount = 20;
const _mutedText = Color(0xFF6B6B70);

/// "학과 N명 중 / 12등 / 상위 14%" + 점수 분포 막대그래프가 든 흰 카드.
class RankHeroCard extends StatelessWidget {
  const RankHeroCard({required this.data, super.key});

  final DepartmentRank data;

  /// 내 등수가 상위 몇 %인지(반올림, 최소 1).
  static int topPercent(DepartmentRank data) =>
      (data.myRank / data.totalCount * 100).round().clamp(1, 100);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.groups, size: 16, color: _mutedText),
                      const SizedBox(width: 6),
                      Text(
                        '학과 ${data.totalCount}명 중',
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${data.myRank}',
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                          letterSpacing: -2,
                        ),
                      ),
                      const Text(
                        '등',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.lime,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 14,
                          color: AppColors.ink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '상위 ${topPercent(data)}%',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Positioned(
                right: 0,
                top: 0,
                child: MascotSticker(width: 92, angle: 0.08),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ScoreHistogram(data: data),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('하위', style: TextStyle(color: _mutedText, fontSize: 11)),
              Text(
                '학과 점수 분포',
                style: TextStyle(color: _mutedText, fontSize: 11),
              ),
              Text('상위', style: TextStyle(color: _mutedText, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

/// 학과 평점 분포를 [_binCount]칸으로 묶은 막대그래프. 왼쪽이 낮은 점수,
/// 오른쪽이 높은 점수다. 내 칸은 진하게, 나보다 높은 칸은 중간 톤으로 칠하고
/// 내 칸 위에 "나" 말풍선을 띄운다.
class _ScoreHistogram extends StatelessWidget {
  const _ScoreHistogram({required this.data});

  final DepartmentRank data;

  @override
  Widget build(BuildContext context) {
    final gpas = data.distribution.map((e) => e.gpa);
    final minGpa = gpas.reduce((a, b) => a < b ? a : b);
    final maxGpa = gpas.reduce((a, b) => a > b ? a : b);
    final span = (maxGpa - minGpa).clamp(0.01, double.infinity);

    int binOf(double gpa) =>
        ((gpa - minGpa) / span * _binCount).floor().clamp(0, _binCount - 1);

    final counts = List<int>.filled(_binCount, 0);
    for (final gpa in gpas) {
      counts[binOf(gpa)]++;
    }
    final maxCount = counts.reduce((a, b) => a > b ? a : b);
    final myBin = binOf(data.myGpa);

    return SizedBox(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < _binCount; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (i == myBin)
                    // 막대 한 칸은 폭이 13px 안팎이라, 말풍선이 잘리지 않도록
                    // 칸 폭 제한을 풀어(OverflowBox) 가운데 정렬로 띄운다.
                    SizedBox(
                      height: 24,
                      child: OverflowBox(
                        maxWidth: 32,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            '나',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    height: 8 + 60 * counts[i] / maxCount,
                    decoration: BoxDecoration(
                      color: i == myBin
                          ? AppColors.cobalt
                          : i > myBin
                          ? const Color(0xFF8FA8F0)
                          : const Color(0xFFE1E8FA),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
