import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'login_screen.dart';

/// 온보딩 화면 ("우진이의 하루" v4 리디자인, 01 섹션 3번째 화면).
/// 로그인 전에 앱이 무엇을 해주는지 먼저 보여주는 소개 화면으로, "시작하기"와
/// "일단 구경만 할래" 모두 로그인 화면으로 이어진다 — 이 앱은 대진대 포털
/// 세션으로 직접 연동하는 구조라 로그인 없이 보여줄 수 있는 데이터가 없어서,
/// 게스트 모드용 화면을 별도로 설계하지 않았다.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _goToLogin(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '대진대 26학번 필수템',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '캠퍼스 처음이지?\n내가 다\n알려줄게!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 100),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _InfoChip(
                          icon: Icons.location_on,
                          iconColor: AppColors.cobalt,
                          backgroundColor: Colors.white,
                          label: '강의실 어디야',
                          angle: -0.1396, // -8˚
                        ),
                        const SizedBox(height: 28),
                        // 디자인에서 셔틀 칩만 오른쪽으로 더 들어가 있어서
                        // (강의실/학식 칩은 같은 왼쪽 선) 그대로 맞춘다.
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: _InfoChip(
                            icon: Icons.directions_bus,
                            iconColor: AppColors.ink,
                            backgroundColor: AppColors.blushPink,
                            label: '셔틀 몇 분 남음?',
                            angle: 0.0873, // +5˚
                          ),
                        ),
                        const SizedBox(height: 28),
                        _InfoChip(
                          icon: Icons.restaurant,
                          iconColor: AppColors.ink,
                          backgroundColor: AppColors.lime,
                          label: '오늘 학식 뭐임',
                          angle: -0.0698, // -4˚
                        ),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -40,
                    right: -40,
                    child: const MascotSticker(width: 240, angle: 0.18),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  _Dot(active: true),
                  SizedBox(width: 10),
                  _Dot(active: false),
                  SizedBox(width: 6),
                  _Dot(active: false),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () => _goToLogin(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lime,
                    foregroundColor: AppColors.ink,
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    '시작하기 →',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _goToLogin(context),
                  child: const Text(
                    '일단 구경만 할래',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    this.angle = 0,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;

  /// 라디안 단위 기울기. 디자인에서 칩마다 제각각 살짝 기울어진 스티커처럼
  /// 붙어있어서(CSS transform matrix 값을 그대로 역산한 각도), 칩마다 다른
  /// 값을 넘긴다.
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030A7F).withValues(alpha: 0.22),
              offset: const Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 18 : 6,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
