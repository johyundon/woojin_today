import 'package:flutter/material.dart';

import 'gradient_card.dart';

// 카드 브랜드 컬러(다크 모드). 아바타 메뉴 "로그아웃" 등 모드 무관 포인트 컬러로도 쓰인다.
const Color _accentBlue = Color(0xFF3D6CFF);
const Color _accentBlueDeep = Color(0xFF2448D1);

// 라이트 모드 전용 카드 브랜드 컬러. 다크 모드와 동일한 원색은 흰 배경 위에서
// 너무 쨍하게 보여서, 채도/명도를 낮춘 별도 팔레트를 쓴다.
const Color _accentBlueLight = Color(0xFF3762E6);
const Color _accentBlueDeepLight = Color(0xFF3049A6);

/// "나는 학과에서 몇등일까요?" 카드.
class RankCard extends StatelessWidget {
  const RankCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onTap,
      height: 156,
      colors: isDark
          ? const [_accentBlue, _accentBlueDeep]
          : const [_accentBlueLight, _accentBlueDeepLight],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 26),
            const Spacer(),
            const Text(
              '나는 학과에서\n몇등일까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '두근두근',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
