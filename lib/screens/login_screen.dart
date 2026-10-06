import 'package:flutter/material.dart';

import '../services/credential_storage.dart';
import '../services/portal_login_service.dart';
import '../theme/app_colors.dart';
import '../widgets/app_text_field.dart';
import '../widgets/primary_button.dart';
import 'student_id_find_screen.dart';
import 'student_id_login_complete_screen.dart';

/// 로그인 화면 (Figma node 6:7 기본 상태 / 6:8 검증 오류·포커스 상태).
/// 두 노드는 별도 화면이 아니라 같은 로그인 화면의 상태 차이(포커스 전/후,
/// 미입력 오류 표시 여부)라고 판단해 하나의 StatefulWidget으로 구현했다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _privacyExpanded = false;
  bool _isLoading = false;

  final _portalLoginService = PortalLoginService();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final userId = _idController.text;
    final userPwd = _passwordController.text;
    final hasInput = userId.isNotEmpty && userPwd.isNotEmpty;
    if (!hasInput) {
      setState(() => _errorMessage = '학번과 비밀번호를 입력해주세요.');
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
      try {
        await CredentialStorage().save(userId: userId, userPwd: userPwd);
      } catch (e) {
        // 저장 실패가 로그인 자체를 막아서는 안 된다. 다음 앱 시작 시
        // 자동 재로그인만 안 될 뿐이므로 로그만 남기고 진행한다.
        debugPrint('[CredentialStorage] 자격증명 저장 실패: $e');
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => StudentIdLoginCompleteScreen(
            jsessionId: result.jsessionId,
            wmonid: result.wmonid,
            userId2: result.userId2,
          ),
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Image.asset(
                'assets/images/login_character.png',
                width: 132,
                height: 192,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 22),
              const Text(
                '우진이의 하루!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 32),
              AppTextField(controller: _idController, hintText: '학번'),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordController,
                hintText: '비밀번호',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () async {
                    final foundStudentId = await Navigator.of(context)
                        .push<String>(
                          MaterialPageRoute(
                            builder: (_) => const StudentIdFindScreen(),
                          ),
                        );
                    if (foundStudentId != null) {
                      _idController.text = foundStudentId;
                    }
                  },
                  child: const Text(
                    '학번을 찾아드릴까요?',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
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
              const SizedBox(height: 22),
              PrimaryButton(
                label: _isLoading ? '로그인 중...' : '시작해볼까요?',
                enabled: !_isLoading,
                onPressed: _onSubmit,
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 16),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _privacyExpanded = !_privacyExpanded),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '개인정보는 어떻게 관리되나요?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Icon(
                      _privacyExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
              if (_privacyExpanded) ...[
                const SizedBox(height: 12),
                const Text(
                  '[우진이의 하루]는 대진대학교 서버와 직접 통신합니다. 별도의 서버가 '
                  '존재하지 않아 민감정보(전화번호, 이름, 생년월일, 학번, 비밀번호 '
                  '등)등은 모두 휴대폰에 저장되고 활용되며 앱 삭제시 전부 폐기 '
                  '처리됩니다. 따라서 앱을 삭제하거나 휴대폰을 변경하는 등의 경우 '
                  '이전 앱의 정보는 공유되지 않습니다.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
