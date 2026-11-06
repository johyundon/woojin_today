import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import 'calendar_colors.dart';

/// "일정을 삭제할까요?" 확인창(v7). 삭제하면 true, 취소하면(바깥을 눌러 닫아도)
/// false를 반환한다.
Future<bool> showEventDeleteDialog(
  BuildContext context, {
  required String eventTitle,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: CalendarColors.barrier,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: CalendarColors.deleteSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_rounded,
                size: 22,
                color: CalendarColors.deleteRed,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '일정을 삭제할까요?',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.51,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "'$eventTitle' 일정이 삭제되고\n알림도 함께 사라져요",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: '취소',
                    background: AppColors.fill,
                    foreground: AppColors.textStrong,
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DialogButton(
                    label: '삭제',
                    background: CalendarColors.deleteRed,
                    foreground: Colors.white,
                    onPressed: () => Navigator.of(dialogContext).pop(true),
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

/// 확인창 아래쪽 버튼(높이 52, 모서리 16).
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Pressable.effect(
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
