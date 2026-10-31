import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../utils/weekday_labels.dart';
import '../../widgets/mascot_sticker.dart';
import 'models/calendar_event.dart';
import 'widgets/date_pick_sheet.dart';
import 'widgets/time_pick_sheet.dart';

const Color _fieldBackground = Color(0xFFF1F1F5);
const Color _mutedText = Color(0xFF6B6B70);
const Color _hintText = Color(0xFFB4B4BA);
const Color _divider = Color(0xFFE4E4EA);
const Color _iconTileBackground = Color(0xFFDCE6FB);
const Color _errorText = Color(0xFFE5484D);

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
      // 키보드 양옆 둥근 모서리 틈으로 Scaffold 바탕이 비쳐 파랑이 보이지
      // 않도록, 바탕은 흰색으로 두고 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: AppColors.cobalt,
        child: SafeArea(
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
                          // 닫기(X)와 라벨 칩을 한 줄에 둬서 머리 영역을 낮춘다
                          // (키보드가 올라와도 입력 칸이 넉넉히 보이게).
                          Row(
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
                              const SizedBox(width: 10),
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
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isEdit ? '일정 수정' : '새 일정',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
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
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                            children: [
                              // 제목: 상세 팝업의 제목처럼 크게 쓰고, 밑줄만 둔다.
                              TextField(
                                controller: _titleController,
                                onChanged: (_) => setState(() {}),
                                cursorColor: AppColors.cobalt,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '일정 제목',
                                  hintStyle: TextStyle(
                                    color: _hintText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  isDense: true,
                                  contentPadding: EdgeInsets.fromLTRB(
                                    2,
                                    6,
                                    2,
                                    12,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _divider,
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.cobalt,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              _SectionCard(
                                children: [
                                  _FieldRow(
                                    icon: Icons.calendar_today,
                                    label: '날짜',
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _ValuePill(
                                          text: _dateLabel(_startDate),
                                          onTap: _pickDates,
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Icon(
                                            Icons.arrow_forward,
                                            size: 14,
                                            color: _mutedText,
                                          ),
                                        ),
                                        _ValuePill(
                                          text: _dateLabel(_endDate),
                                          onTap: _pickDates,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _FieldRow(
                                    icon: Icons.wb_sunny_outlined,
                                    label: '종일',
                                    trailing: Switch(
                                      value: _allDay,
                                      onChanged: (v) =>
                                          setState(() => _allDay = v),
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: AppColors.cobalt,
                                      inactiveThumbColor: Colors.white,
                                      inactiveTrackColor: const Color(
                                        0xFFD8D8DE,
                                      ),
                                      trackOutlineColor:
                                          const WidgetStatePropertyAll(
                                            Colors.transparent,
                                          ),
                                    ),
                                  ),
                                  if (!_allDay)
                                    _FieldRow(
                                      icon: Icons.access_time,
                                      label: '시간',
                                      trailing: _ValuePill(
                                        text: _timeLabel(_time),
                                        onTap: _pickTime,
                                      ),
                                    ),
                                ],
                              ),
                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    4,
                                    8,
                                    4,
                                    0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 14,
                                        color: _errorText,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          error,
                                          style: const TextStyle(
                                            color: _errorText,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _locationController,
                                cursorColor: AppColors.cobalt,
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
                              const SizedBox(height: 12),
                              _SectionCard(
                                children: [
                                  const _FieldRow(
                                    icon: Icons.notifications_none,
                                    label: '알림',
                                  ),
                                  // 칩이 카드 가운데로 몰리지 않고 왼쪽부터 채워지게 폭을 꽉 채운다.
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.fromLTRB(
                                      14,
                                      0,
                                      14,
                                      14,
                                    ),
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
      ),
    );
  }

  static String _dateLabel(DateTime d) =>
      '${d.month}.${d.day} ${weekdayLabelsSunFirst[d.weekday % 7]}';

  static String _timeLabel(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 장소 칸. 로그인 화면 입력칸처럼 왼쪽에 파란 아이콘 타일을 둔다.
  InputDecoration _fieldDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: _hintText, fontWeight: FontWeight.w700),
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: _IconTile(icon: icon),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: _fieldBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: AppColors.cobalt, width: 1.5),
      ),
    );
  }
}

/// 연한 회색 둥근 카드. 안의 줄들 사이에 얇은 구분선을 넣는다.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0 && children[i] is _FieldRow)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 62,
                endIndent: 14,
                color: _divider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// 카드 안의 한 줄: [아이콘 타일] 라벨 ........ [trailing].
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            _IconTile(icon: icon),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            const Spacer(),
            // 좁은 화면에서 날짜 두 개가 안 들어가면 넘치지 않게 살짝 줄인다.
            if (trailing != null)
              Flexible(
                flex: 100,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: trailing,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 상세 팝업의 줄 아이콘과 같은 연파랑 사각 타일.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _iconTileBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 18, color: AppColors.cobalt),
    );
  }
}

/// 눌러서 고르는 값(날짜/시간)을 보여주는 흰 알약 버튼.
class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.cobalt : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.cobalt : _divider,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: AppColors.lime),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
