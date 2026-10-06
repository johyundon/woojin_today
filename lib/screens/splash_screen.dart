import 'dart:async';

import 'package:flutter/material.dart';

import '../services/credential_storage.dart';
import '../services/portal_login_service.dart';
import '../theme/app_colors.dart';
import 'student_id_login_complete_screen.dart';
import 'terms_agreement_screen.dart';

/// 스플래시 화면 (Figma node 6:3).
/// 검은 배경 + 캐릭터 로고를 2초간 보여주는 동안, 저장된 로그인 자격증명이
/// 있으면 조용히 재로그인을 시도한다. 성공하면 약관 동의/로그인 화면을 거치지
/// 않고 바로 로그인 완료 화면으로, 저장된 값이 없거나 재로그인에 실패하면
/// 기존처럼 약관 동의 화면으로 이동한다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _minDisplayTimer;

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  Future<void> _attemptAutoLogin() async {
    // 스플래시를 최소 2초간 보여주는 동안 재로그인 시도를 병렬로 진행해,
    // 로그인 응답이 빨라도 화면이 번쩍이지 않고 느려도 추가로 기다린다.
    // Timer로 직접 만들어 dispose() 시 취소할 수 있게 한다(그냥
    // Future.delayed를 쓰면 위젯이 일찍 dispose돼도 타이머가 계속 남는다).
    final minDisplay = _startMinDisplayTimer();

    final credentials = await CredentialStorage().read();
    if (credentials == null) {
      await minDisplay;
      _goToTermsAgreement();
      return;
    }

    var loginSucceeded = false;
    try {
      final result = await PortalLoginService().login(
        userId: credentials.userId,
        userPwd: credentials.userPwd,
      );
      loginSucceeded = result.success;
    } catch (e) {
      // 계정없음/비밀번호오류/네트워크오류 등 어떤 이유든 사용자에게는
      // 조용히 기존 로그인 흐름으로 넘기고, 원인만 로그로 남긴다.
      debugPrint('[Splash] 자동 재로그인 실패: $e');
    }

    await minDisplay;
    if (!mounted) return;
    if (loginSucceeded) {
      _goToLoginComplete();
    } else {
      _goToTermsAgreement();
    }
  }

  Future<void> _startMinDisplayTimer() {
    final completer = Completer<void>();
    _minDisplayTimer = Timer(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void _goToTermsAgreement() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TermsAgreementScreen()),
    );
  }

  void _goToLoginComplete() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const StudentIdLoginCompleteScreen()),
    );
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/splash_character.png',
              width: 160,
              height: 185,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
