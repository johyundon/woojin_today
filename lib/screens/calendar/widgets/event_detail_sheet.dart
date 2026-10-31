import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'sheet_header.dart';

const Color _mutedText = Color(0xFF6B6B70);

/// 상세 팝업에서 사용자가 고른 동작.
enum EventDetailAction { edit, delete }

/// 일정 카드를 눌렀을 때 아래에서 올라오는 상세 팝업(v4 스타일). 날짜/시간/
/// 장소/알림을 보여주고, 알림은 여기서 바로 켜고 끌 수 있다. 직접 만든 일정이면
/// "삭제하기"/"수정하기" 버튼이 나오고, 누르면 그 동작을 반환하며 닫힌다.
/// 학사일정은 버튼 없이 보기만 된다.
Future<EventDetailAction?> showEventDetailSheet(
  BuildContext context, {
  required CalendarEvent event,
  required Future<void> Function(bool turnOn) onReminderToggled,
}) {
  return showModalBottomSheet<EventDetailAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) =>
        _EventDetailBody(event: event, onReminderToggled: onReminderToggled),
  );
}

class _EventDetailBody extends StatefulWidget {
  const _EventDetailBody({
    required this.event,
    required this.onReminderToggled,
  });

  final CalendarEvent event;
  final Future<void> Function(bool turnOn) onReminderToggled;

  @override
  State<_EventDetailBody> createState() => _EventDetailBodyState();
}

class _EventDetailBodyState extends State<_EventDetailBody> {
  CalendarEvent get event => widget.event;

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _time(TimeOfDay t) => '${_two(t.hour)}:${_two(t.minute)}';

  String get _dateText {
    String md(DateTime d) => '${d.month}월 ${d.day}일';
    final s = event.startDate;
    final e = event.endDate;
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    return sameDay
        ? '${md(s)} ${weekdayLabelsSunFirst[s.weekday % 7]}요일'
        : '${md(s)} ~ ${md(e)}';
  }

  String get _timeText {
    final start = event.startTime;
    if (start == null) return '종일';
    final end = event.endTime;
    return end == null ? _time(start) : '${_time(start)} ~ ${_time(end)}';
  }

  /// 알림 줄 문구. 시간 정보가 없는 종일 일정(학사일정 등)의 "정각" 알림은 오전 9시에
  /// 울리므로 "정각"이라고만 쓰지 않고 언제 울리는지 그대로 보여준다. 여러 날에 걸친
  /// 학사일정은 시작일과 마감일, 두 번 울린다.
  String get _reminderText {
    final offset = event.reminderOffset;
    if (offset == null) return '알림 없음';
    if (event.isAllDay && offset == ReminderOffset.atStart) {
      if (!event.isMultiDay) return '당일 오전 9시';
      return event.isUserEvent ? '시작일 오전 9시' : '시작일·마감일 오전 9시';
    }
    return offset.label;
  }

  Future<void> _toggle(bool turnOn) async {
    await widget.onReminderToggled(turnOn);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final editable = event.isUserEvent;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetGrabber()),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCE6FB),
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
            const SizedBox(height: 10),
            Text(
              event.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _InfoRow(icon: Icons.calendar_today, label: '날짜', value: _dateText),
            // 시간이 없는 일정은 "시간: 종일" 줄을 빼서 보여준다(사용자 요청, 2026-10-31).
            if (!event.isAllDay)
              _InfoRow(icon: Icons.access_time, label: '시간', value: _timeText),
            if (event.location != null && event.location!.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on,
                label: '장소',
                value: event.location!,
              ),
            _InfoRow(
              icon: Icons.notifications_active,
              label: '알림',
              value: _reminderText,
              trailing: Switch(
                value: event.hasReminder,
                onChanged: _toggle,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.cobalt,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD8D8DE),
                trackOutlineColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
              ),
            ),
            if (editable) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: Pressable.effect(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.of(context)
                                  .pop(EventDetailAction.delete),
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
                            color: Color(0xFFE5484D),
                          ),
                          label: const Text(
                            '삭제하기',
                            style: TextStyle(
                              color: Color(0xFFE5484D),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFDECEC),
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: Pressable.effect(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              Navigator.of(context).pop(EventDetailAction.edit),
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            '수정하기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cobalt,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCE6FB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.cobalt),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: _mutedText, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
