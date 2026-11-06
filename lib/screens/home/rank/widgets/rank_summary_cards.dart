import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../models/department_rank.dart';
import 'rank_hero_card.dart';

/// 성적우수 장학 지원 기준(상위 몇 %까지).
const _scholarshipTopPercent = 20;

// v7 디자인(29 rank)의 카드 색. oklch 값은 sRGB로 바꿔 옮겼다.
/// "내 평점" 카드 바탕 oklch(0.95 0.04 295)과 제목색 oklch(0.5 0.14 295).
const _gpaCardBackground = Color(0xFFF0EAFF);
const _gpaCardLabel = Color(0xFF6A4FA9);

/// "장학" 카드 바탕 oklch(0.96 0.05 75)과 제목색 rgb(194, 65, 12).
const _scholarshipCardBackground = Color(0xFFFFEECD);
const _scholarshipCardLabel = Color(0xFFC2410C);

/// 카드 안 큰 값 rgb(43, 47, 59)과 보조 글자 rgb(107, 114, 128).
const _cardValue = Color(0xFF2B2F3B);
const _cardSub = Color(0xFF6B7280);

/// 평균보다 높을 때 위 화살표 rgb(220, 58, 58).
const _aboveAverage = Color(0xFFDC3A3A);

/// 나란히 놓이는 "내 평점"(연보라) / "장학"(연노랑) 카드 두 장.
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
            flex: 180,
            child: _SummaryCard(
              color: _gpaCardBackground,
              labelColor: _gpaCardLabel,
              icon: Icons.school_rounded,
              label: '내 평점',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        data.myGpa.toStringAsFixed(2),
                        style: const TextStyle(
                          color: _cardValue,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                          letterSpacing: -1.17,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '/ 4.5',
                        style: TextStyle(
                          color: _cardSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          diff >= 0
                              ? Icons.arrow_drop_up_rounded
                              : Icons.arrow_drop_down_rounded,
                          size: 15,
                          color: diff >= 0 ? _aboveAverage : AppColors.blue,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '학과 평균보다 ${diff.abs().toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
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
            const SizedBox(width: 10),
            Expanded(
              flex: 164,
              child: _SummaryCard(
                color: _scholarshipCardBackground,
                labelColor: _scholarshipCardLabel,
                icon: Icons.workspace_premium_rounded,
                label: '장학',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eligible ? '성적우수 장학\n지원 가능' : '성적우수 장학\n지원 기준 미달',
                      style: const TextStyle(
                        color: _cardValue,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        height: 1.4,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '기준 상위 $_scholarshipTopPercent%',
                      style: TextStyle(
                        color: _cardSub,
                        fontSize: 12,
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
    required this.labelColor,
    required this.icon,
    required this.label,
    required this.child,
  });

  final Color color;
  final Color labelColor;
  final IconData icon;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: labelColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
