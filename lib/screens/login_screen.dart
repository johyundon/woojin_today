import 'package:flutter/material.dart';

import '../services/credential_storage.dart';
import '../services/portal_login_service.dart';
import '../services/service_factory.dart';
import '../services/terms_acceptance_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/pressable.dart';
import 'student_id_find_screen.dart';
import 'student_id_login_complete_screen.dart';
import 'terms_agreement_screen.dart';

/// 로그인 화면 ("우진이의 하루" v4 리디자인).
/// 로그인 성공 후, 약관에 아직 동의하지 않은 기기라면(최초 로그인) 약관 동의
/// 화면을 한 번 거치고, 이미 동의한 적이 있으면 바로 로그인 완료 화면으로
/// 넘어간다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _autoLogin = true;

  final _portalLoginService = ServiceFactory.portalLogin();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 입력값 검증 에러를 학번 찾기 화면과 같은 모양의 알림창으로 보여준다.
  Future<void> _showMessage(String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.cobalt.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.cobalt,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Pressable.effect(
                pressedScale: 0.96,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cobalt,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    '확인',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit() async {
    final userId = _idController.text;
    final userPwd = _passwordController.text;
    final hasInput = userId.isNotEmpty && userPwd.isNotEmpty;
    if (!hasInput) {
      _showMessage('학번과 비밀번호를 입력해주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    PortalLoginResult result;
    try {
      result = await _portalLoginService.login(
        userId: userId,
        userPwd: userPwd,
      );
    } on PortalLoginException catch (e) {
      // 사용자에게는 뭉뚱그린 안내만 보여주지만, 실제 원인(타임아웃/리다이렉트
      // 초과/서버 응답 코드 등)은 콘솔에 남겨서 재현 시 바로 진단할 수 있게 한다.
      debugPrint('[PortalLogin] 로그인 실패 원인: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '네트워크 또는 서버 오류가 발생했어요. 잠시 후 다시 시도해주세요.';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      if (_autoLogin) {
        try {
          await CredentialStorage().save(userId: userId, userPwd: userPwd);
        } catch (e) {
          // 저장 실패가 로그인 자체를 막아서는 안 된다. 다음 앱 시작 시
          // 자동 재로그인만 안 될 뿐이므로 로그만 남기고 진행한다.
          debugPrint('[CredentialStorage] 자격증명 저장 실패: $e');
        }
      }
      if (!mounted) return;

      if (result.passwordChangeOverdue) {
        await _showPasswordChangeNotice();
        if (!mounted) return;
      }

      final hasAcceptedTerms = await TermsAcceptanceStorage().hasAccepted();
      if (!mounted) return;

      if (hasAcceptedTerms) {
        _goToLoginComplete(
          jsessionId: result.jsessionId,
          wmonid: result.wmonid,
          userId2: result.userId2,
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TermsAgreementScreen(
              jsessionId: result.jsessionId,
              wmonid: result.wmonid,
              userId2: result.userId2,
            ),
          ),
        );
      }
      return;
    }

    switch (result.failReason) {
      case '계정없음':
        setState(() => _errorMessage = '일치하는 계정을 찾지 못했어요.');
      case '비밀번호오류':
        final remaining = result.remainingAttempts;
        setState(
          () => _errorMessage = remaining != null
              ? '비밀번호가 올바르지 않아요. 비밀번호가 $remaining회 더 틀리면 계정이 잠길 수 있어요.'
              : '비밀번호가 올바르지 않아요.',
        );
      default:
        setState(() => _errorMessage = '로그인에 실패했어요. 잠시 후 다시 시도해주세요.');
    }
  }

  /// 비밀번호를 6개월 넘게 바꾸지 않은 계정에 보여주는 안내. 로그인은
  /// 막지 않고, "확인"을 누르면 원래 가던 화면으로 이어진다. 앱을 켤 때의
  /// 자동 로그인(splash_screen.dart)에서는 띄우지 않는다.
  Future<void> _showPasswordChangeNotice() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCE6FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, color: AppColors.cobalt),
              ),
              const SizedBox(height: 14),
              const Text(
                '비밀번호를 바꿔주세요',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '비밀번호를 6개월 넘게 바꾸지 않았어요.\n학교 포털에서 비밀번호를 변경해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B6B70),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Pressable.effect(
                  pressedScale: 0.96,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cobalt,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goToLoginComplete({
    String? jsessionId,
    String? wmonid,
    String? userId2,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentIdLoginCompleteScreen(
          jsessionId: jsessionId,
          wmonid: wmonid,
          userId2: userId2,
        ),
      ),
    );
  }

  Future<void> _onFindStudentId() async {
    final foundStudentId = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const StudentIdFindScreen()),
    );
    if (foundStudentId != null) {
      _idController.text = foundStudentId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 키보드 뒤쪽 빈 공간(둥근 키보드 양옆)에 파랑이 비치지 않도록 바탕은
      // 흰색으로 두고, 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      // 디자인에서 흰 카드가 화면 맨 밑(홈 인디케이터 뒤)까지 꽉 채워져 있어서
      // 바깥 SafeArea는 아래쪽을 비우고, 카드 안쪽 콘텐츠에서만 다시
      // SafeArea로 안전 영역을 띄운다.
      // 마스코트가 카드(텍스트 입력창) 위로도 넘어와야 해서, 마스코트를
      // 맨 바깥 Stack의 마지막 자식으로 따로 빼둔다 — Column 안에 있으면
      // 아무리 겹쳐도 바로 아래의 흰 카드보다 앞으로 나올 수 없기 때문이다.
      body: ColoredBox(
        color: AppColors.cobalt,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // 원은 글자보다 뒤로 간다(원 → 글자 순서).
                                Positioned(
                                  left: 134,
                                  top: 76,
                                  child: Container(
                                    width: 300,
                                    height: 300,
                                    decoration: const BoxDecoration(
                                      color: AppColors.cobaltDeep,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.lime,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            size: 14,
                                            color: AppColors.ink,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            '대진대 재학생 인증',
                                            style: TextStyle(
                                              color: AppColors.ink,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    const Text(
                                      '반가워!\n학교 계정으로\n로그인',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 40,
                                        height: 1.1,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      24,
                      20,
                      30 + MediaQuery.of(context).padding.bottom,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, -12),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoginField(
                          icon: Icons.badge,
                          label: '학번',
                          controller: _idController,
                        ),
                        const SizedBox(height: 14),
                        _LoginField(
                          icon: Icons.lock,
                          label: '비밀번호',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          trailing: Pressable.effect(
                            pressedScale: 0.85,
                            child: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 24,
                                color: Colors.black45,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Transform.scale(
                                  scale: 0.85,
                                  child: Switch(
                                    value: _autoLogin,
                                    activeTrackColor: AppColors.cobalt,
                                    activeThumbColor: Colors.white,
                                    onChanged: (v) =>
                                        setState(() => _autoLogin = v),
                                  ),
                                ),
                                const Text(
                                  '자동 로그인',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            _PressFadeText(
                              onTap: _onFindStudentId,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 14),
                                child: Text(
                                  '학번 찾기',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: AppColors.error,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        Pressable.effect(
                          enabled: !_isLoading,
                          pressedScale: 0.96,
                          child: Container(
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: BorderRadius.circular(31),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cobalt.withValues(
                                    alpha: 0.4,
                                  ),
                                  offset: const Offset(0, 12),
                                  blurRadius: 26,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cobalt,
                                disabledBackgroundColor: AppColors.cobalt
                                    .withValues(alpha: 0.5),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: Text(
                                _isLoading ? '로그인 중...' : '로그인 →',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            '로그인이 안 되면 학생지원처로 문의해 주세요',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 마스코트. 카드보다 나중에(바깥 Stack의 뒤쪽 자식으로) 그려서
            // 카드 위로도 걸쳐 보이게 한다. 화면 기준 고정 위치라 키보드가
            // 올라와 카드와 글자가 움직이면 혼자 위에 떠 버리므로, 키보드가
            // 올라와 있는 동안은 숨긴다.
            if (MediaQuery.of(context).viewInsets.bottom == 0)
              const Positioned(
                left: 140,
                top: 170,
                child: MascotSticker(width: 240, angle: 0.1),
              ),
          ],
        ),
      ),
    );
  }
}

/// 로그인 카드 안의 아이콘 + 라벨 + 입력창 한 세트.
class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.icon,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final Widget? trailing;

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3EF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _focused ? AppColors.cobalt : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.cobalt,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(widget.icon, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              cursorColor: AppColors.cobalt,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              // 비어 있고 포커스가 없을 땐 라벨이 입력창 가운데에 있다가,
              // 입력/포커스하면 작아지면서 위로 올라간다(플로팅 라벨).
              decoration: InputDecoration(
                labelText: widget.label,
                labelStyle: const TextStyle(
                  color: Color(0xFF5A5852),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                // 올라갈 때 0.75배로 줄어들므로 16 → 12(기존 라벨 크기)가 된다.
                floatingLabelStyle: const TextStyle(
                  color: Color(0xFF5A5852),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}

/// 누르는 동안 [child]가 연해졌다가 손을 떼면 돌아오는 탭 영역.
class _PressFadeText extends StatefulWidget {
  const _PressFadeText({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressFadeText> createState() => _PressFadeTextState();
}

class _PressFadeTextState extends State<_PressFadeText> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: _pressed ? 0.4 : 1,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
