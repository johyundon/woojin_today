import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import 'sheet_buttons.dart';
import 'time_wheel_picker.dart';

/// "+" 버튼으로 새 일정을 추가할 때 뜨는 바텀시트(shot6/shot7 참고).
/// 제목이 비어 있으면 저장 버튼이 비활성화된다. 저장하면 (제목, 알림 시간)을
/// 반환하고, 취소하면 null을 반환한다.
Future<(String title, TimeOfDay time)?> showAddScheduleSheet(
  BuildContext context,
) {
  return showModalBottomSheet<(String, TimeOfDay)>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => const _AddScheduleSheetBody(),
  );
}

class _AddScheduleSheetBody extends StatefulWidget {
  const _AddScheduleSheetBody();

  @override
  State<_AddScheduleSheetBody> createState() => _AddScheduleSheetBodyState();
}

class _AddScheduleSheetBodyState extends State<_AddScheduleSheetBody> {
  final _titleController = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _titleController.text.trim();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '제목',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: '일정 제목',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.disabledButton,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '알림받을 시간을 설정하세요',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TimeWheelPicker(
            initialTime: _time,
            onChanged: (time) => _time = time,
          ),
          const SizedBox(height: 20),
          SheetButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onSave: title.isEmpty
                ? null
                : () => Navigator.of(context).pop((title, _time)),
          ),
        ],
      ),
    );
  }
}
