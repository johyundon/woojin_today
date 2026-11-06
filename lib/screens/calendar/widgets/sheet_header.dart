import 'package:flutter/material.dart';

import 'calendar_colors.dart';

/// 캘린더 바텀시트들이 공유하는 위쪽 손잡이 막대(v7).
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 5,
      decoration: BoxDecoration(
        color: CalendarColors.grabber,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
