import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 바텀시트 하단의 "취소"(아웃라인) / "저장"(오렌지) 버튼 한 쌍.
/// [onSave]가 null이면 저장 버튼이 비활성화(회색)된다(shot6 참고).
class SheetButtonRow extends StatelessWidget {
  const SheetButtonRow({
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final saveEnabled = onSave != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '취소',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: saveEnabled
                  ? AppColors.accent
                  : AppColors.disabledButton,
              foregroundColor: saveEnabled
                  ? AppColors.textPrimary
                  : AppColors.disabledButtonText,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              '저장',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
