import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable.dart';

/// 화면 하단에 고정되는 풀폭 CTA 버튼.
/// enabled 여부에 따라 코발트(활성) / 연한 코발트(비활성) 스타일로 전환된다.
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
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(31),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.cobalt.withValues(alpha: 0.4),
                    offset: const Offset(0, 12),
                    blurRadius: 26,
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.cobalt,
            disabledBackgroundColor: AppColors.cobalt.withValues(alpha: 0.35),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
