import 'package:flutter/material.dart';

import '../../../services/advisor_consultation_service.dart';
import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';
import 'advisor_consultation_history_card.dart';
import 'advisor_load_states.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _trackBackground = Color(0xFFE8E7F0);
const Color _divider = Color(0xFFEEEDF4);

const List<String> _semesterStatHeader = [
  '학기',
  '1학년',
  '2학년',
  '3학년',
  '4학년',
  '합계',
];

/// T-WIN 인정 현황으로 학기별 표의 행(1학기/2학기/합계)을 만든다.
///
/// 칸마다 "횟수/학기 기준"으로 보여준다. 학기 기준은 학교가 응답에 적어 둔
/// 규칙(1·2학년 학기당 2회, 3·4학년 학기당 1회)이고, 졸업 기준 12회인
/// 학생에게만 맞는다. 편입생(4회)은 기준을 알 수 없어 "N회"로만 보여준다.
List<SemesterStatRow> buildSemesterStatRows(AdvisorOverview overview) {
  int? perTermGoal(int grade) =>
      overview.goalCount == 12 ? (grade <= 2 ? 2 : 1) : null;
  const grades = [1, 2, 3, 4];

  SemesterStatRow termRow(int term) {
    final counts = [
      for (final g in grades) overview.countOf(term: term, grade: g),
    ];
    return SemesterStatRow(
      label: '$term학기',
      values: [
        for (var i = 0; i < grades.length; i++)
          perTermGoal(grades[i]) == null
              ? '${counts[i]}회'
              : '${counts[i]}/${perTermGoal(grades[i])}',
        '${counts.fold(0, (a, b) => a + b)}회',
      ],
    );
  }

  return [
    termRow(1),
    termRow(2),
    SemesterStatRow(
      label: '합계',
      values: [
        for (final g in grades)
          '${overview.countOf(term: 1, grade: g) + overview.countOf(term: 2, grade: g)}회',
        '${overview.totalCount}회',
      ],
    ),
  ];
}

/// "상담 현황" 탭 본문(v4 리디자인) — 흰 카드 하나에 상담 인정 횟수 +
/// 진행률 바, 학기별 인정 횟수 표, 구분선, 상담 이력 리스트를 전부 담는다.
/// 데이터는 T-WIN 인정 현황·신청 이력([AdvisorOverview])이고, 아래로 당기면
/// 새로 받는다.
class AdvisorStatusTab extends StatelessWidget {
  const AdvisorStatusTab({
    super.key,
    required this.overview,
    required this.loading,
    required this.errorMessage,
    required this.onRetry,
    required this.onRefresh,
    required this.loadDetail,
  });

  final AdvisorOverview? overview;
  final bool loading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;
  final Future<ConsultationDetailInfo> Function(ConsultationRecord record)
  loadDetail;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.cobalt,
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final data = overview;
    if (data == null) {
      if (loading) return const AdvisorLoadingBox(label: '상담 현황을 불러오는 중...');
      return AdvisorErrorBox(
        message: errorMessage ?? '상담 현황을 불러오지 못했어요.',
        onRetry: onRetry,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildApprovedCount(data),
        const SizedBox(height: 16),
        _buildSemesterTable(buildSemesterStatRows(data)),
        const SizedBox(height: 12),
        const Divider(height: 1, color: _divider),
        const SizedBox(height: 12),
        if (data.history.isEmpty)
          const AdvisorEmptyText('아직 상담 신청 이력이 없어요')
        else
          for (var i = 0; i < data.history.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == data.history.length - 1 ? 0 : 10,
              ),
              child: AdvisorConsultationHistoryCard(
                record: data.history[i],
                loadDetail: () => loadDetail(data.history[i]),
              ),
            ),
      ],
    );
  }

  Widget _buildApprovedCount(AdvisorOverview data) {
    final approved = data.totalCount;
    final required = data.goalCount;
    final progress = (approved / required).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '지금까지 상담 인정 횟수',
          style: TextStyle(color: _mutedText, fontSize: 13),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$approved',
              style: const TextStyle(
                color: AppColors.cobalt,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '회',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '/ $required회',
              style: const TextStyle(color: _mutedText, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: _trackBackground,
            valueColor: const AlwaysStoppedAnimation(AppColors.cobalt),
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterTable(List<SemesterStatRow> rows) {
    const header = _semesterStatHeader;
    final lastColumn = header.length - 2; // '학기' 라벨 칸 제외, 0-based.

    return Table(
      columnWidths: const {0: FlexColumnWidth(0.9)},
      children: [
        TableRow(
          children: [for (final h in header) _buildCell(h, isHeader: true)],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _buildCell(row.label, isHeader: true, alignLeft: true),
              for (var i = 0; i < row.values.length; i++)
                _buildCell(row.values[i], isTotal: i == lastColumn),
            ],
          ),
      ],
    );
  }

  Widget _buildCell(
    String text, {
    bool isHeader = false,
    bool isTotal = false,
    bool alignLeft = false,
  }) {
    final color = isTotal
        ? AppColors.cobalt
        : isHeader
        ? _mutedText
        : AppColors.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: isHeader || isTotal ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
