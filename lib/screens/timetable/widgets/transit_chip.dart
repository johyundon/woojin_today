import 'package:flutter/material.dart';

import '../timetable_colors.dart';

/// 연강 사이 경계에 뜨는 작은 "이동하기" 칩. 탭하면 두 건물 사이 캠퍼스
/// 지도로 이동한다.
class TransitChip extends StatelessWidget {
  const TransitChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: TimetableColors.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_walk, color: Colors.white, size: 12),
            SizedBox(width: 3),
            Text(
              '이동하기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
