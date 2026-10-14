import 'package:flutter/material.dart';

/// 캘린더 바텀시트들이 공유하는 위쪽 손잡이 막대.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE1E1E6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
