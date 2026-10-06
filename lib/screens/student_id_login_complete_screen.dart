import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '학생 정보를 불러왔어요',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
                ),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/login_complete_character.png',
                width: 140,
                height: 148,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                '로그인되었습니다',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
