import 'package:flutter/material.dart';

import '../../../services/credential_storage.dart';
import '../../../theme/app_colors.dart';
import '../models/advisor_consultation_models.dart';
import '../services/advisor_consultation_mock_data.dart';

/// "지도교수 상담 신청" 탭 본문 — 상담교수/상담방식 선택 → 전화번호 → 이메일 →
/// 상담 내용 4단계 (Figma node 6:123 "지도교수상담 - 온라인 상담", 스크린샷
/// 8장). "방문 상담"을 골라도 같은 4단계를 그대로 쓴다 — 스크린샷엔 "온라인
/// 상담" 흐름만 있고 "방문 상담" 전용 흐름은 없어서, 교수와 연락할 방법은
/// 상담 방식과 무관하게 똑같이 필요하다고 보고 그대로 재사용했다.
class AdvisorApplyTab extends StatefulWidget {
  const AdvisorApplyTab({
    super.key,
    required this.advisorName,
    required this.advisorLoading,
  });

  /// 본인의 실제 지도교수 성함. 기본 선택은 항상 이 값이다.
  final String? advisorName;

  /// 지도교수 성함을 아직 불러오는 중인지.
  final bool advisorLoading;

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

  int _step = 0;
  bool _searching = false;
  ProfessorOption? _selectedProfessor;
  ConsultationMethod? _selectedMethod;

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
  /// (Figma 스크린샷의 "20211476@daejin.ac.kr"처럼 학번+"@daejin.ac.kr"
  /// 형식). 자격증명이 없으면(세션 없이 들어온 경우 등) 빈 채로 둔다.
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

  bool get _phoneValid =>
      _phoneFirstController.text.trim().length >= 3 &&
      _phoneMiddleController.text.trim().length == 4 &&
      _phoneLastController.text.trim().length == 4;

  bool get _emailValid => _emailController.text.trim().contains('@');

  bool get _contentValid =>
      _contentController.text.trim().length >= _minContentLength;

  void _goNext() => setState(() => _step++);

  void _goBack() => setState(() => _step--);

  void _submit() {
    // 상담 신청 API가 없는 목데이터 화면이라 실제 서버로 전송되지 않는다 —
    // 신청 흐름만 흉내내고 스낵바로 확인만 보여준다.
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('상담을 신청했어요')));
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _buildProfessorAndMethodStep(),
      _buildPhoneStep(),
      _buildEmailStep(),
      _buildContentStep(),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: steps[_step],
    );
  }

  // ── 1단계: 상담교수 + 상담방식 ────────────────────────────────────────

  Widget _buildProfessorAndMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProfessorCard(),
        const SizedBox(height: 24),
        const Text(
          '무슨 상담을 원하세요?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _buildMethodButtons(),
        const SizedBox(height: 20),
        _buildPrimaryButton(
          label: '다음',
          enabled: _selectedProfessor != null && _selectedMethod != null,
          onTap: _goNext,
        ),
      ],
    );
  }

  Widget _buildProfessorCard() {
    if (_searching) return _buildSearchPanel();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '상담교수',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _buildSelectedProfessorLabel(),
              ],
            ),
          ),
          if (_selectedProfessor != null)
            TextButton(
              onPressed: () => setState(() => _searching = true),
              child: const Text(
                '변경',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedProfessorLabel() {
    if (widget.advisorLoading && _selectedProfessor == null) {
      return const Row(
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '불러오는 중...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      );
    }

    final professor = _selectedProfessor;
    if (professor == null) {
      return const Text(
        '지도교수 정보를 불러올 수 없어요',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
      );
    }

    return Text(
      professor.isAdvisor
          ? '${professor.name} (지도교수)'
          : '${professor.name} (${professor.department})',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildSearchPanel() {
    final professors = _filteredProfessors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '상담교수',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _searching = false;
                  _searchController.clear();
                }),
                child: const Text(
                  '닫기',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: '교수님 이름으로 검색',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.disabledButton,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (professors.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '검색 결과가 없어요',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            )
          else
            for (final professor in professors) _buildProfessorRow(professor),
        ],
      ),
    );
  }

  Widget _buildProfessorRow(ProfessorOption professor) {
    final isSelected = _selectedProfessor?.name == professor.name;
    return InkWell(
      onTap: () => setState(() {
        _selectedProfessor = professor;
        _searching = false;
        _searchController.clear();
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          professor.isAdvisor
              ? '${professor.name} (지도교수)'
              : '${professor.name}    ${professor.department}',
          style: TextStyle(
            color: isSelected ? AppColors.accent : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildMethodButtons() {
    return Row(
      children: [
        Expanded(child: _buildMethodButton(ConsultationMethod.online)),
        const SizedBox(width: 10),
        Expanded(child: _buildMethodButton(ConsultationMethod.visit)),
      ],
    );
  }

  Widget _buildMethodButton(ConsultationMethod method) {
    final selected = _selectedMethod == method;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedMethod = method),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.accent : Colors.transparent,
        foregroundColor: selected ? Colors.white : AppColors.textSecondary,
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: const StadiumBorder(),
      ),
      child: Text(
        method.label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }

  // ── 2단계: 전화번호 ──────────────────────────────────────────────────

  Widget _buildPhoneStep() {
    return _buildStepCard(
      title: '전화번호를 입력해주세요',
      content: Row(
        children: [
          Expanded(child: _buildPhoneBox(_phoneFirstController, maxLength: 3)),
          const SizedBox(width: 8),
          Expanded(child: _buildPhoneBox(_phoneMiddleController, maxLength: 4)),
          const SizedBox(width: 8),
          Expanded(child: _buildPhoneBox(_phoneLastController, maxLength: 4)),
        ],
      ),
      onBack: _goBack,
      onNext: _goNext,
      nextEnabled: _phoneValid,
    );
  }

  Widget _buildPhoneBox(TextEditingController controller, {int? maxLength}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: maxLength,
      textAlign: TextAlign.center,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        counterText: '',
        filled: true,
        fillColor: AppColors.disabledButton,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── 3단계: 이메일 ────────────────────────────────────────────────────

  Widget _buildEmailStep() {
    return _buildStepCard(
      title: '이메일을 입력해주세요',
      content: TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.disabledButton,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onBack: _goBack,
      onNext: _goNext,
      nextEnabled: _emailValid,
    );
  }

  // ── 4단계: 상담 내용 ─────────────────────────────────────────────────

  Widget _buildContentStep() {
    return _buildStepCard(
      title: '어떤 이야기를 나누고 싶어요?',
      content: TextField(
        controller: _contentController,
        minLines: 5,
        maxLines: 8,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: '$_minContentLength자 이상 적어주세요',
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          filled: true,
          fillColor: AppColors.disabledButton,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      onBack: _goBack,
      onNext: _submit,
      nextLabel: '상담 신청하기',
      nextEnabled: _contentValid,
    );
  }

  // ── 공통 ────────────────────────────────────────────────────────────

  /// 2~4단계가 공유하는 뼈대: 어두운 카드 안에 제목 + 입력 영역, 그 아래
  /// "이전"(테두리만) + 다음/제출(주황, 조건 안 맞으면 비활성) 버튼.
  Widget _buildStepCard({
    required String title,
    required Widget content,
    required VoidCallback onBack,
    required VoidCallback onNext,
    required bool nextEnabled,
    String nextLabel = '다음',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              content,
              const SizedBox(height: 14),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 13,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '이전',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildPrimaryButton(
                      label: nextLabel,
                      enabled: nextEnabled,
                      onTap: onNext,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.disabledButton,
          disabledForegroundColor: AppColors.disabledButtonText,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
