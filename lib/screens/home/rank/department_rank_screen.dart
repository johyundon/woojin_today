import 'package:flutter/material.dart';

import '../../../services/credential_storage.dart';
import '../../../services/service_factory.dart';
import '../../../services/session_cache.dart';
import '../../../services/twin_rank_service.dart';
import '../../../theme/app_colors.dart';
import 'department_codes.dart';
import 'department_picker_screen.dart';
import 'models/department_rank.dart';
import 'models/rank_calculator.dart';
import 'widgets/rank_hero_card.dart';
import 'widgets/rank_summary_cards.dart';

typedef Credentials = ({String userId, String userPwd});

/// "학과등수" 결과 화면("나 몇 등이야?").
///
/// 흐름: 학과 확인("내 정보") → 학번·비밀번호(자동 로그인 때 저장한 값, 없으면 입력)
/// → 학년("내 정보"의 학적 변동 내역, 없으면 학번으로 추정) → T-WIN 평점 조회(7일 캐시)
/// → 등수 계산.
/// 당겨서 새로고침하면 캐시를 무시하고 새로 받는다.
class DepartmentRankScreen extends StatefulWidget {
  const DepartmentRankScreen({
    required this.isDark,
    this.userId2,
    this.department,
    this.grade,
    this.service,
    this.readCredentials,
    this.now,
    super.key,
  });

  final bool isDark;

  /// "내 정보"에서 학과·학년을 읽을 때 쓴다([department]가 없을 때만).
  final String? userId2;

  /// 테스트용. 주면 "내 정보"를 조회하지 않고 이 학과·학년을 쓴다.
  final String? department;
  final int? grade;

  /// 테스트용 주입 지점들.
  final TwinRankServiceBase? service;
  final Future<Credentials?> Function()? readCredentials;
  final DateTime Function()? now;

  @override
  State<DepartmentRankScreen> createState() => _DepartmentRankScreenState();
}

class _DepartmentRankScreenState extends State<DepartmentRankScreen> {
  late final TwinRankServiceBase _service =
      widget.service ?? ServiceFactory.twinRank();

  String? _department;
  int? _grade;
  Credentials? _credentials;

  /// 학번·비밀번호를 폼에서 직접 입력했는지(틀리면 다시 입력받는다).
  bool _typedCredentials = false;

  bool _loading = true;
  bool _needCredentials = false;
  String? _error;
  DepartmentRank? _data;

