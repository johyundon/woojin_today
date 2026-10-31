import 'package:flutter/material.dart';

import '../../../services/advisor_consultation_service.dart';
import '../../../services/credential_storage.dart';
import '../../../widgets/top_banner.dart';
import '../models/advisor_consultation_models.dart';
import 'advisor_apply_content_step.dart';
import 'advisor_apply_done_card.dart';
import 'advisor_apply_email_step.dart';
import 'advisor_apply_method_step.dart';
import 'advisor_apply_phone_step.dart';
import 'advisor_apply_professor_summary_card.dart';
import 'advisor_apply_search_card.dart';
import 'advisor_load_states.dart';

/// "상담 신청" 탭 본문(v4 리디자인). 상담교수는 모든 단계에서 항상 위에
/// 떠 있고(눌러서 "변경"하면 검색 패널로 교체), 그 아래 단계 카드가 이어진다
/// — 교수/방식(방문이면 날짜·시간도) → 전화번호 → 이메일 → 상담 내용 4단계.
/// 학교 방문 신청에도 전화번호·이메일이 들어가서 두 방식 모두 4단계다.
///
/// 마지막 "상담 신청하기"는 [allowRealSubmit]가 false면 학교로 보내지 않고
/// "아직 실제 신청은 막혀 있어요" 배너만 띄운다(교수님께 진짜 요청이 가므로).
class AdvisorApplyTab extends StatefulWidget {
  const AdvisorApplyTab({
    super.key,
    required this.service,
    required this.credentials,
    required this.advisorName,
    required this.advisorLoading,
    required this.advisorStaffNo,
    required this.studentInfoLine,
    required this.allowRealSubmit,
    required this.onViewStatus,
    required this.onSubmitted,
  });

  final AdvisorConsultationServiceBase service;

  /// 저장된 학번·비밀번호(T-WIN 로그인용). 없으면 조회·신청을 하지 않는다.
  final ({String userId, String userPwd})? credentials;

  /// 본인의 실제 지도교수 성함. 기본 선택은 항상 이 값이다.
  final String? advisorName;

  /// 지도교수 성함을 아직 불러오는 중인지.
  final bool advisorLoading;

  /// 지도교수 직번(상담 현황 응답에서 얻음). 아직 모르면 null.
  final String? advisorStaffNo;

  /// 방문 신청의 학생 정보 칸('학번 학과 학년 이름'). 모르면 null.
  final String? studentInfoLine;

  /// 실제 신청을 학교로 보낼지. 화면에서 `kAllowRealAdvisorSubmit`를 넘긴다.
  final bool allowRealSubmit;

  /// 신청 완료 후 "상담 현황 보기"를 눌렀을 때 — 상담 현황 탭으로 전환.
  final VoidCallback onViewStatus;

  /// 신청이 학교에 접수됐을 때 — 상담 현황을 새로 받게 한다.
  final VoidCallback onSubmitted;

  @override
  State<AdvisorApplyTab> createState() => _AdvisorApplyTabState();
}

class _AdvisorApplyTabState extends State<AdvisorApplyTab> {
  static const int _minContentLength = 10;
  static const int _totalSteps = 4;

  final _searchController = TextEditingController();
  final _phoneMiddleController = TextEditingController();
  final _phoneLastController = TextEditingController();
  final _emailController = TextEditingController();
  final _contentController = TextEditingController();
  final _phoneFirstController = TextEditingController(text: '010');

  final _phoneFirstFocus = FocusNode();
  final _phoneMiddleFocus = FocusNode();
  final _phoneLastFocus = FocusNode();

  int _step = 0;
  bool _searching = false;
  bool _submitted = false;
  bool _submitting = false;
  ProfessorOption? _selectedProfessor;
  ConsultationMethod _selectedMethod = ConsultationMethod.online;
  DateTime? _selectedVisitDate;
  String? _selectedVisitTime;

  // 교수 검색 상태.
  String _searchedQuery = '';
  int _searchPage = 0;
  int _searchTotal = 0;
  bool _searchLoading = false;
  String? _searchError;
  final List<ProfessorOption> _searchResults = [];

  // 고른 날짜의 방문 가능 시간 조회 상태. 늦게 온 응답을 버리려고 번호를 센다.
  List<String> _visitTimes = const [];
  bool _visitTimesLoading = false;
  String? _visitTimesError;
  int _visitRequestId = 0;

