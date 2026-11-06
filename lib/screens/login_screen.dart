import 'package:flutter/material.dart';

import '../services/credential_storage.dart';
import '../services/portal_login_service.dart';
import '../services/service_factory.dart';
import '../services/session_cache.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/pressable.dart';
import 'post_login_route.dart';
import 'student_id_find_screen.dart';

/// 로그인 화면 ("우진이의 하루" v7 디자인 04).
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
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.blue,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textStrong,
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
                    backgroundColor: AppColors.blue,
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

      SessionCache.homepageCookie = result.homepageCookie;
      final next = await postLoginScreen(
        userId: userId,
        jsessionId: result.jsessionId,
        wmonid: result.wmonid,
        userId2: result.userId2,
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => next));
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
                  color: AppColors.blueSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, color: AppColors.blue),
              ),
              const SizedBox(height: 14),
              const Text(
                '비밀번호를 바꿔주세요',
                style: TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '비밀번호를 6개월 넘게 바꾸지 않았어요.\n학교 포털에서 비밀번호를 변경해주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSub,
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
                      backgroundColor: AppColors.blue,
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    // 키가 작은 화면(예 360x640)에서는 제목을 가리지 않도록 마스코트를 줄인다.
    final compact = MediaQuery.sizeOf(context).height < 740;
    return Scaffold(
      // 키보드 뒤쪽 빈 공간(둥근 키보드 양옆)에 파랑이 비치지 않도록 바탕은
      // 흰색으로 두고, 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      // 디자인에서 흰 카드가 화면 맨 밑(홈 인디케이터 뒤)까지 꽉 채워져 있어서
      // 바깥 SafeArea는 아래쪽을 비우고, 카드 안쪽 여백으로 안전 영역을 띄운다.
      body: ColoredBox(
        color: AppColors.blue,
        child: SafeArea(
          bottom: false,
          child: Column(
            // 제목 영역이 가운데로 몰리지 않고 화면 폭을 다 쓰게 한다.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(26, 14, 26, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: AppColors.blue,
                            ),
                            SizedBox(width: 3),
                            Text(
                              '대진대 재학생 인증',
                              style: TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w800,
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
                          fontSize: 32,
                          height: 1.4,
                          letterSpacing: -1.6,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 마스코트가 흰 카드 위로 걸쳐 보이도록 카드와 같은 Stack에
              // 넣고 카드보다 나중에 그린다. 카드 윗변 기준이라 화면 높이가
              // 달라도 카드에 발을 걸친 모양이 유지된다.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      32,
                      22,
                      bottomInset + 10 > 44 ? bottomInset + 10 : 44,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x0F000000),
                          offset: Offset(0, -4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoginField(
                          icon: Icons.badge_rounded,
                          label: '학번',
                          controller: _idController,
                          valueStyle: const TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 16,
                            height: 1.4,
                            letterSpacing: 0.48,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LoginField(
                          icon: Icons.lock_rounded,
                          label: '비밀번호',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          valueStyle: TextStyle(
                            color: AppColors.textStrong,
                            fontSize: _obscurePassword ? 17 : 16,
                            height: 1.4,
                            letterSpacing: _obscurePassword ? 3.4 : 0.48,
                            fontWeight: _obscurePassword
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                          trailing: Pressable.icon(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 19,
                                color: AppColors.textSub,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(6, 18, 6, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Pressable.effect(
                                    child: SizedBox(
                                      width: 44,
                                      height: 26,
                                      child: FittedBox(
                                        child: Switch(
                                          value: _autoLogin,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          activeTrackColor: AppColors.blue,
                                          activeThumbColor: Colors.white,
                                          inactiveTrackColor:
                                              AppColors.checkLine,
                                          inactiveThumbColor: Colors.white,
                                          trackOutlineColor:
                                              const WidgetStatePropertyAll(
                                                Colors.transparent,
                                              ),
                                          onChanged: (v) =>
                                              setState(() => _autoLogin = v),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    '자동 로그인',
                                    style: TextStyle(
                                      color: AppColors.textStrong,
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Pressable(
                                onTap: _onFindStudentId,
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '학번 찾기',
                                    style: TextStyle(
                                      color: AppColors.textBody,
                                      fontSize: 12,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1),
                                child: Icon(
                                  Icons.error_rounded,
                                  size: 15,
                                  color: _errorRed,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: _errorRed,
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: _errorMessage != null ? 28 : 73),
                        _LoginButton(
                          isLoading: _isLoading,
                          onPressed: _onSubmit,
                        ),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            '로그인이 안 되면 학생지원처로 문의해 주세요',
                            style: TextStyle(
                              color: AppColors.textSub,
                              fontSize: 12,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 마스코트. 키보드가 올라와 있는 동안은 입력창을 가리지
                  // 않도록 숨긴다. 그림이 탭을 가로채지 않게 IgnorePointer로 감싼다.
                  if (!keyboardOpen)
                    Positioned(
                      right: 5,
                      // 그림 높이(폭의 약 1.2배)에서 카드에 걸치는 만큼을 뺀 위치.
                      top: compact ? -146 : -227,
                      child: IgnorePointer(
                        child: MascotSticker(
                          width: compact ? 150 : 232,
                          angle: 0.0873,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 오류 안내 글자색(v7 디자인 07의 빨강).
  static const _errorRed = Color(0xFFCC272E);
}

/// 파란 그라데이션 로그인 버튼(디자인 04). 로그인 중에는 눌리지 않고 옅어진다.
class _LoginButton extends StatelessWidget {
  const _LoginButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  static const _gradientStart = Color(0xFF2B8CF0);

  @override
  Widget build(BuildContext context) {
    return Pressable.effect(
      enabled: !isLoading,
      pressedScale: 0.96,
      child: Opacity(
        opacity: isLoading ? 0.6 : 1,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gradientStart, AppColors.blue],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLoading ? '로그인 중...' : '로그인',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!isLoading) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 19),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 로그인 카드 안의 아이콘 + 라벨 + 입력창 한 세트.
/// 입력 중(포커스)에는 파란 테두리와 파란 아이콘 상자로 바뀐다(디자인 04).
class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.icon,
    required this.label,
    required this.controller,
    required this.valueStyle,
    this.obscureText = false,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextStyle valueStyle;
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
    // 라벨을 눌러도 입력창에 포커스가 가도록 칸 전체를 탭 영역으로 둔다.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focusNode.requestFocus,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 72,
        // 테두리 두께는 Container가 안쪽 여백에 더해 준다(1 또는 2).
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(16),
          border: _focused
              ? Border.all(color: AppColors.blue, width: 2)
              : Border.all(color: AppColors.fillDisabled),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _focused ? AppColors.blue : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                size: 19,
                color: _focused ? Colors.white : AppColors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    obscureText: widget.obscureText,
                    obscuringCharacter: '•',
                    cursorColor: AppColors.blue,
                    cursorWidth: 2,
                    style: widget.valueStyle,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.trailing != null) widget.trailing!,
          ],
        ),
      ),
    );
  }
}
