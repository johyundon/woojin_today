import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';

/// "시간표 저장" 팝업(v7 디자인 27). 이름을 입력받아 확인 시 그 이름을
/// [Navigator.pop]으로 돌려준다(취소/바깥 탭이면 null).
class SaveTimetableDialog extends StatefulWidget {
  const SaveTimetableDialog({super.key});

  @override
  State<SaveTimetableDialog> createState() => _SaveTimetableDialogState();
}

class _SaveTimetableDialogState extends State<SaveTimetableDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '시간표 저장',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.54,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              cursorColor: AppColors.blue,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: '시간표 이름',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: AppColors.fill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.blue, width: 2),
                ),
              ),
              onSubmitted: (_) => _confirm(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _button(
                    label: '취소',
                    background: AppColors.fill,
                    textStyle: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _button(
                    label: '확인',
                    background: AppColors.blue,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    onTap: _confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required Color background,
    required TextStyle textStyle,
    required VoidCallback onTap,
  }) {
    return Pressable(
      pressedScale: 0.96,
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }
}
