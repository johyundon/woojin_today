import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/calendar_event.dart';

/// 선택한 날짜의 일정 카드 하나. 점 색 + 라벨 + 제목 + (알림 켜졌으면)
/// "HH:mm 알림" 텍스트 + 우측 알림 토글 (shot3/shot5 참고).
///
/// "HH:mm 알림" 텍스트를 누르면 이미 켜진 알림의 시간을 다시 바꿀 수 있다
/// (토글은 켜짐/꺼짐만 바꿔서, 시간만 바꾸고 싶을 때 껐다 켜야 하는 불편이
/// 있었다).
class EventCard extends StatelessWidget {
  const EventCard({
    required this.event,
    required this.onReminderToggled,
    required this.onEditReminderTime,
    super.key,
  });

  final CalendarEvent event;

  /// 토글이 바뀔 때마다 호출된다 (true = 켜려는 시도, false = 끄기).
  final ValueChanged<bool> onReminderToggled;

  /// 켜져 있는 알림의 "HH:mm 알림" 텍스트를 눌렀을 때 호출된다.
  final VoidCallback onEditReminderTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (event.hasReminder) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onEditReminderTime,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_formatTime(event.reminderTime!)} 알림',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.edit,
                          size: 12,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: event.hasReminder,
            onChanged: onReminderToggled,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accent,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.disabledButton,
          ),
        ],
      ),
    );
  }
}

String _formatTime(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