  /// 10자 미만인 채로 신청을 눌러 본 적이 있는지 — 그 뒤로 10자가 채워질
  /// 때까지 입력창에 안내를 보여준다.
  bool _showContentError = false;

  @override
  void initState() {
    super.initState();
    _selectedProfessor = _advisorOption;
    _prefillEmail();
    for (final controller in [
      _phoneFirstController,
      _phoneMiddleController,
      _phoneLastController,
      _emailController,
      _contentController,
    ]) {
      controller.addListener(_onFieldChanged);
    }
  }

  ProfessorOption? get _advisorOption {
    final name = widget.advisorName;
    if (name == null) return null;
    return ProfessorOption(
      name: name,
      department: '지도교수',
      staffNo: widget.advisorStaffNo,
      isAdvisor: true,
    );
  }

  /// 저장된 로그인 학번(CredentialStorage)으로 학교 이메일을 미리 채워준다
  /// (v4 시안의 "20211476@daejin.ac.kr"처럼 학번+"@daejin.ac.kr" 형식).
  /// 자격증명이 없으면(세션 없이 들어온 경우 등) 빈 채로 둔다.
  Future<void> _prefillEmail() async {
    final credentials = await CredentialStorage().read();
    if (!mounted || credentials == null) return;
    setState(
      () => _emailController.text = '${credentials.userId}@daejin.ac.kr',
    );
  }

  void _onFieldChanged() => setState(() {});

