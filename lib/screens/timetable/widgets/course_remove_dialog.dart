import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../timetable_colors.dart';

/// 시간표 블록의 "×"를 눌렀을 때 뜨는 "삭제하시겠습니까?" 확인창(사용자가 보낸
/// 시안 캡처, 2026-11-16). 연분홍 원 안의 빨간 "!", 제목, 아래 "취소"·"삭제"
/// 두 버튼. 삭제하면 true, 취소하거나 바깥을 눌러 닫으면 false.
Future<bool> showCourseRemoveDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: TimetableColors.barrier,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _RemoveDialogColors.alertSoft,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '!',
                style: TextStyle(
                  color: _RemoveDialogColors.alertRed,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '삭제하시겠습니까?',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _RemoveDialogButton(
                    key: const ValueKey('course-remove-cancel'),
                    label: '취소',
                    background: _RemoveDialogColors.cancelFill,
                    foreground: _RemoveDialogColors.cancelText,
                    onTap: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RemoveDialogButton(
                    key: const ValueKey('course-remove-confirm'),
                    label: '삭제',
                    background: _RemoveDialogColors.alertRed,
                    foreground: Colors.white,
                    onTap: () => Navigator.of(dialogContext).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}

/// 캡처에서 눈으로 옮긴 색.
abstract final class _RemoveDialogColors {
  static const Color alertRed = Color(0xFFEC615A);
  static const Color alertSoft = Color(0xFFFCEAE9);
  static const Color cancelFill = Color(0xFFEAD9DD);
  static const Color cancelText = Color(0xFF6B5560);
}

class _RemoveDialogButton extends StatelessWidget {
  const _RemoveDialogButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: foreground,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
