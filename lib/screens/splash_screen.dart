import 'dart:async';

import 'package:flutter/material.dart';

import '../services/credential_storage.dart';
import '../services/portal_login_service.dart';
import '../services/service_factory.dart';
import '../services/session_cache.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'login_screen.dart';
import 'post_login_route.dart';

/// 스플래시 화면 ("우진이의 하루" v7 디자인 00).
/// 파란 그라데이션 배경 + 마스코트를 2초간 보여주는 동안, 저장된 로그인 자격증명이
/// 있으면 조용히 재로그인을 시도한다. 성공하면 로그인 화면을 거치지
/// 않고 로그인 후 화면(post_login_route.dart)으로, 저장된 값이 없거나 재로그인에 실패하면
/// 로그인 화면으로 이동한다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.portalLoginService,
    this.credentialStorage,
  });

  /// 테스트에서 가짜를 넣기 위한 값. 없으면 실제 서비스를 쓴다.
  final PortalLoginServiceBase? portalLoginService;
  final CredentialStorage? credentialStorage;

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

    final storage = widget.credentialStorage ?? CredentialStorage();
    final credentials = await storage.read();
    if (credentials == null) {
      await minDisplay;
      _goToLogin();
      return;
    }

    var loginSucceeded = false;
    PortalLoginResult? result;
    try {
      final portalLoginService =
          widget.portalLoginService ?? ServiceFactory.portalLogin();
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
      SessionCache.homepageCookie = result.homepageCookie;
      // 보통은 바로 로그인 완료 화면이지만, 약관 버전이 바뀌었거나 온보딩을
      // 끝내지 않은 학번이면 그 화면부터 보여준다.
      final next = await postLoginScreen(
        userId: credentials.userId,
        jsessionId: result.jsessionId,
        wmonid: result.wmonid,
        userId2: result.userId2,
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => next));
      return;
    }

    // 비밀번호를 학교에서 바꿨거나 계정이 없어진 경우. 저장된 값으로 또 시도하면
    // 앱을 켤 때마다 틀린 비밀번호가 학교에 쌓여 계정이 잠길 수 있으므로 지우고,
    // 로그인 화면에서 다시 입력하게 한다. 네트워크 오류 등은 비밀번호와 상관없어
    // 지우지 않는다.
    final reason = result?.failReason;
    if (reason == '비밀번호오류' || reason == '계정없음') {
      try {
        await storage.clear();
      } catch (e) {
        debugPrint('[Splash] 저장된 계정 지우기 실패: $e');
      }
      final remaining = result?.remainingAttempts;
      _goToLogin(
        userId: reason == '비밀번호오류' ? credentials.userId : null,
        notice: reason == '비밀번호오류'
            ? '저장된 비밀번호로 로그인하지 못했어요. 비밀번호를 바꿨다면 새 비밀번호로 '
                  '다시 로그인해 주세요.'
                  '${remaining != null ? ' ($remaining회 더 틀리면 계정이 잠길 수 있어요)' : ''}'
            : '저장된 학번으로 로그인하지 못했어요. 다시 로그인해 주세요.',
      );
      return;
    }
    _goToLogin();
  }

  Future<void> _startMinDisplayTimer() {
    final completer = Completer<void>();
    _minDisplayTimer = Timer(const Duration(seconds: 2), () {
      if (!completer.isCompleted) completer.complete();
    });
    return completer.future;
  }

  void _goToLogin({String? userId, String? notice}) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LoginScreen(initialUserId: userId, notice: notice),
      ),
    );
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    super.dispose();
  }

  // v7 디자인 00: 위에서 아래로 연한 하늘색 → 파랑으로 바뀌는 바탕.
  static const _gradientTop = Color(0xFF8CC2F7);
  static const _gradientMid = Color(0xFF3E93EE);
  static const _footerText = Color(0xFFE6F0FF);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradientTop, _gradientMid, AppColors.blue],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 300,
                      height: 300,
                      child: Center(
                        child: MascotSticker(width: 225, angle: -0.1047),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '대진대 새내기 가이드',
                        style: TextStyle(
                          color: AppColors.blueText,
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '우진이의 하루',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 44,
                        height: 1.4,
                        letterSpacing: -1.98,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 디자인에는 없지만 자동 로그인을 기다리는 중임을 알리던 표시는 남긴다.
            Positioned(
              left: 0,
              right: 0,
              bottom: 52 + 17 + 20,
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset > 52 ? bottomInset : 52,
              child: const Text(
                'DAEJIN UNIVERSITY',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _footerText,
                  fontSize: 12,
                  height: 1.4,
                  letterSpacing: 2.16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
