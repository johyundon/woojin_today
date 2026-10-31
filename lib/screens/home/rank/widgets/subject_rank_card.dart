import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/pressable.dart';
import '../models/department_rank.dart';

const _mutedText = Color(0xFF6B6B70);

/// 처음에 보여주는 과목 수. 더 있으면 "전체 ›"로 펼친다.
const _previewCount = 3;

/// "과목별 석차" 카드: 과목명 · 등급 배지 · 석차 막대 · "3/84". 과목이
/// [_previewCount]개를 넘으면 오른쪽 위 "전체 ›"를 눌러 전부 펼치고 "접기 ‹"로 다시
/// 줄인다.
class SubjectRankCard extends StatefulWidget {
  const SubjectRankCard({required this.subjects, super.key});

  final List<SubjectRank> subjects;

  @override
  State<SubjectRankCard> createState() => _SubjectRankCardState();
}

class _SubjectRankCardState extends State<SubjectRankCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final subjects = widget.subjects;
    final canExpand = subjects.length > _previewCount;
    final visible = _showAll || !canExpand
        ? subjects
        : subjects.take(_previewCount).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '과목별 석차',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (canExpand)
                Pressable(
                  onTap: () => setState(() => _showAll = !_showAll),
                  pressedScale: 0.92,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _showAll ? '접기 ‹' : '전체 ›',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final subject in visible) _SubjectRow(subject: subject),
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
