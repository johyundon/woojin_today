import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../models/calendar_event.dart';
import 'ringing_bell.dart';

const Color _mutedText = Color(0xFF6B6B70);

/// 선택한 날짜의 일정 한 줄 — 왼쪽 시간(시작 시간과 끝 시간, 시간이 없으면
/// "종일"), 일정 색 세로 막대, 라벨 칩/제목/장소(없으면 기간)가 든 카드, 오른쪽의
/// 원형 알림 종 버튼. 카드를 누르면 상세 팝업이 열리고, 종 버튼으로는 알림을 바로
/// 켜고 끈다.
class EventRow extends StatelessWidget {
  const EventRow({
    required this.event,
    required this.onReminderToggled,
    required this.onTap,
    super.key,
  });

  final CalendarEvent event;

  /// 종 버튼을 눌렀을 때 호출된다(true = 켜려는 시도, false = 끄기).
  final ValueChanged<bool> onReminderToggled;

  /// 카드를 눌렀을 때(상세 팝업 열기).
  final VoidCallback onTap;

  String get _periodText {
    String md(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    final sameDay =
        event.startDate.year == event.endDate.year &&
        event.startDate.month == event.endDate.month &&
        event.startDate.day == event.endDate.day;
    return sameDay
        ? md(event.startDate)
        : '${md(event.startDate)} ~ ${md(event.endDate)}';
  }

  /// 장소가 있으면 장소, 없으면 기간.
  String get _subtitle {
    final location = event.location;
    return location == null || location.isEmpty ? _periodText : location;
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            // 카드 높이의 세로 가운데, 칸의 가로 가운데에 놓는다.
            child: Center(
              child: event.startTime == null
                  ? const Text(
                      '종일',
                      style: TextStyle(
                        color: _mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(event.startTime!),
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (event.endTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(event.endTime!),
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          Container(
            width: 4,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              event.label,
                              style: const TextStyle(
                                color: AppColors.cobalt,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              color: _mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 알림 켜짐: 파란 원 + 흰 종 / 꺼짐: 흰 원 + 회색 종.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onReminderToggled(!event.hasReminder),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: event.hasReminder
                              ? AppColors.cobalt
                              : Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: RingingBell(
                            active: event.hasReminder,
                            size: 20,
                            activeColor: Colors.white,
                            inactiveColor: const Color(0xFF9A9A9E),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
