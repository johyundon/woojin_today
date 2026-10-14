import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 바텀시트 하단의 "취소"(연한 회색) / "저장"(파랑) 알약 버튼 한 쌍.
/// [onSave]가 null이면 저장 버튼이 비활성화(연한 파랑)된다.
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
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onCancel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F1F5),
                foregroundColor: AppColors.ink,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                '취소',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cobalt,
                disabledBackgroundColor: const Color(0xFFC9D3F2),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
              ),
              child: const Text(
                '저장',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
