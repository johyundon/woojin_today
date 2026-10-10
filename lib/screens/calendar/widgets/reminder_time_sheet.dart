import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'sheet_buttons.dart';
import 'time_wheel_picker.dart';

/// 일정 카드의 알림 토글을 켤 때 뜨는 "알림받을 시간을 설정하세요" 바텀시트
/// (shot4 참고). 저장하면 선택된 [TimeOfDay]를, 취소하면 null을 반환한다.
Future<TimeOfDay?> showReminderTimeSheet(
  BuildContext context, {
  required String eventTitle,
  TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0),
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      var selectedTime = initialTime;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eventTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '알림받을 시간을 설정하세요',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TimeWheelPicker(
              initialTime: initialTime,
              onChanged: (time) => selectedTime = time,
            ),
            const SizedBox(height: 20),
            SheetButtonRow(
              onCancel: () => Navigator.of(sheetContext).pop(),
              onSave: () => Navigator.of(sheetContext).pop(selectedTime),
            ),
          ],
        ),
      );
    },
  );
}
