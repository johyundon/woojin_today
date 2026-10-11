import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'models/graduation_credit.dart';
import 'services/graduation_credit_mock_data.dart';

/// "졸업학점" 화면.
///
/// 이 기능엔 대응하는 Figma 디자인이 없어서, 이미 만든 "모아보기" 화면들
/// (특히 마일리지 화면의 카드/막대그래프 톤)을 참고해 직접 설계했다.
/// 이수학점 조회 API가 명세서에 없어([GraduationCreditMockData] 참고)
/// 전부 목데이터로 동작하고, 학과/입학년도마다 실제 졸업 요건이 달라서
/// 이 숫자가 실제 본인 요건이 아니라는 안내를 화면에 넣었다.
class GraduationCreditScreen extends StatelessWidget {
  const GraduationCreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = GraduationCreditMockData.categories;
    final totalRequired = GraduationCreditMockData.totalRequired;
    final totalEarned = GraduationCreditMockData.totalEarned;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 4),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _TotalProgressCard(
                    totalRequired: totalRequired,
                    totalEarned: totalEarned,
                  ),
                  const SizedBox(height: 16),
                  _CategoryCard(categories: categories),
                  const SizedBox(height: 16),
                  const Text(
                    '학과/입학년도에 따라 실제 졸업 요건이 다를 수 있어요. '
                    '정확한 사정 결과는 학사정보시스템에서 확인해주세요.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalProgressCard extends StatelessWidget {
  const _TotalProgressCard({
    required this.totalRequired,
    required this.totalEarned,
  });

  final int totalRequired;
  final int totalEarned;

  @override
  Widget build(BuildContext context) {
    final remaining = (totalRequired - totalEarned).clamp(0, totalRequired);
    final ratio = totalRequired == 0 ? 0.0 : totalEarned / totalRequired;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '지금까지 이수한 학점',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$totalEarned',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ' / $totalRequired학점',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.disabledButton,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            remaining == 0 ? '졸업 요건 학점을 모두 채웠어요!' : '졸업까지 $remaining학점 더 필요해요',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.categories});

  final List<GraduationCreditCategory> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '영역별 이수 현황',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < categories.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == categories.length - 1 ? 0 : 14,
              ),
              child: _CategoryRow(category: categories[i]),
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final GraduationCreditCategory category;

  @override
  Widget build(BuildContext context) {
    final ratio = category.required == 0
        ? 0.0
        : category.earned / category.required;
    final done = category.remaining == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                category.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${category.earned} / ${category.required}학점',
              style: TextStyle(
                color: done ? AppColors.accent : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.disabledButton,
            valueColor: const AlwaysStoppedAnimation(AppColors.accent),
          ),
        ),
      ],
    );
  }
}
