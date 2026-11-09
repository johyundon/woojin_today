import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../models/department_rank.dart';

/// 평점 만점. 막대 길이는 평점 / 만점.
const _maxGpa = 4.5;

/// 석차 목록 한 줄.
class GpaRankingRow {
  const GpaRankingRow({
    required this.rank,
    required this.gpa,
    required this.isMe,
  });

  /// 1부터 차례로 붙이는 순위.
  final int rank;
  final double gpa;

  /// 내 줄인지.
  final bool isMe;
}

/// 학과 평점을 높은 순으로 나열하고 내 줄을 표시한다.
///
/// 동기 목록에 내 평점이 들어 있는지는 확인하지 못했다. 그래서 같은 값이
/// 없으면 내 자리에 내 평점을 끼워 넣는다.
List<GpaRankingRow> gpaRankingRows(DepartmentRank data) {
  final gpas = [for (final e in data.distribution) e.gpa]
    ..sort((a, b) => b.compareTo(a));
  bool same(double a, double b) => (a - b).abs() < 0.005;

  if (!gpas.any((g) => same(g, data.myGpa))) {
    gpas.insert(gpas.where((g) => g > data.myGpa).length, data.myGpa);
  }
  // 평점이 같은 사람이 있어도 "나"는 그중 첫 줄 하나만 표시한다.
  final me = gpas.indexWhere((g) => same(g, data.myGpa));
  return [
    for (var i = 0; i < gpas.length; i++)
      GpaRankingRow(rank: i + 1, gpa: gpas[i], isMe: i == me),
  ];
}

/// "컴퓨터공학전공(3학년) 성적 분포" 카드: 학과 학생들의 평점을 1위부터 전부
/// 막대로 나열한다. 위쪽 점수 분포 카드처럼 다른 사람은 연한 파랑, 내 평점
/// 줄은 진한 파랑과 "나" 표시로 구분한다. 이름은 받지 않으므로
/// 순위와 평점만 보여준다.
class GpaRankingListCard extends StatelessWidget {
  const GpaRankingListCard({required this.data, super.key});

  final DepartmentRank data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 15,
                color: AppColors.textBody,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  '${data.departmentName}(${data.grade}학년) 성적 분포',
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final row in gpaRankingRows(data)) _RankingRow(row: row),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({required this.row});

  final GpaRankingRow row;

  @override
  Widget build(BuildContext context) {
    final color = row.isMe ? AppColors.blue : AppColors.textSub;
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${row.rank}위',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: row.isMe ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (row.gpa / _maxGpa).clamp(0.0, 1.0),
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: row.isMe ? AppColors.blue : AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (row.isMe) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(6),
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
                  const SizedBox(width: 4),
                ],
                Text(
                  row.gpa.toStringAsFixed(2),
                  style: TextStyle(
                    color: row.isMe ? AppColors.blue : AppColors.textStrong,
                    fontSize: 13,
                    fontWeight: row.isMe ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
