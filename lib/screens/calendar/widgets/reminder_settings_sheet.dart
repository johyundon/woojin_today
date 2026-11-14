import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';
import 'date_pick_sheet.dart';
import 'sheet_buttons.dart';
import 'sheet_header.dart';
import 'time_pick_sheet.dart';

/// 일정 알림 설정 창(종 버튼·상세 팝업의 "설정"에서 연다). 신입생도 바로 알아보게
/// "3일 전 · 11.17 (화)"처럼 한 줄씩 쌓은 목록에서 눌러 체크하고, 원하는 날은
/// "+ 날짜 추가"로 달력에서 골라 넣는다(사용자 결정, 2026-11-13).
///
/// 위쪽 "알림 시간" 줄에서 울리는 시각을 고른다(고른 날 모두 같은 시각, 처음엔
/// 오전 9시)(사용자 요청, 2026-11-14).
///
/// 이미 지난 날은 목록에 보이지 않는다. 모두 해제하고 저장하면 알림이 꺼진다.
/// 저장하면 "시작일 며칠 전" 목록과 알림 시각(기본 시각이면 null)을, 닫거나
/// 취소하면 null을 반환한다. 처음 여는(알림이 꺼진) 일정은 "당일"이 체크돼 있다.
Future<({List<int> days, TimeOfDay? time})?> showReminderSettingsSheet(
  BuildContext context, {
  required CalendarEvent event,
  DateTime? now,
}) {
  return showModalBottomSheet<({List<int> days, TimeOfDay? time})>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) =>
        _ReminderSettingsBody(event: event, now: now ?? DateTime.now()),
  );
}

/// 한 일정에 받을 수 있는 알림 수. iPhone은 앱 하나당 예약 알림을 64개까지만
/// 보관해서, 한 일정이 너무 많이 차지하지 않게 막는다.
const int _maxDays = 14;

class _ReminderSettingsBody extends StatefulWidget {
  const _ReminderSettingsBody({required this.event, required this.now});

  final CalendarEvent event;
  final DateTime now;

  @override
  State<_ReminderSettingsBody> createState() => _ReminderSettingsBodyState();
}

class _ReminderSettingsBodyState extends State<_ReminderSettingsBody> {
  /// 알림이 울리는 시각.
  late TimeOfDay _time = widget.event.effectiveReminderTime;

  /// 일정의 기본 알림 시각(이 시각이면 따로 저장하지 않는다).
  TimeOfDay get _defaultTime => allDayReminderAnchor;

  /// 체크된 날. 이미 지난 날은 목록에 없으므로 처음부터 뺀다.
  late final Set<int> _days = {
    for (final d
        in widget.event.hasReminder ? widget.event.reminderDaysBefore : [0])
      if (!_isPast(d)) d,
  };

  /// 직접 고른 날(목록 기본 줄에 없는 날). 체크를 풀어도 줄은 남겨 다시 켤 수 있다.
  late final Set<int> _custom = {
    for (final d in _days)
      if (!reminderPresetDays.contains(d)) d,
  };

  String? _error;

  DateTime get _start {
    final s = widget.event.startDate;
    return DateTime(s.year, s.month, s.day);
  }

  DateTime get _today =>
      DateTime(widget.now.year, widget.now.month, widget.now.day);

  /// 시작일 [d]일 전 날짜.
  DateTime _dateOf(int d) =>
      DateTime(_start.year, _start.month, _start.day - d);

  /// [d]일 전 알림 시각이 이미 지났으면 true(오늘이라도 울릴 시각이 지났으면 지난 것).
  bool _isPast(int d) {
    final date = _dateOf(d);
    final t = _time;
    return !DateTime(
      date.year,
      date.month,
      date.day,
      t.hour,
      t.minute,
    ).isAfter(widget.now);
  }

  /// 줄 오른쪽 날짜. 기본 줄은 "11.17 (화)", 직접 고른 날은 이름이 이미 날짜라
  /// 요일만 붙인다.
  String _dateText(int d) {
    final date = _dateOf(d);
    final weekday = weekdayLabelsSunFirst[date.weekday % 7];
    return reminderPresetDays.contains(d)
        ? '${date.month}.${date.day} ($weekday)'
        : '$weekday요일';
  }

  void _toggle(int d) => setState(() {
    _error = null;
    if (_days.remove(d)) return;
    if (_days.length >= _maxDays) {
      _error = '알림은 한 일정에 $_maxDays개까지 받을 수 있어요';
      return;
    }
    _days.add(d);
  });

  /// 달력에서 고를 수 있는 마지막 날 = 일정이 끝나는 날(여러 날 일정은 진행
  /// 중인 날도 고를 수 있다).
  DateTime get _end {
    final e = widget.event.endDate;
    return DateTime(e.year, e.month, e.day);
  }

