import 'package:flutter/material.dart';

import '../../services/service_factory.dart';
import '../../services/session_cache.dart';
import '../../services/student_info_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/advisor_apply_tab.dart';
import 'widgets/advisor_segmented_tabs.dart';
import 'widgets/advisor_status_tab.dart';

const Color _mutedLavender = Color(0xFFD7D9F5);

/// "지도교수상담" 화면(v4 리디자인) — 다른 "모아보기" 하위 화면들(마일리지,
/// 캘린더)과 같은 틀로 다시 짰다: 코발트 배경 위에 뒤로가기/교수님 카드/
/// 세그먼트 탭이 뜨고, 그 아래 흰 카드들에 탭 내용이 담긴다
/// (우진이의 하루 v4 시안, standalone.html "13-1~13-10" 화면).
///
/// 지도교수 성함만큼은 이 화면에서 유일하게 실제 연동이 있다 — 포털
/// 로그인으로 얻은 [userId2]로 [StudentInfoService](`kUseMockApi`일 때는
/// [FakeStudentInfoService])를 호출해 조회한다(home_screen.dart와 같은
/// 패턴). 그 외 상담 인정 횟수/학기별 표/이력/다른 교수 목록/방문 상담
/// 가능 시간은 API 명세서에 대응 엔드포인트가 없어
/// [AdvisorConsultationMockData]의 하드코딩된 목데이터로만 동작한다.
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

  late final StudentInfoServiceBase _studentInfoService;
  String? _advisorName;
  bool _advisorLoading = true;

  @override
  void initState() {
    super.initState();
    _studentInfoService = ServiceFactory.studentInfo();
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
      final info = await SessionCache.getStudentInfo(
        _studentInfoService,
        userId2: userId2,
      );
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
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                '지도교수 상담',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.035,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _buildAdvisorCard(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: AdvisorSegmentedTabs(
                selectedIndex: _selectedTab,
                onChanged: (index) => setState(() => _selectedTab = index),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedTab == 0
                  ? const AdvisorStatusTab()
                  : AdvisorApplyTab(
                      advisorName: _advisorName,
                      advisorLoading: _advisorLoading,
                      onViewStatus: () => setState(() => _selectedTab = 0),
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cobaltDeep,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
            child: Text(
              _advisorInitial,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '나의 지도교수님',
                  style: TextStyle(color: _mutedLavender, fontSize: 12),
                ),
                const SizedBox(height: 1),
                _buildAdvisorNameLine(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _advisorInitial {
    final name = _advisorName;
    return name == null || name.isEmpty ? '?' : name.substring(0, 1);
  }

  Widget _buildAdvisorNameLine() {
    if (_advisorLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.lime,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '불러오는 중...',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      );
    }

    final advisorName = _advisorName;
    if (advisorName == null) {
      return const Text(
        '불러올 수 없어요',
        style: TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
        children: [
          TextSpan(
            text: advisorName,
            style: const TextStyle(color: AppColors.lime),
          ),
          const TextSpan(
            text: ' 교수님',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
