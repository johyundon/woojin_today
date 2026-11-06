import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../models/department_rank.dart';

const _binCount = 20;

/// "등" 글자색(v7 디자인 값 rgb(63, 69, 88)).
const _rankUnit = Color(0xFF3F4558);

/// 나보다 점수가 높은 칸의 막대색(v7 디자인 oklch(0.82 0.1 265)).
const _aboveMeBar = Color(0xFFA4C3FF);

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
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                size: 15,
                color: AppColors.textBody,
              ),
              const SizedBox(width: 5),
              Text(
                '학과 ${data.totalCount}명 중',
                style: const TextStyle(
                  color: AppColors.textBody,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${data.myRank}',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 61,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  letterSpacing: -3.66,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '등',
                style: TextStyle(
                  color: _rankUnit,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  size: 13,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 3),
                Text(
                  '상위 ${topPercent(data)}%',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _ScoreHistogram(data: data),
          const SizedBox(height: 6),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('하위', style: _axisLabel),
              Text('학과 점수 분포', style: _axisLabel),
              Text('상위', style: _axisLabel),
            ],
          ),
        ],
      ),
    );
  }
}

const _axisLabel = TextStyle(
  color: AppColors.textSub,
  fontSize: 12,
  fontWeight: FontWeight.w700,
);

/// 학과 평점 분포를 [_binCount]칸으로 묶은 막대그래프. 왼쪽이 낮은 점수,
/// 오른쪽이 높은 점수다. 내 칸은 파랑, 나보다 높은 칸은 중간 톤으로 칠하고
/// 내 칸 위에 "나" 표시를 띄운다.
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

    // 가장 높은 막대(60) 위에도 "나" 표시(25 + 간격 4)가 들어가도록 높이를 둔다.
    return SizedBox(
      height: 89,
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
                    // 막대 한 칸은 폭이 12px 안팎이라, 표시가 잘리지 않도록
                    // 칸 폭 제한을 풀어(OverflowBox) 가운데 정렬로 띄운다.
                    SizedBox(
                      height: 29,
                      child: OverflowBox(
                        maxWidth: 40,
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '나',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    height: 10 + 50 * counts[i] / maxCount,
                    decoration: BoxDecoration(
                      color: i == myBin
                          ? AppColors.blue
                          : i > myBin
                          ? _aboveMeBar
                          : AppColors.blueSoft,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                        bottom: Radius.circular(2),
                      ),
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