  @override
  void didUpdateWidget(AdvisorApplyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 지도교수 성함·직번이 이 탭을 처음 그린 뒤에야 오는 경우를 대비한다 —
    // 아직 아무도 안 골랐거나 지도교수를 고른 상태일 때만 새 값으로 채운다
    // (사용자가 이미 다른 교수로 바꿨다면 덮어쓰지 않음).
    final selected = _selectedProfessor;
    final advisor = _advisorOption;
    if (advisor != null && (selected == null || selected.isAdvisor)) {
      final changed = selected?.staffNo != advisor.staffNo;
      setState(() => _selectedProfessor = advisor);
      if (changed && _isVisit && _selectedVisitDate != null) {
        _loadVisitTimes(_selectedVisitDate!);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _phoneFirstController.dispose();
    _phoneMiddleController.dispose();
    _phoneLastController.dispose();
    _phoneFirstFocus.dispose();
    _phoneMiddleFocus.dispose();
    _phoneLastFocus.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  bool get _isVisit => _selectedMethod == ConsultationMethod.visit;

  bool get _phoneValid =>
      _phoneFirstController.text.trim().length >= 3 &&
      _phoneMiddleController.text.trim().length == 4 &&
      _phoneLastController.text.trim().length == 4;

  bool get _emailValid => _emailController.text.trim().contains('@');

  bool get _contentValid =>
      advisorContentLength(_contentController.text) >= _minContentLength;

  bool get _methodStepValid {
    if (_selectedProfessor == null) return false;
    if (!_isVisit) return true;
    return _selectedVisitDate != null && _selectedVisitTime != null;
  }

  void _goNext() {
    if (_step == _totalSteps - 1) {
      if (!_contentValid) {
        setState(() => _showContentError = true);
        return;
      }
      _submit();
    } else {
      setState(() => _step++);
    }
  }

  void _goBack() => setState(() => _step--);

  Future<void> _submit() async {
    if (_submitting) return;
    if (!widget.allowRealSubmit) {
      showTopBanner(
        context,
        title: '아직 실제 신청은 막혀 있어요',
        message: '개발 중이라 교수님께 신청이 가지 않도록 막아 두었어요.',
        icon: Icons.lock_outline_rounded,
      );
      return;
    }

    final credentials = widget.credentials;
    final professor = _selectedProfessor;
    final staffNo = professor?.staffNo;
    if (credentials == null || professor == null || staffNo == null) {
      _showSubmitError('교수님 정보를 아직 불러오지 못했어요. 잠시 후 다시 시도해 주세요.');
      return;
    }
    final phone =
        '${_phoneFirstController.text.trim()}-'
        '${_phoneMiddleController.text.trim()}-'
        '${_phoneLastController.text.trim()}';
    final content = _contentController.text.trim();
    final email = _emailController.text.trim();

    setState(() => _submitting = true);
    try {
      if (_isVisit) {
        final studentInfo = widget.studentInfoLine;
        if (studentInfo == null) {
          throw StateError('학생 정보 없음');
        }
        await widget.service.submitVisit(
          userId: credentials.userId,
          userPwd: credentials.userPwd,
          request: VisitApplyRequest(
            professorStaffNo: staffNo,
            slot: VisitSlot(
              date: _selectedVisitDate!,
              time: _selectedVisitTime!,
            ),
            content: content,
            phone: phone,
            email: email,
            studentInfo: studentInfo,
          ),
        );
      } else {
        final advisorStaffNo = widget.advisorStaffNo;
        final advisorName = widget.advisorName;
        if (advisorStaffNo == null || advisorName == null) {
          throw StateError('지도교수 정보 없음');
        }
        await widget.service.submitOnline(
          userId: credentials.userId,
          userPwd: credentials.userPwd,
          request: OnlineApplyRequest(
            professorStaffNo: staffNo,
            content: content,
            phone: phone,
            email: email,
            advisorStaffNo: advisorStaffNo,
            advisorName: advisorName,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
      widget.onSubmitted();
    } on AdvisorSubmitBlockedException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSubmitError(e.toString());
    } catch (e) {
      debugPrint('[AdvisorApply] 신청 실패: $e');
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSubmitError(
        e is StateError
            ? '내 정보를 아직 불러오지 못했어요. 잠시 후 다시 시도해 주세요.'
            : advisorErrorMessage(e),
      );
    }
  }

  void _showSubmitError(String message) => showTopBanner(
    context,
    title: '상담 신청을 보내지 못했어요',
    message: message,
    icon: Icons.error_outline_rounded,
  );

  void _selectMethod(ConsultationMethod method) {
    setState(() {
      _selectedMethod = method;
      _clearVisitSelection();
    });
  }

  void _clearVisitSelection() {
    _selectedVisitDate = null;
    _selectedVisitTime = null;
    _visitTimes = const [];
    _visitTimesError = null;
    _visitTimesLoading = false;
    _visitRequestId++;
  }

  /// 날짜를 바꾸면 그 전 날짜 기준으로 골랐던 시간은 비우고, 그 날짜가 속한
  /// 주의 상담 가능 시간을 학교에 묻는다(같은 주는 서비스가 기억해 다시 묻지
  /// 않는다).
  void _selectVisitDate(DateTime date) {
    setState(() {
      _selectedVisitDate = date;
      _selectedVisitTime = null;
    });
    _loadVisitTimes(date);
  }

  Future<void> _loadVisitTimes(DateTime date) async {
    final requestId = ++_visitRequestId;
    final credentials = widget.credentials;
    final staffNo = _selectedProfessor?.staffNo;
    if (credentials == null || staffNo == null) {
      setState(() {
        _visitTimesLoading = false;
        _visitTimes = const [];
        _visitTimesError = credentials == null
            ? '로그인 정보가 없어 시간을 확인할 수 없어요.'
            : '교수님 정보를 불러오는 중이에요. 잠시 후 다시 시도해 주세요.';
      });
      return;
    }
    setState(() {
      _visitTimesLoading = true;
      _visitTimesError = null;
    });
    try {
      final slots = await widget.service.fetchVisitSlots(
        userId: credentials.userId,
        userPwd: credentials.userPwd,
        staffNo: staffNo,
        date: date,
      );
      if (!mounted || requestId != _visitRequestId) return;
      final now = DateTime.now();
      final times = [
        for (final s in slots)
          if (DateUtils.isSameDay(s.date, date) &&
              _slotDateTime(s).isAfter(now))
            s.time,
      ];
      setState(() {
        _visitTimesLoading = false;
        _visitTimes = times;
      });
    } catch (e) {
      debugPrint('[AdvisorApply] 방문 시간 조회 실패: $e');
      if (!mounted || requestId != _visitRequestId) return;
      setState(() {
        _visitTimesLoading = false;
        _visitTimes = const [];
        _visitTimesError = advisorErrorMessage(e);
      });
    }
  }

  static DateTime _slotDateTime(VisitSlot s) {
    final parts = s.time.split(':');
    return DateTime(
      s.date.year,
      s.date.month,
      s.date.day,
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0,
    );
  }

  /// 새 검색(검색 버튼·키보드 완료)이면 1페이지부터, [more]면 다음 페이지를
  /// 이어 붙인다.
  Future<void> _searchProfessors({bool more = false}) async {
    final credentials = widget.credentials;
    final query = more ? _searchedQuery : _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchedQuery = '';
        _searchResults.clear();
        _searchError = null;
        _searchPage = 0;
      });
      return;
    }
    if (credentials == null) {
      setState(() => _searchError = '로그인 정보가 없어 검색할 수 없어요.');
      return;
    }
    FocusScope.of(context).unfocus();
    final page = more ? _searchPage + 1 : 1;
    setState(() {
      _searchLoading = true;
      _searchError = null;
      if (!more) _searchResults.clear();
    });
    try {
      final result = await widget.service.searchProfessors(
        userId: credentials.userId,
        userPwd: credentials.userPwd,
        query: query,
        page: page,
      );
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
        _searchedQuery = query;
        _searchPage = page;
        _searchTotal = result.total;
        _searchResults.addAll([
          for (final p in result.professors)
            if (p.staffNo != widget.advisorStaffNo)
              ProfessorOption(
                name: p.name,
                department: p.department,
                staffNo: p.staffNo,
              ),
        ]);
      });
    } catch (e) {
      debugPrint('[AdvisorApply] 교수 검색 실패: $e');
      if (!mounted) return;
      setState(() {
        _searchLoading = false;
        _searchError = advisorErrorMessage(e);
      });
    }
  }

