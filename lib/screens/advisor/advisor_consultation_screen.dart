import 'package:flutter/material.dart';

import '../../config/advisor_submit_config.dart';
import '../../services/advisor_consultation_service.dart';
import '../../services/credential_storage.dart';
import '../../services/service_factory.dart';
import '../../services/session_cache.dart';
import '../../services/student_info_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import 'widgets/advisor_apply_tab.dart';
import 'widgets/advisor_load_states.dart';
import 'widgets/advisor_segmented_tabs.dart';
import 'widgets/advisor_status_tab.dart';

const Color _mutedLavender = Color(0xFFD7D9F5);

/// "지도교수상담" 화면(v4 리디자인) — 다른 "모아보기" 하위 화면들(마일리지,
/// 캘린더)과 같은 틀로 다시 짰다: 코발트 배경 위에 뒤로가기/교수님 카드/
/// 세그먼트 탭이 뜨고, 그 아래 흰 카드들에 탭 내용이 담긴다
/// (우진이의 하루 v4 시안, standalone.html "13-1~13-10" 화면).
///
/// 지도교수 성함은 포털 로그인으로 얻은 [userId2]로 [StudentInfoService]를
/// 호출해 조회한다(home_screen.dart와 같은 패턴). 상담 인정 횟수·학기별 표·
/// 이력·상세·교수 검색·방문 가능 시간은 저장된 학번·비밀번호로 T-WIN에
/// 로그인해 [AdvisorConsultationService]로 받는다.
///
/// 상담 신청은 교수님께 진짜 요청이 가므로 [allowRealSubmit]
/// (`kAllowRealAdvisorSubmit`)가 false면 보내지 않는다.
class AdvisorConsultationScreen extends StatefulWidget {
  const AdvisorConsultationScreen({
    required this.userId2,
    this.studentInfoService,
    this.consultationService,
    this.readCredentials,
    this.allowRealSubmit = kAllowRealAdvisorSubmit,
    super.key,
  });

  /// 포털 로그인으로 얻은 본인 SSO uid — [StudentInfoService.fetchStudentInfo]
  /// 호출에 필요하다. null이면(세션 없음) 지도교수 조회 자체를 하지 않고
  /// 방어적으로 "불러올 수 없음" 상태로 처리한다.
  final String? userId2;

  /// 테스트에서 [StudentInfoService]를 가짜로 바꿔 끼우려고 주입할 수 있다.
  final StudentInfoServiceBase? studentInfoService;

  /// 테스트용 주입 지점들.
  final AdvisorConsultationServiceBase? consultationService;
  final Future<({String userId, String userPwd})?> Function()? readCredentials;

  /// 실제 신청을 보낼지. 테스트에서만 바꾼다 — 앱에서는 항상 기본값
  /// (`kAllowRealAdvisorSubmit`)을 쓴다.
  final bool allowRealSubmit;

  @override
  State<AdvisorConsultationScreen> createState() =>
      _AdvisorConsultationScreenState();
}

class _AdvisorConsultationScreenState extends State<AdvisorConsultationScreen> {
  int _selectedTab = 0;

  late final StudentInfoServiceBase _studentInfoService;
  late final AdvisorConsultationServiceBase _consultationService =
      widget.consultationService ?? AdvisorConsultationService();
  String? _advisorName;
  bool _advisorLoading = true;
  StudentInfoResponse? _studentInfo;

  ({String userId, String userPwd})? _credentials;
  AdvisorOverview? _overview;
  bool _overviewLoading = true;
  String? _overviewError;

  @override
  void initState() {
    super.initState();
    _studentInfoService =
        widget.studentInfoService ?? ServiceFactory.studentInfo();
    _loadAdvisorName();
    _loadOverview();
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
        _studentInfo = info;
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

  /// 저장된 학번·비밀번호로 상담 인정 현황과 이력을 받는다. [forceRefresh]면
  /// 기기 저장분(7일)을 무시한다(당겨서 새로고침, 신청 직후).
  Future<void> _loadOverview({bool forceRefresh = false}) async {
    setState(() {
      _overviewLoading = true;
      _overviewError = null;
    });
    var credentials = _credentials;
    if (credentials == null) {
      try {
        credentials =
            await (widget.readCredentials ?? CredentialStorage().read)();
      } catch (e) {
        debugPrint('[AdvisorConsultation] 로그인 정보 읽기 실패: $e');
      }
      if (!mounted) return;
      if (credentials == null) {
        setState(() {
          _overviewLoading = false;
          _overviewError = '저장된 로그인 정보가 없어요. 다시 로그인해 주세요.';
        });
        return;
      }
      setState(() => _credentials = credentials);
    }
    try {
      final overview = await _consultationService.fetchOverview(
        userId: credentials.userId,
        userPwd: credentials.userPwd,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _overview = overview;
        _overviewLoading = false;
      });
    } catch (e) {
      debugPrint('[AdvisorConsultation] 상담 현황 조회 실패: $e');
      if (!mounted) return;
      setState(() {
        _overviewLoading = false;
        _overviewError = advisorErrorMessage(e);
      });
      // 이미 보여주던 현황이 있으면 그대로 두고 실패만 알린다.
      if (_overview != null) {
        showTopBanner(
          context,
          title: '새로 불러오지 못했어요',
          message: advisorErrorMessage(e),
          icon: Icons.error_outline_rounded,
        );
      }
    }
  }

  Future<ConsultationDetailInfo> _loadDetail(ConsultationRecord record) {
    final credentials = _credentials;
    if (credentials == null) {
      return Future.error(StateError('로그인 정보 없음'));
    }
    return _consultationService.fetchDetail(
      userId: credentials.userId,
      userPwd: credentials.userPwd,
      record: record,
    );
  }

  /// 방문 신청의 학생 정보 칸. 학교 화면처럼 '학번 학과 학년 이름'.
  String? get _studentInfoLine {
    final info = _studentInfo;
    final userId = _credentials?.userId;
    if (info == null || userId == null) return null;
    final department = info.department;
    final grade = info.grade;
    final name = info.name;
    if (department == null || grade == null || name == null) return null;
    return '$userId $department $grade $name';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 키보드 양옆 둥근 모서리 틈으로 Scaffold 바탕이 비쳐 파랑이 보이지
      // 않도록, 바탕은 흰색으로 두고 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: AppColors.cobalt,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Pressable.icon(
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
                    ? AdvisorStatusTab(
                        overview: _overview,
                        loading: _overviewLoading,
                        errorMessage: _overviewError,
                        onRetry: _loadOverview,
                        onRefresh: () => _loadOverview(forceRefresh: true),
                        loadDetail: _loadDetail,
                      )
                    : AdvisorApplyTab(
                        service: _consultationService,
                        credentials: _credentials,
                        advisorName: _advisorName,
                        advisorLoading: _advisorLoading,
                        advisorStaffNo: _overview?.advisorStaffNo,
                        studentInfoLine: _studentInfoLine,
                        allowRealSubmit: widget.allowRealSubmit,
                        onViewStatus: () => setState(() => _selectedTab = 0),
                        onSubmitted: () => _loadOverview(forceRefresh: true),
                      ),
              ),
            ],
          ),
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
