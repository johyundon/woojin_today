import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';
import 'date_pick_sheet.dart';
import 'sheet_buttons.dart';
import 'sheet_header.dart';

/// 일정 알림 설정 창(종 버튼·상세 팝업의 "설정"에서 연다). 신입생도 바로 알아보게
/// "3일 전 · 11.17 (화)"처럼 한 줄씩 쌓은 목록에서 눌러 체크하고, 원하는 날은
/// "+ 날짜 추가"로 달력에서 골라 넣는다(사용자 결정, 2026-11-13).
///
/// 이미 지난 날은 목록에 보이지 않는다. 모두 해제하고 저장하면 알림이 꺼진다.
/// 저장하면 "시작일 며칠 전" 목록을, 닫거나 취소하면 null을 반환한다. 처음 여는
/// (알림이 꺼진) 일정은 "당일"이 체크돼 있다. 울리는 시각은 고정이다(종일 일정은
/// 오전 9시, 시간이 있는 일정은 그 시각).
Future<List<int>?> showReminderSettingsSheet(
  BuildContext context, {
  required CalendarEvent event,
  DateTime? now,
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
        _ReminderSettingsBody(event: event, now: now ?? DateTime.now()),
  );
}

/// 목록에 늘 나오는 "며칠 전" 줄들(지난 날은 빠진다).
const List<int> _presetDays = [0, 1, 3, 7, 14, 30];

class _ReminderSettingsBody extends StatefulWidget {
  const _ReminderSettingsBody({required this.event, required this.now});

  final CalendarEvent event;
  final DateTime now;

  @override
  State<_ReminderSettingsBody> createState() => _ReminderSettingsBodyState();
}

class _ReminderSettingsBodyState extends State<_ReminderSettingsBody> {
  /// 체크된 날. 지난 날은 목록에 안 보이지만, 이미 시작한 여러 날 학사일정은
  /// 시작일(0)을 들고 있어야 마감 알림이 걸리므로 여기서는 지우지 않는다([_result]).
  late final Set<int> _days = {
    ...(widget.event.hasReminder ? widget.event.reminderDaysBefore : [0]),
  };

  /// 직접 고른 날(목록 기본 줄에 없는 날). 체크를 풀어도 줄은 남겨 다시 켤 수 있다.
  late final Set<int> _custom = {
    for (final d in _days)
      if (!_presetDays.contains(d)) d,
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
    final t = widget.event.startTime ?? allDayReminderAnchor;
    return !DateTime(
      date.year,
      date.month,
      date.day,
      t.hour,
      t.minute,
    ).isAfter(widget.now);
  }

  /// 여러 날 일정의 0일 전은 "시작일"로 쓴다(상세 팝업 문구와 같게).
  String _label(int d) => widget.event.isMultiDay && d == 0
      ? '시작일'
      : reminderDaysLabel(d, allDay: widget.event.isAllDay);

  String _dateText(int d) {
    final date = _dateOf(d);
    return '${date.month}.${date.day} '
        '(${weekdayLabelsSunFirst[date.weekday % 7]})';
  }

  String get _anchorText {
    final t = widget.event.startTime;
    if (t == null) return '오전 9시';
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute == 0 ? '' : ' ${t.minute}분';
    return '${t.hour < 12 ? '오전' : '오후'} $hour시$minute';
  }

  void _toggle(int d) => setState(() {
    _error = null;
    if (!_days.remove(d)) _days.add(d);
  });

  Future<void> _pickDate() async {
    final picked = await showDatePickSheet(
      context,
      title: '알림 받을 날짜',
      initialDate: _today.isAfter(_start) ? _start : _today,
      today: widget.now,
    );
    if (picked == null || !mounted) return;
    final d = _start
        .difference(DateTime(picked.year, picked.month, picked.day))
        .inDays;
    setState(() {
      if (d < 0) {
        _error = '일정 시작일보다 뒤 날짜는 고를 수 없어요';
      } else if (_isPast(d)) {
        _error = '이미 지난 날짜예요';
      } else if (d > maxReminderDaysBefore) {
        _error = '시작일 $maxReminderDaysBefore일 전까지만 고를 수 있어요';
      } else {
        _error = null;
        _days.add(d);
        if (!_presetDays.contains(d)) _custom.add(d);
      }
    });
  }

  /// 저장할 목록. 보이는 줄에서 고른 날만 남긴다(지난 날은 정리). 보이는 줄이
  /// 하나도 없으면(이미 시작한 일정) 원래 값을 그대로 둬서 마감 알림이 걸리게 한다.
  List<int> _result(List<int> rows) {
    final picked = rows.isEmpty ? _days : _days.where(rows.contains);
    return picked.toList()..sort((a, b) => b.compareTo(a));
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // 가까운 날부터: 시작일 → 1일 전 → … 직접 고른 날도 날짜 순서대로 섞는다.
    final rows = {..._presetDays, ..._custom}.where((d) => !_isPast(d)).toList()
      ..sort();
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
          Text(
            '여러 개 골라도 돼요 · 고른 날 $_anchorText에 울려요',
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.fill, width: 1.5),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Text(
                      widget.event.isMultiDay && !widget.event.isUserEvent
                          ? '이미 시작한 일정이라 마감 알림만 울려요'
                          : '알림을 걸 수 있는 날이 지났어요',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                for (final d in rows) ...[
                  _DayRow(
                    label: _label(d),
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
            onSave: () => Navigator.of(context).pop(_result(rows)),
          ),
        ],
      ),
    );
  }
}

/// "3일 전 · 11.17 (화)" 한 줄. 누르면 체크를 켜고 끈다. 직접 고른 날은
/// 오른쪽 ✕로 줄째 뺄 수 있다.
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
                width: 64,
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
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                      semanticLabel: '$label 빼기',
                    ),
                  ),
                ),
              const SizedBox(width: 6),
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
