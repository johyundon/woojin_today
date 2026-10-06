import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 약관 동의 완료 후 이동할 다음 화면이 아직 없어서 임시로 띄우는 placeholder.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          '다음 화면 준비중',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
      ),
    );
  }
}
