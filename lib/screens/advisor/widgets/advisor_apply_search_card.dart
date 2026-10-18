import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';

const Color _mutedText = Color(0xFF7C7B88);
const Color _chipBackground = Color(0xFFF1F0F7);
const Color _disabledText = Color(0xFFB3B2C0);

/// 교수 검색 카드("변경"을 눌렀을 때 상담교수 요약 카드 아래에 뜨는 패널).
class AdvisorProfessorSearchCard extends StatelessWidget {
  const AdvisorProfessorSearchCard({
    super.key,
    required this.searchController,
    required this.professors,
    required this.selectedProfessor,
    required this.onQueryChanged,
    required this.onSelectProfessor,
  });

  final TextEditingController searchController;

  /// 검색어로 이미 걸러진 교수 목록.
  final List<ProfessorOption> professors;

  final ProfessorOption? selectedProfessor;

  /// 검색어가 바뀔 때마다(필터링 결과를 다시 그리기 위해) 호출.
  final VoidCallback onQueryChanged;

  final ValueChanged<ProfessorOption> onSelectProfessor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _chipBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: searchController,
              onChanged: (_) => onQueryChanged(),
              style: const TextStyle(color: AppColors.ink, fontSize: 14),
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: _disabledText, size: 18),
                hintText: '교수님 이름으로 검색',
                hintStyle: TextStyle(color: _disabledText),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 9),
          if (professors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '검색 결과가 없어요',
                style: TextStyle(color: _mutedText, fontSize: 13),
              ),
            )
          else
            for (final professor in professors)
              _ProfessorRow(
                professor: professor,
                isSelected: selectedProfessor?.name == professor.name,
                onTap: () => onSelectProfessor(professor),
              ),
        ],
      ),
    );
  }
}

class _ProfessorRow extends StatelessWidget {
  const _ProfessorRow({
    required this.professor,
    required this.isSelected,
    required this.onTap,
  });

  final ProfessorOption professor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.cobalt.withValues(alpha: 0.1)
                : _chipBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                professor.name,
                style: TextStyle(
                  color: isSelected ? AppColors.cobalt : AppColors.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (professor.isAdvisor)
                Text(
                  '지도교수',
                  style: TextStyle(
                    color: isSelected ? AppColors.cobalt : _mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
