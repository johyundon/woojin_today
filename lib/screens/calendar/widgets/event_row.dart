import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';
import 'ringing_bell.dart';

/// 선택한 날짜의 일정 한 줄 — 왼쪽 시간(시작 시간과 끝 시간. 시간이 없는 일정은
/// 이 칸 없이 바로 막대부터), 일정 색 세로 막대, 라벨 칩/제목/장소(없으면 기간)가 든 카드, 오른쪽의
/// 둥근 사각 알림 종 버튼. 카드를 누르면 상세 팝업이 열리고, 종 버튼을 누르면 알림 설정
/// 창이 열린다(캘린더 화면이 처리).
class EventRow extends StatelessWidget {
  /// 카드 왼쪽 시간 칸(시작/끝 시간)을 보일지. 숨겨 둔 상태다.
  static const _showTimeColumn = false;

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
          // 시간이 없는 일정(학사일정 등)은 "종일" 글자와 그 칸을 빼서 카드를 왼쪽으로
          // 붙인다(사용자 요청, 2026-10-31). 시간이 있는 일정의 시간 칸도 지금은
          // 숨긴다(사용자 요청, 2026-11-14 — 코드는 남겨 둠, [_showTimeColumn]).
          if (_showTimeColumn && event.startTime != null) ...[
            SizedBox(
              width: 44,
              // 시작 시간은 위, 끝 시간은 아래 끝에 둔다(v7).
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(event.startTime!),
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (event.endTime != null)
                      Text(
                        _formatTime(event.endTime!),
                        style: const TextStyle(
                          color: AppColors.textSub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 5,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: Pressable(
              onTap: onTap,
              pressedOpacity: 0.75,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 13, 12, 13),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event.label,
                              style: const TextStyle(
                                color: AppColors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textStrong,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitle,
                            style: const TextStyle(
                              color: AppColors.textSub,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 알림 켜짐: 남색 칸 + 흰 종 / 꺼짐: 흰 칸(테두리) + 회색 종.
                    Pressable(
                      onTap: () => onReminderToggled(!event.hasReminder),
                      pressedScale: 0.88,
                      haptic: HapticFeedback.lightImpact,
                      // 손을 떼면 살짝 커졌다가 제자리로 튕기듯 돌아온다.
                      releaseCurve: Curves.easeOutBack,
                      releaseDuration: const Duration(milliseconds: 260),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: event.hasReminder
                              ? AppColors.inkNavy
                              : Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          border: event.hasReminder
                              ? null
                              : Border.all(color: CalendarColors.bellOffLine),
                        ),
                        child: Center(
                          child: RingingBell(
                            active: event.hasReminder,
                            size: 16,
                            activeColor: Colors.white,
                            inactiveColor: CalendarColors.bellOffIcon,
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