  final _idController = TextEditingController();
  final _pwController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    if (widget.department != null) {
      _department = widget.department;
      _grade = widget.grade;
    } else {
      await _readStudentInfo();
    }
    final read = widget.readCredentials ?? CredentialStorage().read;
    Credentials? stored;
    try {
      stored = await read();
    } catch (_) {
      stored = null;
    }
    if (!mounted) return;
    if (stored == null) {
      setState(() {
        _loading = false;
        _needCredentials = true;
      });
      return;
    }
    _useCredentials(stored);
    await _load();
  }

  /// "내 정보"(홈에서 이미 불러와 캐시된 값)에서 학과와 학년("3학년")을 읽는다.
  Future<void> _readStudentInfo() async {
    final userId2 = widget.userId2;
    if (userId2 == null) return;
    try {
      final info = await SessionCache.getStudentInfo(
        ServiceFactory.studentInfo(),
        userId2: userId2,
      );
      _department = info.department?.trim();
      final digit = RegExp(r'\d').firstMatch(info.grade ?? '')?.group(0);
      _grade = digit == null ? null : int.parse(digit);
    } catch (_) {
      // 못 읽으면 학과는 직접 고르고, 학년은 학번으로 추정한다.
    }
  }

  void _useCredentials(Credentials credentials) {
    _credentials = credentials;
    _grade ??= estimateGrade(
      credentials.userId,
      (widget.now ?? DateTime.now)(),
    );
  }

  Future<void> _load({bool forceRefresh = false}) async {
    final credentials = _credentials;
    final department = _department;
    final grade = _grade;
    if (credentials == null || grade == null) return;
    final code = department == null ? null : departmentCodes[department];
    if (code == null) {
      setState(() {
        _loading = false;
        _error = department == null
            ? '학과 정보를 불러오지 못했어요. 학과를 직접 골라 주세요.'
            : '"$department"의 학과코드를 몰라요. 학과를 직접 골라 주세요.';
      });
      return;
    }

    setState(() {
      _loading = _data == null || !forceRefresh;
      _error = null;
    });
    try {
      final stats = await _service.fetchGradeStats(
        userId: credentials.userId,
        userPwd: credentials.userPwd,
        sustCd: code,
        shyrCd: '$grade',
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _needCredentials = false;
        _data = buildDepartmentRank(
          stats,
          departmentName: department!,
          grade: grade,
        );
      });
    } on TwinRankException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _data = null;
        _error = switch (e.failure) {
          TwinRankFailure.loginFailed => 'T-WIN 로그인에 실패했어요. 학번·비밀번호를 확인해 주세요.',
          TwinRankFailure.noData => '성적 정보를 찾지 못했어요. 잠시 후 다시 시도해 주세요.',
          TwinRankFailure.network => '네트워크 연결을 확인해 주세요.',
        };
        // 직접 입력한 학번·비밀번호가 틀렸으면 다시 입력받는다.
        if (e.failure == TwinRankFailure.loginFailed && _typedCredentials) {
          _needCredentials = true;
        }
      });
    }
  }

  Future<void> _submitCredentials() async {
    final id = _idController.text.trim();
    final pw = _pwController.text;
    if (id.isEmpty || pw.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _needCredentials = false;
      _loading = true;
    });
    _typedCredentials = true;
    _useCredentials((userId: id, userPwd: pw));
    await _load();
  }

  Future<void> _changeDepartment() async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => DepartmentPickerScreen(
          currentDepartment: _department ?? '',
          departmentNames: departmentCodes.keys.toList(),
          colleges: const {},
        ),
      ),
    );
    if (selected == null || selected == _department) return;
    setState(() {
      _department = selected;
      _data = null;
    });
    await _load();
  }

  Future<void> _changeGrade() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            for (var g = 1; g <= 4; g++)
              ListTile(
                title: Text(
                  '$g학년',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontWeight: g == _grade ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                trailing: g == _grade
                    ? const Icon(Icons.check, color: AppColors.cobalt)
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(g),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (selected == null || selected == _grade) return;
    setState(() {
      _grade = selected;
      _data = null;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              if (_credentials != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(
                      label: _department ?? '학과 선택',
                      onTap: _changeDepartment,
                    ),
                    _Chip(label: '$_grade학년', onTap: _changeGrade),
                  ],
                ),
              const SizedBox(height: 10),
              const Text(
                '나 몇 등이야?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.04,
                ),
              ),
              const SizedBox(height: 18),
              ..._body(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body() {
    if (_loading) {
      return const [
        SizedBox(height: 80),
        Center(child: CircularProgressIndicator(color: Colors.white)),
      ];
    }
    if (_needCredentials) {
      return [
        _CredentialsForm(
          idController: _idController,
          pwController: _pwController,
          error: _error,
          onSubmit: _submitCredentials,
        ),
      ];
    }
    final data = _data;
    if (data == null) {
      return [
        _Message(
          text: _error ?? '성적 정보를 불러오지 못했어요.',
          buttonLabel:
              _department != null && departmentCodes.containsKey(_department)
              ? '다시 시도'
              : '학과 고르기',
          onPressed:
              _department != null && departmentCodes.containsKey(_department)
              ? _load
              : _changeDepartment,
        ),
      ];
    }
    return [
      RankHeroCard(data: data),
      const SizedBox(height: 12),
      // 장학 카드(RankSummaryCards.showScholarship)와 과목별 석차 카드
      // (SubjectRankCard)는 실제 데이터가 없어 숨겨 둔다. 코드는 남겨 두었다.
      RankSummaryCards(data: data),
    ];
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.lime,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.ink,
            ),
          ],
        ),
      ),
    );
  }
}

/// 자동 로그인을 끄고 로그인해 기기에 학번·비밀번호가 없을 때 받는 입력 폼.
/// 입력한 값은 이 화면에서만 쓰고 저장하지 않는다.
class _CredentialsForm extends StatelessWidget {
  const _CredentialsForm({
    required this.idController,
    required this.pwController,
    required this.error,
    required this.onSubmit,
  });

  final TextEditingController idController;
  final TextEditingController pwController;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F1F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '학번과 비밀번호가 필요해요',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '등수는 T-WIN에 따로 로그인해서 가져와요. 입력한 값은 저장하지 않아요.',
            style: TextStyle(color: Color(0xFF6B6B70), fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: idController,
            keyboardType: TextInputType.number,
            decoration: decoration('학번'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: pwController,
            obscureText: true,
            decoration: decoration('비밀번호'),
            onSubmitted: (_) => onSubmit(),
          ),
          if (error != null) ...[
            const SizedBox(height: 10),
            Text(
              error!,
              style: const TextStyle(color: Color(0xFFE5484D), fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.cobalt,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '등수 보기',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            text,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.lime,
              foregroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              buttonLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
