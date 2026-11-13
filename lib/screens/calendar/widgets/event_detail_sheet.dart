import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';
import 'sheet_header.dart';

/// 상세 팝업에서 사용자가 고른 동작.
enum EventDetailAction { edit, delete }

/// 일정 카드를 눌렀을 때 아래에서 올라오는 상세 팝업(v7). 날짜/시간/
/// 장소/알림을 보여주고, 알림 줄의 "설정" 버튼으로 알림 설정 창(며칠 전 알림)을
/// 연다. 직접 만든 일정이면
/// "삭제하기"/"수정하기" 버튼이 나오고, 누르면 그 동작을 반환하며 닫힌다.
/// 학사일정은 수정·삭제할 수 없다는 안내와 "닫기" 버튼만 나온다.
Future<EventDetailAction?> showEventDetailSheet(
  BuildContext context, {
  required CalendarEvent event,
  required Future<void> Function() onReminderTap,
}) {
  return showModalBottomSheet<EventDetailAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) =>
        _EventDetailBody(event: event, onReminderTap: onReminderTap),
  );
}

class _EventDetailBody extends StatefulWidget {
  const _EventDetailBody({required this.event, required this.onReminderTap});

  final CalendarEvent event;
  final Future<void> Function() onReminderTap;

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
    return end == null ? _time(start) : '${_time(start)} – ${_time(end)}';
  }

  /// 알림 줄 문구. 길어지지 않게 고른 날이 두 개까지면 "2주 전·당일"처럼 잇고,
  /// 더 많으면 가장 이른 것만 "2주 전 외 2개"로 줄인다(사용자 요청, 2026-11-13).
  /// 여러 날 일정의 "당일"은 "시작일"로 쓴다.
  String get _reminderText {
    final days = event.reminderDaysBefore;
    if (days.isEmpty) return '알림 없음';
    String label(int d) => event.isMultiDay && d == 0
        ? '시작일'
        : reminderDaysLabel(d, allDay: event.isAllDay);
    if (days.length <= 2) return days.map(label).join('·');
    return '${label(days.first)} 외 ${days.length - 1}개';
  }

  Future<void> _openSettings() async {
    await widget.onReminderTap();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final editable = event.isUserEvent;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 38),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SheetGrabber()),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.label,
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              event.title,
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.63,
              ),
            ),
            _InfoRow(
              icon: Icons.calendar_today_rounded,
              label: '날짜',
              value: _dateText,
            ),
            // 시간이 없는 일정은 "시간: 종일" 줄을 빼서 보여준다(사용자 요청, 2026-10-31).
            if (!event.isAllDay)
              _InfoRow(
                icon: Icons.watch_later_rounded,
                label: '시간',
                value: _timeText,
              ),
            if (event.location != null && event.location!.isNotEmpty)
              _InfoRow(
                icon: Icons.location_on_rounded,
                label: '장소',
                value: event.location!,
              ),
            _InfoRow(
              icon: Icons.notifications_active_rounded,
              label: '알림',
              value: _reminderText,
              trailing: Pressable(
                onTap: _openSettings,
                pressedScale: 0.93,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    '설정',
                    style: TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            if (!editable) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 15,
                      color: AppColors.textBody,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '학교에서 등록한 일정은 수정, 삭제할 수 없어요',
                        style: TextStyle(
                          color: AppColors.textBody,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: editable ? 20 : 16),
            if (editable)
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      icon: Icons.delete_rounded,
                      label: '삭제하기',
                      background: CalendarColors.deleteSoft,
                      foreground: CalendarColors.deleteRed,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      onPressed: () =>
                          Navigator.of(context).pop(EventDetailAction.delete),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SheetButton(
                      icon: Icons.edit_rounded,
                      label: '수정하기',
                      background: AppColors.blue,
                      foreground: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      onPressed: () =>
                          Navigator.of(context).pop(EventDetailAction.edit),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: _SheetButton(
                  label: '닫기',
                  background: AppColors.blue,
                  foreground: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 상세 팝업 아래쪽 버튼(높이 52, 모서리 16).
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.fontSize,
    required this.fontWeight,
    required this.onPressed,
  });

  final IconData? icon;
  final String label;
  final Color background;
  final Color foreground;
  final double fontSize;
  final FontWeight fontWeight;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
    final style = ElevatedButton.styleFrom(
      backgroundColor: background,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    return SizedBox(
      height: 52,
      child: Pressable.effect(
        child: icon == null
            ? ElevatedButton(onPressed: onPressed, style: style, child: text)
            : ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 17, color: foreground),
                label: text,
                style: style,
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
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.blueText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}
