import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import 'calendar_colors.dart';
import 'ringing_bell.dart';

/// 시간 정보가 없는 일정(학사일정 등)에 알림을 걸었을 때 띄우는 안내 팝업(v7).
/// 알림이 언제 울리는지([dates] 각각의 오전 9시)를 알려주고 "확인"으로
/// 닫는다. 날짜가 둘이면 "10월 14일, 15일 오전 9시에"처럼 함께 보여준다.
Future<void> showReminderSetDialog(
  BuildContext context, {
  required List<DateTime> dates,
}) {
  // 첫 날짜는 "10월 14일", 뒤따르는 날짜는 같은 달이면 "15일"만 붙인다.
  final label = StringBuffer();
  for (var i = 0; i < dates.length; i++) {
    final d = dates[i];
    if (i > 0) label.write(', ');
    final sameMonth = i > 0 && d.month == dates[i - 1].month;
    label.write(sameMonth ? '${d.day}일' : '${d.month}월 ${d.day}일');
  }
  return showDialog<void>(
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
                color: AppColors.blueSoft,
                shape: BoxShape.circle,
              ),
              // 팝업이 뜨면서 종이 한 번 울린다.
              child: const Center(
                child: RingingBell(
                  active: true,
                  playOnStart: true,
                  size: 26,
                  activeColor: AppColors.blue,
                  inactiveColor: AppColors.blue,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '알림이 설정됐어요',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.51,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$label 오전 9시에\n알림이 울립니다',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Pressable.effect(
                pressedScale: 0.97,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
            ),
          ],
        ),
      ),
    ),
  );
}