  void _selectProfessor(ProfessorOption professor) {
    setState(() {
      _selectedProfessor = professor;
      _searching = false;
      _clearVisitSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdvisorProfessorSummaryCard(
            advisorLoading: widget.advisorLoading,
            selectedProfessor: _selectedProfessor,
            searching: _searching,
            onToggleSearching: () => setState(() => _searching = !_searching),
          ),
          const SizedBox(height: 12),
          if (_submitted)
            AdvisorDoneCard(onViewStatus: widget.onViewStatus)
          else if (_searching)
            AdvisorProfessorSearchCard(
              searchController: _searchController,
              advisor: _advisorOption,
              results: _searchResults,
              loading: _searchLoading,
              errorMessage: _searchError,
              hasSearched: _searchedQuery.isNotEmpty,
              hasMore: _searchPage * 5 < _searchTotal,
              selectedProfessor: _selectedProfessor,
              onSearch: _searchProfessors,
              onLoadMore: () => _searchProfessors(more: true),
              onSelectProfessor: _selectProfessor,
            )
          else
            _buildCurrentStepCard(),
        ],
      ),
    );
  }

  Widget _buildCurrentStepCard() {
    return switch (_step) {
      0 when _isVisit => AdvisorMethodAndScheduleStep(
        step: _step,
        totalSteps: _totalSteps,
        selectedMethod: _selectedMethod,
        methodStepValid: _methodStepValid,
        onSelectMethod: _selectMethod,
        onNext: _goNext,
        selectedVisitDate: _selectedVisitDate,
        selectedVisitTime: _selectedVisitTime,
        onSelectVisitDate: _selectVisitDate,
        onSelectVisitTime: (time) => setState(() => _selectedVisitTime = time),
        times: _visitTimes,
        timesLoading: _visitTimesLoading,
        timesError: _visitTimesError,
        onRetryTimes: () => _loadVisitTimes(_selectedVisitDate!),
      ),
      0 => AdvisorMethodStep(
        step: _step,
        totalSteps: _totalSteps,
        selectedMethod: _selectedMethod,
        methodStepValid: _methodStepValid,
        onSelectMethod: _selectMethod,
        onNext: _goNext,
      ),
      1 => AdvisorPhoneStep(
        step: _step,
        totalSteps: _totalSteps,
        firstController: _phoneFirstController,
        middleController: _phoneMiddleController,
        lastController: _phoneLastController,
        firstFocus: _phoneFirstFocus,
        middleFocus: _phoneMiddleFocus,
        lastFocus: _phoneLastFocus,
        phoneValid: _phoneValid,
        onBack: _goBack,
        onNext: _goNext,
      ),
      2 => AdvisorEmailStep(
        step: _step,
        totalSteps: _totalSteps,
        controller: _emailController,
        emailValid: _emailValid,
        onBack: _goBack,
        onNext: _goNext,
      ),
      _ => AdvisorContentStep(
        step: _step,
        totalSteps: _totalSteps,
        controller: _contentController,
        minContentLength: _minContentLength,
        showError: _showContentError && !_contentValid,
        onBack: _goBack,
        onNext: _goNext,
      ),
    };
  }
}
