import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _chipBackground = Color(0xFFF1F0F7);

/// 상담교수 요약 카드(모든 단계에서 항상 보임). 눌러서 "변경"하면
/// 검색 패널로 교체된다.
class AdvisorProfessorSummaryCard extends StatelessWidget {
  const AdvisorProfessorSummaryCard({
    super.key,
    required this.advisorLoading,
    required this.selectedProfessor,
    required this.searching,
    required this.onToggleSearching,
  });

  /// 지도교수 성함 조회가 아직 끝나지 않았는지.
  final bool advisorLoading;

  final ProfessorOption? selectedProfessor;

  /// 검색 패널이 열려 있는지("변경"/"닫기" 버튼 라벨에도 반영됨).
  final bool searching;

  final VoidCallback onToggleSearching;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '상담교수',
                  style: TextStyle(color: _mutedText, fontSize: 12),
                ),
                const SizedBox(height: 2),
                _SelectedProfessorLabel(
                  advisorLoading: advisorLoading,
                  selectedProfessor: selectedProfessor,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggleSearching,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _chipBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                searching ? '닫기' : '변경',
                style: const TextStyle(
                  color: AppColors.cobalt,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedProfessorLabel extends StatelessWidget {
  const _SelectedProfessorLabel({
    required this.advisorLoading,
    required this.selectedProfessor,
  });

  final bool advisorLoading;
  final ProfessorOption? selectedProfessor;

  @override
  Widget build(BuildContext context) {
    if (advisorLoading && selectedProfessor == null) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.cobalt,
            ),
          ),
          SizedBox(width: 8),
          Text('불러오는 중...', style: TextStyle(color: _mutedText, fontSize: 14)),
        ],
      );
    }

    final professor = selectedProfessor;
    if (professor == null) {
      return const Text(
        '지도교수 정보를 불러올 수 없어요',
        style: TextStyle(color: _mutedText, fontSize: 14),
      );
    }

    return Text(
      professor.isAdvisor
          ? '${professor.name} (지도교수)'
          : '${professor.name} (${professor.department})',
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
