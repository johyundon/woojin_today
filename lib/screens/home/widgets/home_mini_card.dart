import 'package:flutter/material.dart';

/// 홈 화면 "다음 수업" 카드 아래 나란히 놓이는 작은 카드
/// ("우진이의 하루" v4 리디자인). 둥근 네모 아이콘 + 라벨 + 제목 + 아래 [footer].
/// 배경/글자 색을 받아서 검은 카드와 분홍 카드에 함께 쓴다.
class HomeMiniCard extends StatelessWidget {
  const HomeMiniCard({
    super.key,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.label,
    required this.title,
    required this.footer,
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    this.titleColor,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String label;
  final String title;
  final Widget footer;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;

  /// 제목 색. null이면 [textColor]를 쓴다(검은 카드에서만 라임색 등으로 다르게 준다).
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 156,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030A7F).withValues(alpha: 0.22),
              offset: const Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: titleColor ?? textColor,
                fontSize: 18,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            footer,
          ],
        ),
      ),
    );
  }
}
