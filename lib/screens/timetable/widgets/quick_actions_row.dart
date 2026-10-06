import 'package:flutter/material.dart';

import '../timetable_colors.dart';

/// 헤더 바로 아래 줄: "내 시간표 불러오기" 아웃라인 버튼 + "강의시간 알림" 토글.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    required this.loading,
    required this.onLoadMyTimetable,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
  });

  final bool loading;
  final VoidCallback onLoadMyTimetable;
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          onPressed: loading ? null : onLoadMyTimetable,
          style: OutlinedButton.styleFrom(
            foregroundColor: TimetableColors.accent,
            side: const BorderSide(color: TimetableColors.accent),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TimetableColors.accent,
                  ),
                )
              : const Text(
                  '내 시간표 불러오기',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
        ),
        const Spacer(),
        const Text(
          '강의시간 알림',
          style: TextStyle(color: TimetableColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 6),
        Switch(
          value: notificationsEnabled,
          onChanged: onNotificationsChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: TimetableColors.accent,
          inactiveThumbColor: TimetableColors.textSecondary,
          inactiveTrackColor: TimetableColors.surfaceElevated,
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
    );
  }
}
