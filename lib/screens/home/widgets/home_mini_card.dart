import 'package:flutter/material.dart';

import '../../../widgets/pressable.dart';

/// 홈 화면 "다음 수업" 카드 아래 나란히 놓이는 작은 정사각 카드 (v7 디자인 12·13).
/// 흰 네모 아이콘 + 라벨 → 제목(두 줄까지) → 맨 아래 [footer] 순서.
/// 바탕·글자 색을 받아서 남색 "학과 등수" 카드와 연한 파랑 "오늘 점심" 카드에 함께 쓴다.
class HomeMiniCard extends StatelessWidget {
  const HomeMiniCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.title,
    required this.titleColor,
    required this.footer,
    required this.onTap,
    required this.backgroundColor,
    this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final String title;
  final Color titleColor;
  final Widget footer;
  final VoidCallback onTap;
  final Color backgroundColor;

  /// 테두리 색. null이면 테두리 없음.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final border = borderColor;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 171,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: border == null ? null : Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 17, color: iconColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 18,
                height: 1.4,
                letterSpacing: -0.54,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            footer,
          ],
        ),
      ),
    );
  }
}
