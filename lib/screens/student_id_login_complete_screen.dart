import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'home_screen.dart';

/// 포털 로그인 완료 화면 (Figma node 6:11).
/// 디자인에 별도 버튼이 없어, 스플래시 화면(splash_screen.dart)과 동일한 방식으로
/// 일정 시간 뒤 자동으로 홈 화면으로 전환되도록 구현했다.
class StudentIdLoginCompleteScreen extends StatefulWidget {
  const StudentIdLoginCompleteScreen({
    super.key,
    this.jsessionId,
    this.wmonid,
    this.userId2,
  });

  /// 로그인 화면/스플래시 화면에서 전달받은 세션 쿠키 값. 로그인 흐름상
  /// 항상 있을 테지만 방어적으로 nullable로 둔다. [HomeScreen]에 그대로
  /// 전달한다.
  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  @override
  State<StudentIdLoginCompleteScreen> createState() =>
      _StudentIdLoginCompleteScreenState();
}

class _StudentIdLoginCompleteScreenState
    extends State<StudentIdLoginCompleteScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _goToHome);
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          jsessionId: widget.jsessionId,
          wmonid: widget.wmonid,
          userId2: widget.userId2,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 스플래시 화면(splash_screen.dart, v7 디자인 00)과 같은 그라데이션.
  static const _gradientTop = Color(0xFF8CC2F7);
  static const _gradientMid = Color(0xFF3E93EE);
  static const _footerText = Color(0xFFE6F0FF);

  @override
  Widget build(BuildContext context) {
    // 디자인에 따로 없는 화면이라 스플래시 화면(v7 디자인 00)과 같은 구성으로
    // 맞춘다: 파란 그라데이션 배경 + 마스코트 + 이름표 + 큰 제목.
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
                        '학생 정보를 불러왔어요',
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
                      '로그인되었습니다',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        height: 1.4,
                        letterSpacing: -1.62,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
