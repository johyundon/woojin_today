import 'package:flutter/material.dart';

import '../home_colors.dart';
import 'gradient_card.dart';

// 카드 브랜드 컬러(다크 모드). 아바타 메뉴 "로그아웃" 등 모드 무관 포인트 컬러로도 쓰인다.
const Color _accentOrangeDeep = Color(0xFFFF5B00);

// 라이트 모드 전용 카드 브랜드 컬러. 다크 모드와 동일한 원색은 흰 배경 위에서
// 너무 쨍하게 보여서, 채도/명도를 낮춘 별도 팔레트를 쓴다.
const Color _accentOrangeLight = Color(0xFFE46E25);
const Color _accentOrangeDeepLight = Color(0xFFC85719);

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "시간표를 짜볼까요?" 추천 카드.
class RecommendCard extends StatelessWidget {
  const RecommendCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GradientCard(
      onTap: onTap,
      height: 168,
      colors: isDark
          ? const [accentOrange, _accentOrangeDeep]
          : const [_accentOrangeLight, _accentOrangeDeepLight],
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Badge(label: '추천'),
            const SizedBox(height: 16),
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white,
              size: 26,
            ),
            const Spacer(),
            const Text(
              '시간표를 짜볼까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '나만의 시간표를 만들고 저장해보세요',
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
