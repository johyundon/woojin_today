import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 체크박스 + 라벨 (+ 선택적 "보기" 링크) 한 줄.
/// 약관 동의 화면에서 "전체 동의합니다", "이용약관 동의", "개인정보 처리방침 동의"
/// 세 줄에 공통으로 재사용한다.
class AppCheckboxRow extends StatelessWidget {
  const AppCheckboxRow({
    super.key,
    required this.label,
    required this.checked,
    required this.onChanged,
    this.labelStyle,
    this.onViewPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final TextStyle? labelStyle;
  final VoidCallback? onViewPressed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            _CheckboxBox(checked: checked),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style:
                    labelStyle ??
                    const TextStyle(
                      color: AppColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (onViewPressed != null)
              GestureDetector(
                onTap: onViewPressed,
                child: const Text(
                  '보기',
                  style: TextStyle(
                    color: AppColors.cobalt,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.cobalt,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxBox extends StatelessWidget {
  const _CheckboxBox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: checked ? AppColors.cobalt : Colors.white,
        border: Border.all(
          color: checked ? AppColors.cobalt : const Color(0xFFCFCBC3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: checked
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : null,
    );
  }
}
