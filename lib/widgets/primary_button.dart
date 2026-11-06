import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable.dart';

/// 화면 하단에 고정되는 풀폭 CTA 버튼.
/// enabled 여부에 따라 파랑(활성) / 회색(비활성) 스타일로 전환된다(v7).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable.effect(
      enabled: enabled,
      pressedScale: 0.96,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled ? AppColors.cardShadow : null,
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            disabledBackgroundColor: AppColors.fillDisabled,
            foregroundColor: Colors.white,
            disabledForegroundColor: AppColors.textMuted,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
