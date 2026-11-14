import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../utils/weekday_labels.dart';
import '../../widgets/mascot_sticker.dart';
import '../../widgets/pressable.dart';
import '../../widgets/primary_button.dart';
import 'models/calendar_event.dart';
import 'widgets/calendar_colors.dart';
import 'widgets/date_pick_sheet.dart';
import 'widgets/time_pick_sheet.dart';

/// 일정 수정/추가 화면(v7). [event]가 있으면 그 일정을 고치는
/// "일정 수정", 없으면 [initialDate]에 새로 만드는 "새 일정"이다.
///
/// 저장하면 새 [CalendarEvent]를 반환하며 닫힌다(고치는 경우 id/색/라벨은
/// 그대로). 닫기(X)나 뒤로 가면 null. 저장할 수 있는 조건은 "제목이 있고, 끝나는
/// 날짜가 시작보다 빠르지 않을 것"이다. 시간은 "10~11시" 같은 구간이 아니라
/// 하나만 고른다. 알림은 일정 카드의 종 버튼(알림 설정 창)에서 정하고, 새 일정은
/// 기본으로 정각 알림이 켜진다.
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

  /// 입력 중인 칸은 흰 바탕 + 파란 테두리로 바꿔 보여준다(v7).
  final _titleFocus = FocusNode();
  final _locationFocus = FocusNode();

  late DateTime _startDate = _dateOnly(
    widget.event?.startDate ?? widget.initialDate,
  );
  late DateTime _endDate = _dateOnly(
    widget.event?.endDate ?? widget.initialDate,
  );
  late bool _allDay = widget.event?.isAllDay ?? false;
  late TimeOfDay _time =
      widget.event?.startTime ?? const TimeOfDay(hour: 9, minute: 0);

  /// 알림 칩은 숨겨 둔다 — 알림은 종 버튼의 알림 설정 창 한 곳에서 정한다(사용자
  /// 결정, 2026-11-13). 칩 코드는 지우지 않고 남겨 두며, 칩에서 고른 값은 저장하지
  /// 않는다.
  static const _showReminderChips = false;

  late ReminderOffset? _offset = widget.event?.hasReminder == false
      ? null
      : ReminderOffset.atStart;

  bool get _isEdit => widget.event != null;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _titleFocus.addListener(_onFocusChanged);
    _locationFocus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _titleFocus.dispose();
    _locationFocus.dispose();
    super.dispose();
  }

  /// 끝나는 날짜가 시작보다 빠르면 안내 문구를, 괜찮으면 null.
  String? get _rangeError =>
      _endDate.isBefore(_startDate) ? '끝나는 날짜가 시작보다 빨라요' : null;

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty && _rangeError == null;

  /// 날짜 칸(시작·끝 어느 쪽이든)을 누르면 시작~끝을 한 번에 고르는 시트를 연다.
  Future<void> _pickDates() async {
    final picked = await showDateRangePickSheet(
      context,
      initialStart: _startDate,
      initialEnd: _endDate,
    );
    if (picked == null) return;
    setState(() {
      _startDate = _dateOnly(picked.start);
      _endDate = _dateOnly(picked.end);
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
        color: original?.color ?? AppColors.blue,
        startTime: _allDay ? null : _time,
        endTime: null,
        location: location.isEmpty ? null : location,
        // 알림은 그대로 둔다. 새 일정은 정각(당일) 알림 하나.
        reminderDaysBefore: original?.reminderDaysBefore ?? const [0],
        reminderTime: original?.reminderTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _rangeError;

    // 거의 흰 바탕이라 상태 표시줄 글자를 어둡게 둔다(앱 테마는 아직 어두운 테마).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        // 키보드 양옆 둥근 모서리 틈으로 Scaffold 바탕이 비쳐도 어색하지 않게
        // 바탕은 흰색으로 두고, 위쪽 연한 바탕은 body 영역에만 깐다.
        backgroundColor: Colors.white,
        // 앱 테마가 어두운 테마라 글자 선택 손잡이·선택 영역 색을 직접 정한다.
        body: Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: const TextSelectionThemeData(
              cursorColor: AppColors.blue,
              selectionColor: AppColors.blueSoftLine,
              selectionHandleColor: AppColors.blue,
            ),
          ),
          child: ColoredBox(
            color: AppColors.canvas,
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // 마스코트를 오른쪽 끝에 붙이려고 머리 영역을 화면 폭만큼 넓힌다.
                      const SizedBox(width: double.infinity),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
                        child: Pressable.icon(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textStrong,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.blueSoft,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.event?.label ?? '내 일정',
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isEdit ? '일정 수정' : '새 일정',
                              style: const TextStyle(
                                color: AppColors.textStrong,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.04,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Positioned(
                        right: 10,
                        top: 13,
                        child: MascotSticker(width: 93, angle: 0.14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(36),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x0F000000),
                            offset: Offset(0, -4),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                24,
                                20,
                                16,
                              ),
                              children: [
                                _Section(
                                  label: '제목',
                                  child: _InputBox(
                                    focused: _titleFocus.hasFocus,
                                    child: TextField(
                                      controller: _titleController,
                                      focusNode: _titleFocus,
                                      onChanged: (_) => setState(() {}),
                                      cursorColor: AppColors.blue,
                                      style: _valueStyle,
                                      decoration: _inputDecoration('일정 제목'),
                                    ),
                                  ),
                                ),
                                _Section(
                                  label: '날짜',
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _ValueBox(
                                          icon: Icons.calendar_today_rounded,
                                          text: _dateLabel(_startDate),
                                          onTap: _pickDates,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _ValueBox(
                                          icon: Icons.calendar_today_rounded,
                                          text: _dateLabel(_endDate),
                                          onTap: _pickDates,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      0,
                                      4,
                                      16,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          size: 14,
                                          color: CalendarColors.deleteRed,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            error,
                                            style: const TextStyle(
                                              color: CalendarColors.deleteRed,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    0,
                                    4,
                                    16,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          '종일',
                                          style: TextStyle(
                                            color: AppColors.textStrong,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 48,
                                        height: 28,
                                        child: FittedBox(
                                          child: Switch(
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            value: _allDay,
                                            onChanged: (v) =>
                                                setState(() => _allDay = v),
                                            activeThumbColor: Colors.white,
                                            activeTrackColor: AppColors.inkNavy,
                                            inactiveThumbColor: Colors.white,
                                            inactiveTrackColor:
                                                AppColors.checkLine,
                                            trackOutlineColor:
                                                const WidgetStatePropertyAll(
                                                  Colors.transparent,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // 시간은 하나만 고른다(끝나는 시간 칸 없음).
                                if (!_allDay)
                                  _Section(
                                    label: '시간',
                                    child: _ValueBox(
                                      icon: Icons.watch_later_rounded,
                                      text: _timeLabel(_time),
                                      onTap: _pickTime,
                                    ),
                                  ),
                                _Section(
                                  label: '장소',
                                  child: _InputBox(
                                    focused: _locationFocus.hasFocus,
                                    icon: Icons.location_on_rounded,
                                    child: TextField(
                                      controller: _locationController,
                                      focusNode: _locationFocus,
                                      cursorColor: AppColors.blue,
                                      style: _valueStyle,
                                      decoration: _inputDecoration('장소 (선택)'),
                                    ),
                                  ),
                                ),
                                if (_showReminderChips)
                                  _Section(
                                    label: '알림',
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        _OffsetChip(
                                          label: '없음',
                                          selected: _offset == null,
                                          onTap: () =>
                                              setState(() => _offset = null),
                                        ),
                                        for (final offset
                                            in ReminderOffset.values)
                                          _OffsetChip(
                                            label: offset.label,
                                            selected: _offset == offset,
                                            onTap: () => setState(
                                              () => _offset = offset,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              4,
                              24,
                              16 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: PrimaryButton(
                              label: '저장하기',
                              enabled: _canSave,
                              onPressed: _save,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const TextStyle _valueStyle = TextStyle(
    color: AppColors.textStrong,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  /// 칸 모양은 [_InputBox]가 그리므로 입력칸 자체는 테두리·바탕 없이 둔다
  /// (앱 테마가 어두운 테마라 기본값에 기대지 않고 전부 정한다).
  static InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 15,
      fontWeight: FontWeight.w700,
    ),
    isDense: true,
    filled: false,
    contentPadding: EdgeInsets.zero,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
  );

  static String _dateLabel(DateTime d) =>
      '${d.month}.${d.day} ${weekdayLabelsSunFirst[d.weekday % 7]}';

  static String _timeLabel(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// 칸 이름(작은 회색 글자) + 그 아래 칸. 섹션 사이는 16 띄운다.
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSub,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

/// 글자를 입력하는 칸(높이 58). 평소엔 연회색, 입력 중엔 흰 바탕 + 파란 테두리.
class _InputBox extends StatelessWidget {
  const _InputBox({required this.focused, required this.child, this.icon});

  final bool focused;
  final IconData? icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: focused ? Colors.white : AppColors.fill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? AppColors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 17, color: AppColors.blue),
            const SizedBox(width: 10),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// 눌러서 고르는 값(날짜/시간) 칸. 연회색 바탕에 파란 아이콘과 값.
class _ValueBox extends StatelessWidget {
  const _ValueBox({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _EventEditScreenState._valueStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 알림 시점 칩. 고른 칩은 남색 바탕 + 흰 글자.
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
    return Pressable(
      onTap: onTap,
      pressedScale: 0.93,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.inkNavy : AppColors.fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textStrong,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
