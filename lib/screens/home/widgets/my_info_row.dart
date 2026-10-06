import 'package:flutter/material.dart';

import '../home_colors.dart';

/// "내 정보" 모달의 한 줄(라벨+값).
class MyInfoRow extends StatelessWidget {
  const MyInfoRow({
    required this.colors,
    required this.label,
    required this.value,
  });

  final HomeColors colors;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
