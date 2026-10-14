import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/mascot_sticker.dart';
import 'models/calendar_event.dart';
import 'widgets/time_pick_sheet.dart';

const List<String> _weekdayKor = ['일', '월', '화', '수', '목', '금', '토'];
const Color _fieldBackground = Color(0xFFF1F1F5);
const Color _mutedText = Color(0xFF6B6B70);

/// 일정 수정/추가 화면(v4 리디자인). [event]가 있으면 그 일정을 고치는
/// "일정 수정", 없으면 [initialDate]에 새로 만드는 "새 일정"이다.
///
/// 저장하면 새 [CalendarEvent]를 반환하며 닫힌다(고치는 경우 id/색/라벨은
/// 그대로). 닫기(X)나 뒤로 가면 null. 저장할 수 있는 조건은 "제목이 있고, 끝나는
/// 날짜가 시작보다 빠르지 않을 것"이다. 시간은 "10~11시" 같은 구간이 아니라
/// 하나만 고르고, 알림(기본 "정각")은 그 시간에 한 번만 울린다.
class EventEditScreen extends StatefulWidget {
  const EventEditScreen({this.event, required this.initialDate, super.key});

  final CalendarEvent? event;

  /// 새 일정일 때 시작/끝 날짜의 초깃값(캘린더에서 선택해 둔 날짜).
  final DateTime initialDate;

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.event?.title ?? '',
  );
  late final TextEditingController _locationController = TextEditingController(
    text: widget.event?.location ?? '',
  );

  late DateTime _startDate = _dateOnly(
    widget.event?.startDate ?? widget.initialDate,
  );
  late DateTime _endDate = _dateOnly(
    widget.event?.endDate ?? widget.initialDate,
  );
  late bool _allDay = widget.event?.isAllDay ?? false;
  late TimeOfDay _time =
      widget.event?.startTime ?? const TimeOfDay(hour: 9, minute: 0);

  /// 알림. 새 일정은 "정각" — 정한 시간에 한 번만 울린다.
  late ReminderOffset? _offset = widget.event == null
      ? ReminderOffset.atStart
      : widget.event!.reminderOffset;

  bool get _isEdit => widget.event != null;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// 끝나는 날짜가 시작보다 빠르면 안내 문구를, 괜찮으면 null.
  String? get _rangeError =>
      _endDate.isBefore(_startDate) ? '끝나는 날짜가 시작보다 빨라요' : null;

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty && _rangeError == null;

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme
              .copyWith(primary: AppColors.cobalt, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final date = _dateOnly(picked);
      if (isStart) {
        _startDate = date;
        // 시작을 끝보다 뒤로 옮기면 끝도 같이 따라가게 한다.
        if (_endDate.isBefore(date)) _endDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePickSheet(
      context,
      title: '시간',
      initialTime: _time,
    );
    if (picked == null) return;
    setState(() => _time = picked);
  }

  void _save() {
    final original = widget.event;
    final location = _locationController.text.trim();
    Navigator.of(context).pop(
      CalendarEvent(
        id: original?.id ?? 'local-${DateTime.now().microsecondsSinceEpoch}',
        startDate: _startDate,
        endDate: _endDate,
        label: original?.label ?? '내 일정',
        title: _titleController.text.trim(),
        color: original?.color ?? AppColors.cobalt,
        startTime: _allDay ? null : _time,
        endTime: null,
        location: location.isEmpty ? null : location,
        reminderOffset: _offset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _rangeError;

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.cobaltDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            widget.event?.label ?? '내 일정',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _isEdit ? '일정 수정' : '새 일정',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: MascotSticker(width: 76, angle: 0.08),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                child: ColoredBox(
                  color: Colors.white,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          children: [
                            const _Label('제목'),
                            TextField(
                              controller: _titleController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: _fieldDecoration(hint: '일정 제목'),
                            ),
                            const SizedBox(height: 18),
                            const _Label('날짜'),
                            Row(
                              children: [
                                Expanded(
                                  child: _PickerButton(
                                    icon: Icons.calendar_today,
                                    text: _dateLabel(_startDate),
                                    onTap: () => _pickDate(isStart: true),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _PickerButton(
                                    icon: Icons.calendar_today,
                                    text: _dateLabel(_endDate),
                                    onTap: () => _pickDate(isStart: false),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Text(
                                    '종일',
                                    style: TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _allDay,
                                    onChanged: (v) =>
                                        setState(() => _allDay = v),
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.cobalt,
                                    inactiveThumbColor: Colors.white,
                                    inactiveTrackColor: const Color(0xFFD8D8DE),
                                    trackOutlineColor:
                                        const WidgetStatePropertyAll(
                                          Colors.transparent,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_allDay) ...[
                              const _Label('시간'),
                              _PickerButton(
                                icon: Icons.access_time,
                                text: _timeLabel(_time),
                                onTap: _pickTime,
                              ),
                            ],
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Color(0xFFE5484D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 18),
                            const _Label('장소'),
                            TextField(
                              controller: _locationController,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: _fieldDecoration(
                                hint: '장소 (선택)',
                                icon: Icons.location_on,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const _Label('알림'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _OffsetChip(
                                  label: '없음',
                                  selected: _offset == null,
                                  onTap: () => setState(() => _offset = null),
                                ),
                                for (final offset in ReminderOffset.values)
                                  _OffsetChip(
                                    label: offset.label,
                                    selected: _offset == offset,
                                    onTap: () =>
                                        setState(() => _offset = offset),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20,
                          4,
                          20,
                          16 + MediaQuery.of(context).padding.bottom,
                        ),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: _canSave
                                ? [
                                    BoxShadow(
                                      color: AppColors.cobalt.withValues(
                                        alpha: 0.35,
                                      ),
                                      offset: const Offset(0, 6),
                                      blurRadius: 14,
                                    ),
                                  ]
                                : null,
                          ),
                          child: SizedBox.expand(
                            child: ElevatedButton(
                              onPressed: _canSave ? _save : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.cobalt,
                                disabledBackgroundColor: const Color(
                                  0xFFC9D3F2,
                                ),
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                '저장하기',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
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
      ),
    );
  }

  static String _dateLabel(DateTime d) =>
      '${d.month}.${d.day} ${_weekdayKor[d.weekday % 7]}';

  static String _timeLabel(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  InputDecoration _fieldDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9A9A9E)),
      prefixIcon: icon == null
          ? null
          : Icon(icon, color: AppColors.cobalt, size: 20),
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.cobalt, width: 1.5),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: _mutedText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: _fieldBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.cobalt),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OffsetChip extends StatelessWidget {
  const _OffsetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.cobalt : _fieldBackground,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
