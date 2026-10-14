import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// 알림을 걸려는 시각([attemptedAt])이 이미 지났을 때 띄우는 안내 팝업(v4
/// 스타일). 어느 시각이 지났는지와 알림은 걸리지 않았다는 것, 어떻게 하면 되는지를
/// 알려주고, "확인"으로 닫는다. 시각을 보여주는 건 "일정은 아직 안 지났는데 왜?"
/// 하는 헷갈림(예: "10분 전" 알림의 시각이 먼저 지난 경우)을 풀어주기 위해서다.
Future<void> showReminderPastDialog(
  BuildContext context, {
  required DateTime attemptedAt,
}) {
  String two(int n) => n.toString().padLeft(2, '0');
  final when =
      '${attemptedAt.month}월 ${attemptedAt.day}일 '
      '${two(attemptedAt.hour)}:${two(attemptedAt.minute)}';

  return showDialog<void>(
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
                color: Color(0xFFDCE6FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.alarm_off, color: AppColors.cobalt),
            ),
            const SizedBox(height: 14),
            const Text(
              '이미 지난 시간이에요',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '알림 시각($when)이 이미 지나서\n알림은 걸리지 않았어요. 일정 시간이나\n알림 시점을 바꿔보세요.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF6B6B70),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cobalt,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
