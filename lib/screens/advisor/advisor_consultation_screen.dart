import 'package:flutter/material.dart';

import '../../config/mock_mode.dart';
import '../../services/fakes/fake_student_info_service.dart';
import '../../services/student_info_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/advisor_apply_tab.dart';
import 'widgets/advisor_segmented_tabs.dart';
import 'widgets/advisor_status_tab.dart';

/// "지도교수상담" 화면 (Figma node 6:118).
///
/// 이 노드는 실제 Figma 벡터 레이어가 아니라 다른 앱을 캡처한 스크린샷 4장
/// (6:119~6:122)이 평탄화된 상태라 `get_design_context`로 쓸만한 코드를
/// 뽑을 수 없었다(calendar_screen.dart, cafeteria_screen.dart, mileage_screen.dart와
/// 같은 상황). 스크린샷을 눈으로 보고 레이아웃/색상/간격을 근사해 재현했다.
///
/// 지도교수 성함만큼은 이 화면에서 유일하게 실제 연동이 있다 — 포털
/// 로그인으로 얻은 [userId2]로 [StudentInfoService](`kUseMockApi`일 때는
/// [FakeStudentInfoService])를 호출해 조회한다(home_screen.dart와 같은
/// 패턴). 그 외 상담 인정 횟수/학기별 표/이력/다른 교수 목록은 API
/// 명세서에 대응 엔드포인트가 없어 [AdvisorConsultationMockData]의 하드코딩된
/// 목데이터로만 동작한다.
///
/// [AdvisorApplyTab] 안의 "상담 내용" 입력 필드 + "상담 신청하기" 버튼은
/// 스크린샷 4장에 없던 부분이라, "상세보기" 다이얼로그의 "신청 내용" 필드를
/// 참고해 직접 추가한 UI다(디자인에 명시되지 않음).
class AdvisorConsultationScreen extends StatefulWidget {
  const AdvisorConsultationScreen({required this.userId2, super.key});

  /// 포털 로그인으로 얻은 본인 SSO uid — [StudentInfoService.fetchStudentInfo]
  /// 호출에 필요하다. null이면(세션 없음) 지도교수 조회 자체를 하지 않고
  /// 방어적으로 "불러올 수 없음" 상태로 처리한다.
  final String? userId2;

  @override
  State<AdvisorConsultationScreen> createState() =>
      _AdvisorConsultationScreenState();
}

class _AdvisorConsultationScreenState extends State<AdvisorConsultationScreen> {
  int _selectedTab = 0;

  late final StudentInfoService _studentInfoService;
  String? _advisorName;
  bool _advisorLoading = true;

  @override
  void initState() {
    super.initState();
    _studentInfoService = kUseMockApi
        ? FakeStudentInfoService()
        : StudentInfoService();
    _loadAdvisorName();
  }

  /// [widget.userId2]가 없으면(세션 정보 없음) 네트워크 호출 자체를 하지
  /// 않고 바로 "불러올 수 없음" 상태로 처리한다. 홈 화면과 달리 이 화면은
  /// 원인별 에러 안내가 필요하지 않아(로딩 스피너 + "불러올 수 없어요" 정도면
  /// 충분), 예외 종류를 구분하지 않고 하나로 합쳐 처리한다.
  Future<void> _loadAdvisorName() async {
    final userId2 = widget.userId2;
    if (userId2 == null) {
      setState(() {
        _advisorLoading = false;
        _advisorName = null;
      });
      return;
    }

    try {
      final info = await _studentInfoService.fetchStudentInfo(userId2: userId2);
      if (!mounted) return;
      setState(() {
        _advisorName = info.advisorName;
        _advisorLoading = false;
      });
    } catch (e) {
      debugPrint('[AdvisorConsultation] 지도교수 조회 실패: $e');
      if (!mounted) return;
      setState(() {
        _advisorName = null;
        _advisorLoading = false;
      });
    }
  }

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
              child: _buildAdvisorCard(),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AdvisorSegmentedTabs(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _selectedTab == 0
                  ? const AdvisorStatusTab()
                  : AdvisorApplyTab(
                      advisorName: _advisorName,
                      advisorLoading: _advisorLoading,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvisorCard() {
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
            '나의 지도교수님',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          _buildAdvisorNameLine(),
        ],
      ),
    );
  }

  Widget _buildAdvisorNameLine() {
    if (_advisorLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          SizedBox(width: 10),
          Text(
            '불러오는 중...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      );
    }

    final advisorName = _advisorName;
    if (advisorName == null) {
      return const Text(
        '불러올 수 없어요',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        children: [
          TextSpan(
            text: advisorName,
            style: const TextStyle(color: AppColors.accent),
          ),
          const TextSpan(
            text: ' 교수님',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
