import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'sheet_buttons.dart';
import 'sheet_header.dart';
import 'time_wheel_picker.dart';

/// 시/분 휠로 시간을 고르는 바텀시트. 저장하면 고른 [TimeOfDay]를, 취소하면
/// null을 반환한다. 일정 수정 화면의 시작/끝 시간 칸에서 쓴다.
Future<TimeOfDay?> showTimePickSheet(
  BuildContext context, {
  required String title,
  required TimeOfDay initialTime,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      var selected = initialTime;
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.of(sheetContext).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetGrabber(),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            TimeWheelPicker(
              initialTime: initialTime,
              onChanged: (time) => selected = time,
            ),
            const SizedBox(height: 20),
            SheetButtonRow(
              onCancel: () => Navigator.of(sheetContext).pop(),
              onSave: () => Navigator.of(sheetContext).pop(selected),
            ),
          ],
        ),
      );
    },
  );
}
