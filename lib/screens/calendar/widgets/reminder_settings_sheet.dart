import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';
import 'date_pick_sheet.dart';
import 'sheet_buttons.dart';
import 'sheet_header.dart';

/// 일정 알림 설정 창(종 버튼·상세 팝업의 "설정"에서 연다). 당일·1일 전·…·30일 전
/// 버튼을 눌러 켜고 끄거나, "날짜 직접 고르기"로 원하는 날을 골라 여러 개 받는다.
///
/// 고른 날짜는 "시작일 며칠 전"으로 바꿔 돌려준다. 저장하면 그 목록을, "알림 끄기"를
/// 누르면 빈 목록을, 닫거나 취소하면 null을 반환한다. 처음 여는(알림이 꺼진) 일정은
/// "당일"이 골라져 있다. 울리는 시각은 고정이다(종일 일정은 오전 9시, 시간이 있는
/// 일정은 그 시각).
Future<List<int>?> showReminderSettingsSheet(
  BuildContext context, {
  required CalendarEvent event,
  DateTime? today,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) =>
        _ReminderSettingsBody(event: event, today: today ?? DateTime.now()),
  );
}

/// 바로 누를 수 있는 "며칠 전" 버튼들.
const List<int> _presetDays = [0, 1, 3, 7, 14, 30];

class _ReminderSettingsBody extends StatefulWidget {
  const _ReminderSettingsBody({required this.event, required this.today});

  final CalendarEvent event;
  final DateTime today;

  @override
  State<_ReminderSettingsBody> createState() => _ReminderSettingsBodyState();
}

class _ReminderSettingsBodyState extends State<_ReminderSettingsBody> {
  late final Set<int> _days = widget.event.hasReminder
      ? widget.event.reminderDaysBefore.toSet()
      : {0};
  String? _error;

  DateTime get _start {
    final s = widget.event.startDate;
    return DateTime(s.year, s.month, s.day);
  }

  DateTime get _todayDate =>
      DateTime(widget.today.year, widget.today.month, widget.today.day);

  /// 시작일 [d]일 전 날짜.
  DateTime _dateOf(int d) =>
      DateTime(_start.year, _start.month, _start.day - d);

  bool _isPast(int d) => _dateOf(d).isBefore(_todayDate);

  /// 여러 날 일정의 0일 전은 "시작일"로 쓴다(상세 팝업 문구와 같게).
  String _label(int d) => widget.event.isMultiDay && d == 0
      ? '시작일'
      : reminderDaysLabel(d, allDay: widget.event.isAllDay);

  String _dateText(int d) {
    final date = _dateOf(d);
    return '${date.month}.${date.day} (${weekdayLabelsSunFirst[date.weekday % 7]})';
  }

  String get _anchorText {
    final t = widget.event.startTime;
    if (t == null) return '오전 9시';
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  void _toggle(int d) => setState(() {
    _error = null;
    if (!_days.remove(d)) _days.add(d);
  });

  Future<void> _pickDate() async {
    final latest = _start;
    final picked = await showDatePickSheet(
      context,
      title: '알림 받을 날짜',
      initialDate: _todayDate.isAfter(latest) ? latest : _todayDate,
      today: widget.today,
    );
    if (picked == null || !mounted) return;
    final d = _start
        .difference(DateTime(picked.year, picked.month, picked.day))
        .inDays;
    setState(() {
      if (d < 0) {
        _error = '일정 시작일 이후 날짜는 고를 수 없어요';
      } else if (_isPast(d)) {
        _error = '이미 지난 날짜예요';
      } else if (d > maxReminderDaysBefore) {
        _error = '시작일 $maxReminderDaysBefore일 전까지만 고를 수 있어요';
      } else {
        _error = null;
        _days.add(d);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final event = widget.event;
    // 버튼에 없는 날(직접 고른 날)도 같은 칸에 이어서 보여준다.
    final custom = _days.where((d) => !_presetDays.contains(d)).toList()
      ..sort((a, b) => b.compareTo(a));
    final cells = [..._presetDays, ...custom];
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + media.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: SheetGrabber()),
          const SizedBox(height: 20),
          const Text(
            '알림 설정',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '언제 알림을 받을지 골라 주세요 · $_anchorText에 울려요',
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 8.0;
              final width = (constraints.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final d in cells)
                    SizedBox(
                      width: width,
                      child: _DayOption(
                        label: _label(d),
                        date: _dateText(d),
                        selected: _days.contains(d),
                        disabled: _isPast(d) && !_days.contains(d),
                        onTap: () => _toggle(d),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: _pickDate,
            pressedScale: 0.97,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: AppColors.blueText,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '날짜 직접 고르기',
                    style: TextStyle(
                      color: AppColors.blueText,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(
                color: CalendarColors.deleteRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (event.hasReminder) ...[
            const SizedBox(height: 10),
            Center(
              child: Pressable(
                onTap: () => Navigator.of(context).pop(const <int>[]),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '알림 끄기',
                    style: TextStyle(
                      color: CalendarColors.deleteRed,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SheetButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onSave: _days.isEmpty
                ? null
                : () =>
                      Navigator.of(context)
                          .pop(_days.toList()..sort((a, b) => b.compareTo(a))),
          ),
        ],
      ),
    );
  }
}

/// "2주 전 / 11.6 (금)" 칸 하나. 누르면 켜고 끈다. 이미 지난 날은 흐리게 막는다.
class _DayOption extends StatelessWidget {
  const _DayOption({
    required this.label,
    required this.date,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final String date;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : disabled
        ? AppColors.textMuted
        : AppColors.textStrong;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      child: Pressable(
        onTap: disabled ? null : onTap,
        pressedScale: 0.95,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.inkNavy : AppColors.fill,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                disabled ? '지난 날짜' : date,
                style: TextStyle(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.75)
                      : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
