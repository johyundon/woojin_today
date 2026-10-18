import 'dart:async';

import 'package:flutter/material.dart';

import '../services/credential_storage.dart';
import '../services/portal_login_service.dart';
import '../services/service_factory.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'login_screen.dart';
import 'student_id_login_complete_screen.dart';

/// 스플래시 화면 ("우진이의 하루" v4 리디자인).
/// 코발트 배경 + 마스코트를 2초간 보여주는 동안, 저장된 로그인 자격증명이
/// 있으면 조용히 재로그인을 시도한다. 성공하면 로그인 화면을 거치지
/// 않고 바로 로그인 완료 화면으로, 저장된 값이 없거나 재로그인에 실패하면
/// 로그인 화면으로 이동한다.
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
      _goToLogin();
      return;
    }

    var loginSucceeded = false;
    PortalLoginResult? result;
    try {
      final portalLoginService = ServiceFactory.portalLogin();
      result = await portalLoginService.login(
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
    if (loginSucceeded && result != null) {
      _goToLoginComplete(
        jsessionId: result.jsessionId,
        wmonid: result.wmonid,
        userId2: result.userId2,
      );
    } else {
      _goToLogin();
    }
  }

  Future<void> _startMinDisplayTimer() {
    final completer = Completer<void>();
    _minDisplayTimer = Timer(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _goToLoginComplete({
    String? jsessionId,
    String? wmonid,
    String? userId2,
  }) {
    if (!mounted) return;
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

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              Container(
                width: 260,
                height: 260,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.cobaltDeep,
                  shape: BoxShape.circle,
                ),
                child: const MascotSticker(width: 190),
              ),
              const Spacer(flex: 1),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '대진대 새내기 가이드',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '우진이의 하루',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.lime,
                ),
              ),
              const Spacer(flex: 2),
              const Text(
                'DAEJIN UNIVERSITY',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
