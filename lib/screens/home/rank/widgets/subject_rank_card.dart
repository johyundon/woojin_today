import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../models/department_rank.dart';

const _mutedText = Color(0xFF6B6B70);

/// "과목별 석차" 카드: 과목명 · 등급 배지 · 석차 막대 · "3/84".
class SubjectRankCard extends StatelessWidget {
  const SubjectRankCard({required this.subjects, super.key});

  final List<SubjectRank> subjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '과목별 석차',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          for (final subject in subjects) _SubjectRow(subject: subject),
        ],
      ),
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject});

  final SubjectRank subject;

  Color get _badgeColor {
    if (subject.grade.startsWith('A')) {
      return subject.grade == 'A+' ? AppColors.lime : const Color(0xFFDCE6FB);
    }
    return AppColors.blushPink;
  }

  @override
  Widget build(BuildContext context) {
    // 1등이면 꽉 찬 막대, 꼴찌에 가까울수록 짧아진다.
    final fill = 1 - (subject.rank - 1) / subject.total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              subject.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 34,
            padding: const EdgeInsets.symmetric(vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _badgeColor,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              subject.grade,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: fill,
                minHeight: 8,
                backgroundColor: const Color(0xFFE1E8FA),
                color: AppColors.cobalt,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text.rich(
              TextSpan(
                text: '${subject.rank}',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                children: [
                  TextSpan(
                    text: '/${subject.total}',
                    style: const TextStyle(
                      color: _mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
