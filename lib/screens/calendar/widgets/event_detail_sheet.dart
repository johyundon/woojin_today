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
/// 장소/알림을 보여주고, 알림은 여기서 바로 켜고 끌 수 있다. 직접 만든 일정이면
/// "삭제하기"/"수정하기" 버튼이 나오고, 누르면 그 동작을 반환하며 닫힌다.
/// 학사일정은 수정·삭제할 수 없다는 안내와 "닫기" 버튼만 나온다.
Future<EventDetailAction?> showEventDetailSheet(
  BuildContext context, {
  required CalendarEvent event,
  required Future<void> Function(bool turnOn) onReminderToggled,
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
    return end == null ? _time(start) : '${_time(start)} – ${_time(end)}';
  }

  /// 알림 줄 문구. 시간 정보가 없는 종일 일정(학사일정 등)의 "정각" 알림은 오전 9시에
  /// 울리므로 "정각"이라고만 쓰지 않고 언제 울리는지 그대로 보여준다. 여러 날에 걸친
  /// 학사일정은 시작일과 마감일(3일 이상이면 마감 전날도) 울린다.
  String get _reminderText {
    final offset = event.reminderOffset;
    if (offset == null) return '알림 없음';
    if (event.isAllDay && offset == ReminderOffset.atStart) {
      if (!event.isMultiDay) return '당일 오전 9시';
      if (event.isUserEvent) return '시작일 오전 9시';
      final hasDayBefore = event.reminders.any(
        (r) => r.kind == ReminderKind.dayBeforeEnd,
      );
      return hasDayBefore ? '시작일·마감 전날·마감일 오전 9시' : '시작일·마감일 오전 9시';
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
              trailing: SizedBox(
                width: 48,
                height: 28,
                child: FittedBox(
                  child: Switch(
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: event.hasReminder,
                    onChanged: _toggle,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.inkNavy,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: AppColors.checkLine,
                    trackOutlineColor: const WidgetStatePropertyAll(
                      Colors.transparent,
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
