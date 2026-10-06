import 'package:flutter/material.dart';

import 'gradient_card.dart';

// 카드 브랜드 컬러(다크 모드). 아바타 메뉴 "로그아웃" 등 모드 무관 포인트 컬러로도 쓰인다.
const Color _accentPurple = Color(0xFF8B5CF6);
const Color _accentPurpleDeep = Color(0xFF6A3FE0);

// 라이트 모드 전용 카드 브랜드 컬러. 다크 모드와 동일한 원색은 흰 배경 위에서
// 너무 쨍하게 보여서, 채도/명도를 낮춘 별도 팔레트를 쓴다.
const Color _accentPurpleLight = Color(0xFF7E53E0);
const Color _accentPurpleDeepLight = Color(0xFF5F39C8);

/// "오늘의 메뉴는 무엇일까요?" 카드.
class MenuCard extends StatelessWidget {
  const MenuCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onTap,
      height: 156,
      colors: isDark
          ? const [_accentPurple, _accentPurpleDeep]
          : const [_accentPurpleLight, _accentPurpleDeepLight],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                color: isDark ? _accentPurpleDeep : _accentPurpleDeepLight,
                size: 16,
              ),
            ),
            const Spacer(),
            const Text(
              '오늘의 메뉴는\n무엇일까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '학식을 조회할 수 있어요!',
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
