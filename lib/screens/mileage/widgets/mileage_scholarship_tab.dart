import 'package:flutter/material.dart';

import '../services/mileage_notice_mock_data.dart';
import 'mileage_notice_card.dart';

/// "장학 대상자 확인" 탭 본문 — 공지 카드 목록.
class MileageScholarshipTab extends StatelessWidget {
  const MileageScholarshipTab({super.key});

  @override
  Widget build(BuildContext context) {
    final notices = MileageNoticeMockData.notices;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: notices.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          MileageNoticeCard(notice: notices[index]),
    );
  }
}
