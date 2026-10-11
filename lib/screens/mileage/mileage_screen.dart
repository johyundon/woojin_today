import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/mileage_scholarship_tab.dart';
import 'widgets/mileage_segmented_tabs.dart';
import 'widgets/mileage_status_tab.dart';

/// "마일리지" 화면 (Figma node 6:105).
///
/// 이 노드는 실제 Figma 벡터 레이어가 아니라 다른 앱을 캡처한 스크린샷 4장
/// (6:106~6:109)이 평탄화된 상태라 `get_design_context`로 쓸만한 코드를 뽑을
/// 수 없었다(calendar_screen.dart, cafeteria_screen.dart와 같은 상황). 스크린샷을
/// 눈으로 보고 레이아웃/색상/간격을 근사해 재현했다.
///
/// 마일리지/장학 대상자 API 연동이 없어(명세서에 대응 엔드포인트 없음) 모든
/// 데이터는 하드코딩된 목데이터([MileageMockData], [MileageNoticeMockData],
/// [MileageRosterMockData])로만 조회한다.
class MileageScreen extends StatefulWidget {
  const MileageScreen({super.key});

  @override
  State<MileageScreen> createState() => _MileageScreenState();
}

class _MileageScreenState extends State<MileageScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: MileageSegmentedTabs(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _selectedTab == 0
                  ? const MileageStatusTab()
                  : const MileageScholarshipTab(),
            ),
          ],
        ),
      ),
    );
  }
}
