import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../models/advisor_consultation_models.dart';
import 'advisor_load_states.dart';

/// 교수 검색 카드("변경"을 눌렀을 때 상담교수 요약 카드 아래에 뜨는 패널).
///
/// 맨 위에는 항상 지도교수가 있고, 그 아래는 T-WIN 교수 검색 결과다. 학교는
/// 이름으로 5명씩 돌려주므로, 글자를 칠 때마다가 아니라 검색(키보드 완료 또는
/// 돋보기)을 누를 때만 조회한다.
class AdvisorProfessorSearchCard extends StatelessWidget {
  const AdvisorProfessorSearchCard({
    super.key,
    required this.searchController,
    required this.advisor,
    required this.results,
    required this.loading,
    required this.errorMessage,
    required this.hasSearched,
    required this.hasMore,
    required this.selectedProfessor,
    required this.onSearch,
    required this.onLoadMore,
    required this.onSelectProfessor,
  });

  final TextEditingController searchController;

  /// 본인 지도교수. 아직 모르면 null.
  final ProfessorOption? advisor;

  /// 검색 결과(지도교수와 같은 사람은 뺀 목록).
  final List<ProfessorOption> results;
  final bool loading;
  final String? errorMessage;
  final bool hasSearched;
  final bool hasMore;

  final ProfessorOption? selectedProfessor;
  final VoidCallback onSearch;
  final VoidCallback onLoadMore;
  final ValueChanged<ProfessorOption> onSelectProfessor;

  bool _isSelected(ProfessorOption p) {
    final selected = selectedProfessor;
    if (selected == null) return false;
    if (selected.isAdvisor || p.isAdvisor) {
      return selected.isAdvisor == p.isAdvisor;
    }
    return selected.staffNo == p.staffNo;
  }

  @override
  Widget build(BuildContext context) {
    final advisor = this.advisor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v7 시안처럼 돋보기를 왼쪽에 둔다. 눌러도 검색된다(키보드 완료와 같음).
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Pressable.icon(
                  key: const ValueKey('professor-search-button'),
                  onTap: onSearch,
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => onSearch(),
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 13,
                    ),
                    decoration: const InputDecoration(
                      hintText: '교수님 이름으로 검색',
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (advisor != null)
            _ProfessorRow(
              professor: advisor,
              isSelected: _isSelected(advisor),
              onTap: () => onSelectProfessor(advisor),
            ),
          if (loading)
            const AdvisorLoadingBox(label: '검색하는 중...')
          else if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 9),
              child: AdvisorErrorBox(message: errorMessage!, onRetry: onSearch),
            )
          else if (!hasSearched)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '다른 교수님은 이름을 입력하고 검색해 주세요',
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            )
          else if (results.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '검색 결과가 없어요',
                style: TextStyle(color: AppColors.textSub, fontSize: 13),
              ),
            )
          else ...[
            for (final professor in results)
              _ProfessorRow(
                professor: professor,
                isSelected: _isSelected(professor),
                onTap: () => onSelectProfessor(professor),
              ),
            if (hasMore)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Pressable(
                    onTap: onLoadMore,
                    child: const Text(
                      '더 보기',
                      style: TextStyle(
                        color: AppColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
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
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.blue.withValues(alpha: 0.1)
                : AppColors.fill,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                professor.name,
                style: TextStyle(
                  color: isSelected ? AppColors.blue : AppColors.textStrong,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  professor.isAdvisor ? '지도교수' : professor.department,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? AppColors.blue : AppColors.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
