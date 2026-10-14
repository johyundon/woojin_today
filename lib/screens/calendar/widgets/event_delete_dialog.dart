import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

const Color _deleteRed = Color(0xFFE5484D);

/// "일정을 삭제할까요?" 확인창. 삭제하면 true, 취소하면(바깥을 눌러 닫아도)
/// false를 반환한다.
Future<bool> showEventDeleteDialog(
  BuildContext context, {
  required String eventTitle,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFFDECEC),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete, color: _deleteRed),
            ),
            const SizedBox(height: 14),
            const Text(
              '일정을 삭제할까요?',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "'$eventTitle' 일정이 삭제되고\n알림도 함께 사라져요",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B6B70),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F1F5),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deleteRed,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        '삭제',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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
