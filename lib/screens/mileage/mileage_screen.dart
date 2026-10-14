import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'services/mileage_mock_data.dart';
import 'widgets/mileage_history_card.dart';
import 'widgets/mileage_scholarship_tab.dart';
import 'widgets/mileage_total_card.dart' show MileageTotalCard, formatPoints;

/// "모은 마일리지" 화면(v4 리디자인). 총 포인트 카드, 이번 학기/장학 기준
/// 카드, 최근 적립 내역을 보여준다. 시안에는 없지만 기존에 있던 "장학 대상자
/// 확인" 기능은 "장학 기준" 카드를 누르면 열리는 화면으로 그대로 남겼다.
///
/// 마일리지/장학 대상자 API 연동이 없어(명세서에 대응 엔드포인트 없음) 모든
/// 데이터는 하드코딩된 목데이터([MileageMockData], [MileageNoticeMockData],
/// [MileageRosterMockData])로만 조회한다.
class MileageScreen extends StatelessWidget {
  const MileageScreen({super.key});

  void _openScholarshipTargets(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.textPrimary,
            title: const Text(
              '장학 대상자 확인',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          body: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: MileageScholarshipTab(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.cobaltDeep,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '비교과 · 활동',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '모은 마일리지',
              style: TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(height: 18),
            const MileageTotalCard(),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _PointCard(
                      color: AppColors.lime,
                      label: '이번 학기',
                      value: '+${formatPoints(MileageMockData.termPoints)}P',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PointCard(
                      color: AppColors.blushPink,
                      label: '장학 기준',
                      value:
                          '${formatPoints(MileageMockData.scholarshipPoints)}P',
                      onTap: () => _openScholarshipTargets(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const MileageHistoryCard(activities: MileageMockData.activities),
          ],
        ),
      ),
    );
  }
}

class _PointCard extends StatelessWidget {
  const _PointCard({
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
