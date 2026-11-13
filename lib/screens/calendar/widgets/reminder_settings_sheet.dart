import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../models/calendar_event.dart';
import 'calendar_colors.dart';
import 'sheet_buttons.dart';
import 'sheet_header.dart';

/// 일정 알림 설정 창(종 버튼·상세 팝업의 알림 줄에서 연다). "며칠 전"을 숫자로
/// 넣어 여러 개 받을 수 있다(0 = 당일).
///
/// 저장하면 넣은 날짜 목록을, "알림 끄기"를 누르면 빈 목록을, 닫거나 취소하면
/// null을 반환한다. 처음 여는(알림이 꺼진) 일정은 "당일" 하나가 들어 있다.
/// 울리는 시각은 고정이다(종일 일정은 오전 9시, 시간이 있는 일정은 그 시각).
Future<List<int>?> showReminderSettingsSheet(
  BuildContext context, {
  required CalendarEvent event,
}) {
  return showModalBottomSheet<List<int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    barrierColor: CalendarColors.barrier,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (_) => _ReminderSettingsBody(event: event),
  );
}

class _ReminderSettingsBody extends StatefulWidget {
  const _ReminderSettingsBody({required this.event});

  final CalendarEvent event;

  @override
  State<_ReminderSettingsBody> createState() => _ReminderSettingsBodyState();
}

class _ReminderSettingsBodyState extends State<_ReminderSettingsBody> {
  late final Set<int> _days = widget.event.hasReminder
      ? widget.event.reminderDaysBefore.toSet()
      : {0};
  final _input = TextEditingController();
  String? _error;

  bool get _allDay => widget.event.isAllDay;

  List<int> get _sorted => _days.toList()..sort((a, b) => b.compareTo(a));

  /// 여러 날 일정의 0일 전은 "시작일"로 쓴다(상세 팝업 문구와 같게).
  String _label(int d) => widget.event.isMultiDay && d == 0
      ? '시작일'
      : reminderDaysLabel(d, allDay: _allDay);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _add() {
    final value = int.tryParse(_input.text.trim());
    setState(() {
      if (value == null || value > maxReminderDaysBefore) {
        _error = '0부터 $maxReminderDaysBefore까지 숫자로 넣어 주세요';
        return;
      }
      _error = null;
      _days.add(value);
      _input.clear();
    });
  }

  String get _anchorText {
    final t = widget.event.startTime;
    if (t == null) return '오전 9시';
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final event = widget.event;
    return Padding(
      // 키보드가 올라오면 그만큼 창을 밀어 올린다.
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SingleChildScrollView(
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
              '${event.isMultiDay ? '시작일' : '일정'} 며칠 전 $_anchorText에 '
              '알림을 받을지 정해요',
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            if (_days.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '아래에서 날짜를 추가해 주세요',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _sorted)
                    _DayChip(
                      label: _label(d),
                      onRemove: () => setState(() => _days.remove(d)),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    onSubmitted: (_) => _add(),
                    cursorColor: AppColors.blue,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: '며칠 전 (0 = ${_label(0)})',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      suffixText: '일 전',
                      filled: true,
                      fillColor: AppColors.fill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Pressable(
                  onTap: _add,
                  pressedScale: 0.93,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.inkNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '추가',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
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
              const SizedBox(height: 14),
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
                  : () => Navigator.of(context).pop(_sorted),
            ),
          ],
        ),
      ),
    );
  }
}

/// 넣은 "며칠 전" 하나. 오른쪽 ✕로 뺀다.
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppColors.inkNavy,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Pressable.icon(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.8),
                semanticLabel: '$label 빼기',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
