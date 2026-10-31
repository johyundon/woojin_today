import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../models/department_rank.dart';
import 'rank_hero_card.dart';

/// 성적우수 장학 지원 기준(상위 몇 %까지).
const _scholarshipTopPercent = 20;

/// 나란히 놓이는 "내 평점"(라임) / "장학"(핑크) 카드 두 장.
///
/// 장학 기준(상위 20%)이 확인되지 않아 지금은 [showScholarship]을 꺼서 "내 평점"
/// 카드만 보여준다. 기준이 확인되면 켜면 된다.
class RankSummaryCards extends StatelessWidget {
  const RankSummaryCards({
    required this.data,
    this.showScholarship = false,
    super.key,
  });

  final DepartmentRank data;
  final bool showScholarship;

  @override
  Widget build(BuildContext context) {
    final diff = data.myGpa - data.departmentAverageGpa;
    final eligible = RankHeroCard.topPercent(data) <= _scholarshipTopPercent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              color: AppColors.lime,
              icon: Icons.school,
              label: '내 평점',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: data.myGpa.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                      children: const [
                        TextSpan(
                          text: ' / 4.5',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          diff >= 0
                              ? Icons.arrow_drop_up
                              : Icons.arrow_drop_down,
                          size: 16,
                          color: AppColors.ink,
                        ),
                        Text(
                          '학과 평균보다 ${diff.abs().toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showScholarship) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                color: AppColors.blushPink,
                icon: Icons.workspace_premium,
                label: '장학',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eligible ? '성적우수 장학\n지원 가능' : '성적우수 장학\n지원 기준 미달',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '기준 상위 $_scholarshipTopPercent%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.child,
  });

  final Color color;
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.ink),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.ink),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