  /// 달력에서 고를 수 있는 첫날 = 시작일 4주 전과 오늘 중 늦은 날.
  DateTime get _firstPickable {
    final earliest = _dateOf(maxReminderDaysBefore);
    return earliest.isAfter(_today) ? earliest : _today;
  }

  Future<void> _pickDate() async {
    final room = _maxDays - _days.length;
    if (room <= 0) {
      setState(() => _error = '알림은 한 일정에 $_maxDays개까지 받을 수 있어요');
      return;
    }
    final first = _firstPickable;
    final picked = await showMultiDatePickSheet(
      context,
      title: '알림 받을 날짜',
      initialMonth: _today.isBefore(first) ? first : _today,
      today: widget.now,
      firstDate: first,
      lastDate: _end,
      maxCount: room,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _error = null;
      for (final date in picked) {
        final d = _start
            .difference(DateTime(date.year, date.month, date.day))
            .inDays;
        if (_isPast(d)) {
          _error = '오늘 알림 시각이 이미 지난 날은 뺐어요';
          continue;
        }
        _days.add(d);
        if (!reminderPresetDays.contains(d)) _custom.add(d);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // 달력처럼 이른 날부터: 4주 전 → … → 시작일 → (진행 중인 날). 직접 고른
    // 날도 날짜 순서대로 섞는다(사용자 요청, 2026-11-14).
    final rows = {
      ...reminderPresetDays,
      ..._custom,
    }.where((d) => !_isPast(d)).toList()..sort((a, b) => b.compareTo(a));
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 20 + media.padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: SheetGrabber()),
          const SizedBox(height: 20),
          const Text(
            '언제 알려 드릴까요?',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '여러 개 골라도 돼요',
            style: TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _TimeRow(
            text: _timeText(_time),
            onTap: () async {
              final picked = await showTimePickSheet(
                context,
                title: '알림 시간',
                initialTime: _time,
              );
              if (picked == null || !mounted) return;
              setState(() {
                _time = picked;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.fill, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      '아래 날짜 추가로 알림 받을 날을 골라 주세요',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                for (final d in rows) ...[
                  _DayRow(
                    label: widget.event.reminderDayLabel(d),
                    date: _dateText(d),
                    selected: _days.contains(d),
                    onTap: () => _toggle(d),
                    onRemove: _custom.contains(d)
                        ? () => setState(() {
                            _custom.remove(d);
                            _days.remove(d);
                          })
                        : null,
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.fill),
                ],
                _AddDateRow(onTap: _pickDate),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(
                color: CalendarColors.deleteRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SheetButtonRow(
            onCancel: () => Navigator.of(context).pop(),
            onSave: () => Navigator.of(context).pop((
              // 시각을 바꿔 지나 버린 날은 뺀다.
              days: _days.where((d) => !_isPast(d)).toList()
                ..sort((a, b) => b.compareTo(a)),
              time: _time == _defaultTime ? null : _time,
            )),
          ),
        ],
      ),
    );
  }
}

/// "3일 전 · 11.17 (화)" 한 줄. 누르면 체크를 켜고 끈다. 직접 고른 날은
/// 오른쪽 휴지통으로 줄째 뺄 수 있다.
class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.label,
    required this.date,
    required this.selected,
    required this.onTap,
    this.onRemove,
  });

  final String label;
  final String date;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Container(
          color: selected ? AppColors.blueSoft : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.blueText : AppColors.textStrong,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  date,
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onRemove != null)
                Pressable.icon(
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CalendarColors.deleteSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.delete_rounded,
                      size: 18,
                      color: CalendarColors.deleteRed,
                      semanticLabel: '$label 빼기',
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              _CheckDot(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 체크 동그라미(켜짐: 파란 원 + 체크, 꺼짐: 회색 테두리).
class _CheckDot extends StatelessWidget {
  const _CheckDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColors.blue : Colors.white,
        border: Border.all(
          color: selected ? AppColors.blue : AppColors.textMuted,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}

/// 목록 맨 아래 "+ 날짜 추가" 줄. 달력 창을 연다.
class _AddDateRow extends StatelessWidget {
  const _AddDateRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: const Row(
          children: [
            Icon(Icons.add_rounded, size: 20, color: AppColors.blueText),
            SizedBox(width: 6),
            Text(
              '날짜 추가',
              style: TextStyle(
                color: AppColors.blueText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Spacer(),
            Text(
              '달력에서 고르기',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "오전 9:00"처럼 쓴다.
String _timeText(TimeOfDay t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '${t.hour < 12 ? '오전' : '오후'} $hour:$minute';
}

/// 목록 위 "알림 시간 · 오전 9:00 ›" 줄. 누르면 시·분 돌림판이 열린다.
class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 20,
              color: AppColors.blueText,
            ),
            const SizedBox(width: 8),
            const Text(
              '알림 시간',
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.blueText,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
