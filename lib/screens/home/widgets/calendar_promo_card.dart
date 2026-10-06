import 'package:flutter/material.dart';

import '../home_colors.dart';

/// "우진이의 캘린더" 프로모 카드.
class CalendarPromoCard extends StatelessWidget {
  const CalendarPromoCard({required this.colors, required this.onTap});

  final HomeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '우진이의 캘린더',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '학교 일정을 알림으로 받아보세요',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Image.asset(
              colors.isDark
                  ? 'assets/images/calendar_mascot_dark.png'
                  : 'assets/images/calendar_mascot.png',
              width: 72,
              height: 68,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}
