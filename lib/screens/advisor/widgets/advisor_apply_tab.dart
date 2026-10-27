import 'package:flutter/material.dart';

import '../../../services/credential_storage.dart';
import '../models/advisor_consultation_models.dart';
import '../services/advisor_consultation_mock_data.dart';
import 'advisor_apply_content_step.dart';
import 'advisor_apply_done_card.dart';
import 'advisor_apply_email_step.dart';
import 'advisor_apply_method_step.dart';
import 'advisor_apply_phone_step.dart';
import 'advisor_apply_professor_summary_card.dart';
import 'advisor_apply_search_card.dart';

/// "상담 신청" 탭 본문(v4 리디자인). 상담교수는 모든 단계에서 항상 위에
/// 떠 있고(눌러서 "변경"하면 검색 패널로 교체), 그 아래 단계 카드는 고른
/// 상담 방식에 따라 갈린다 — 온라인 상담은 교수/방식→전화번호→이메일→
/// 상담 내용 4단계, 방문 상담은 교수/방식+시간 선택→상담 내용 2단계로
/// 끝난다(방문은 전화/이메일을 안 받는다). 마지막에 신청하면 같은 자리에
/// 완료 카드가 뜬다.
class AdvisorApplyTab extends StatefulWidget {
  const AdvisorApplyTab({
    super.key,
    required this.advisorName,
    required this.advisorLoading,
    required this.onViewStatus,
  });

  /// 본인의 실제 지도교수 성함. 기본 선택은 항상 이 값이다.
  final String? advisorName;

  /// 지도교수 성함을 아직 불러오는 중인지.
  final bool advisorLoading;

  /// 신청 완료 후 "상담 현황 보기"를 눌렀을 때 — 상담 현황 탭으로 전환.
  final VoidCallback onViewStatus;

  @override
  State<AdvisorApplyTab> createState() => _AdvisorApplyTabState();
}

class _AdvisorApplyTabState extends State<AdvisorApplyTab> {
  static const int _minContentLength = 10;

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
  ProfessorOption? _selectedProfessor;
  ConsultationMethod _selectedMethod = ConsultationMethod.online;
  DateTime? _selectedVisitDate;
  String? _selectedVisitTime;

  /// 10자 미만인 채로 신청을 눌러 본 적이 있는지 — 그 뒤로 10자가 채워질
  /// 때까지 입력창에 안내를 보여준다.
  bool _showContentError = false;

  @override
  void initState() {
    super.initState();
    if (widget.advisorName != null) {
      _selectedProfessor = ProfessorOption(
        name: widget.advisorName!,
        department: '지도교수',
        isAdvisor: true,
      );
    }
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
    // 지도교수 조회가 이 탭을 처음 그린 뒤에야 끝나는 경우를 대비한다 — 아직
    // 아무 교수도 선택되지 않았을 때만 기본값으로 채운다(사용자가 이미 다른
    // 교수로 바꿨다면 덮어쓰지 않음).
    if (widget.advisorName != null && _selectedProfessor == null) {
      setState(() {
        _selectedProfessor = ProfessorOption(
          name: widget.advisorName!,
          department: '지도교수',
          isAdvisor: true,
        );
      });
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

  List<ProfessorOption> get _allProfessors {
    final advisorName = widget.advisorName;
    return [
      if (advisorName != null)
        ProfessorOption(name: advisorName, department: '지도교수', isAdvisor: true),
      ...AdvisorConsultationMockData.otherProfessors,
    ];
  }

  List<ProfessorOption> get _filteredProfessors {
    final query = _searchController.text.trim();
    if (query.isEmpty) return _allProfessors;
    return _allProfessors.where((p) => p.name.contains(query)).toList();
  }

  bool get _isVisit => _selectedMethod == ConsultationMethod.visit;

  /// 방문 상담이면 교수/방식+시간 선택 → 상담 내용 2단계, 온라인이면
  /// 교수/방식 → 전화번호 → 이메일 → 상담 내용 4단계.
  int get _totalSteps => _isVisit ? 2 : 4;

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

  void _submit() {
    // 상담 신청 API가 없는 목데이터 화면이라 실제 서버로 전송되지 않는다 —
    // 신청 흐름만 흉내내고 완료 카드로 넘어간다.
    setState(() => _submitted = true);
  }

  void _selectMethod(ConsultationMethod method) {
    setState(() {
      _selectedMethod = method;
      _selectedVisitDate = null;
      _selectedVisitTime = null;
    });
  }

  /// 날짜를 바꾸면 그 전 날짜 기준으로 골랐던 시간은 비운다 — 날짜마다
  /// 상담 가능 시간이 다를 수 있다는 전제를 지키기 위함(지금은 목데이터라
  /// 모든 날짜가 같은 시간 목록을 쓰지만, 실제 API가 생기면 날짜별로
  /// 달라질 수 있다).
  void _selectVisitDate(DateTime date) {
    setState(() {
      _selectedVisitDate = date;
      _selectedVisitTime = null;
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
              professors: _filteredProfessors,
              selectedProfessor: _selectedProfessor,
              onQueryChanged: () => setState(() {}),
              onSelectProfessor: (professor) => setState(() {
                _selectedProfessor = professor;
                _searching = false;
                _searchController.clear();
              }),
            )
          else
            _buildCurrentStepCard(),
        ],
      ),
    );
  }

  Widget _buildCurrentStepCard() {
    if (_isVisit) {
      return _step == 0
          ? AdvisorMethodAndScheduleStep(
              step: _step,
              totalSteps: _totalSteps,
              selectedMethod: _selectedMethod,
              methodStepValid: _methodStepValid,
              onSelectMethod: _selectMethod,
              onNext: _goNext,
              selectedVisitDate: _selectedVisitDate,
              selectedVisitTime: _selectedVisitTime,
              onSelectVisitDate: _selectVisitDate,
              onSelectVisitTime: (time) =>
                  setState(() => _selectedVisitTime = time),
            )
          : AdvisorContentStep(
              step: _step,
              totalSteps: _totalSteps,
              controller: _contentController,
              minContentLength: _minContentLength,
              showError: _showContentError && !_contentValid,
              onBack: _goBack,
              onNext: _goNext,
            );
    }
    return switch (_step) {
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
