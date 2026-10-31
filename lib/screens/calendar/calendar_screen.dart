import 'package:flutter/material.dart';

import '../../services/academic_schedule_service.dart';
import '../../services/notification_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import '../../utils/weekday_labels.dart';
import 'event_edit_screen.dart';
import 'models/calendar_event.dart';
import 'services/academic_schedule_merge.dart';
import 'services/calendar_event_storage.dart';
import '../home/widgets/home_bottom_nav.dart';
import 'widgets/calendar_month_grid.dart';
import 'widgets/event_delete_dialog.dart';
import 'widgets/event_detail_sheet.dart';
import 'widgets/event_row.dart';
import 'widgets/reminder_past_dialog.dart';
import 'widgets/reminder_set_dialog.dart';

/// [_CalendarScreenState._syncReminder]의 결과.
enum _ReminderResult { ok, denied, past }

/// "캘린더" 화면(v4 리디자인). 코발트 헤더에서 달을 넘기고, 흰 패널의 월간
/// 격자에서 날짜를 고르면 그날의 일정이 시간순 카드로 아래에 나온다.
///
/// 학사일정은 보고 있는 달을 학교 홈페이지에서 받아([AcademicScheduleService],
/// 달별 하루 캐시) 저장된 일정에 합친다([mergeAcademicSchedule]). 예전에 넣어 둔
/// 샘플 일정은 이때 빠진다([_buildSampleEvents]는 남겨 두었지만 쓰지 않는다).
/// 알림(로컬 푸시)을 걸 수 있어야 해서 일정은 [CalendarEventStorage]로 기기에
/// 저장된다 — 저장이 없으면 앱을 껐다 켰을 때 "화면상 꺼진 토글인데 전에 걸어둔
/// 알림은 그대로 울리는" 불일치가 생긴다. 받기에 실패하면 저장된 일정을 그대로
/// 보여주고 안내만 띄운다.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({this.onTabTap, this.scheduleService, super.key});

  /// 테스트용 주입 지점.
  final AcademicScheduleServiceBase? scheduleService;

  /// 하단 탭 바를 눌렀을 때 호출된다(홈이 그 탭 화면으로 바꿔 준다). 없으면 이전
  /// 화면으로 돌아가기만 한다.
  final ValueChanged<int>? onTabTap;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = CalendarEventStorage();
  final _notifications = NotificationService.instance;
  late final AcademicScheduleServiceBase _scheduleService =
      widget.scheduleService ?? ServiceFactory.academicSchedule();

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  List<CalendarEvent> _events = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final saved = await _storage.loadAll();
    if (!mounted) return;
    // 예전 샘플 일정은 학사일정을 못 받더라도 바로 빼고 알림도 취소한다.
    final samples = saved.where((e) => e.id.startsWith('sample-')).toList();
    setState(() {
      _events = saved.where((e) => !samples.contains(e)).toList();
      _loaded = true;
    });
    if (samples.isNotEmpty) {
      for (final event in samples) {
        await _cancelReminders(event);
      }
      await _persist();
    }
    await _syncMonth(_focusedMonth);
  }

  /// [month]의 학사일정을 받아 저장된 일정에 합치고, 빠진 일정의 알림은 취소하고,
  /// 마감일이 바뀐 일정의 알림은 다시 건다. 실패하면 저장된 일정을 그대로 둔다.
  Future<void> _syncMonth(DateTime month) async {
    final List<AcademicScheduleItem> fetched;
    try {
      fetched = await _scheduleService.fetchMonth(month.year, month.month);
    } on AcademicScheduleException {
      if (mounted && month == _focusedMonth) {
        _showMessage('학사일정을 불러오지 못했어요. 저장된 일정만 보여드려요');
      }
      return;
    }
    if (!mounted) return;
    final merged = mergeAcademicSchedule(
      current: _events,
      fetched: fetched,
      year: month.year,
      month: month.month,
    );
    setState(() => _events = merged.events);
    for (final event in merged.removed) {
      await _cancelReminders(event);
    }
    for (final event in merged.changed) {
      await _syncReminder(event);
    }
    await _persist();
  }

  Future<void> _persist() => _storage.saveAll(_events);

  /// 보고 있는 달과 겹치는(완전히 그 달 안에 있지 않아도 일부라도 걸치는)
  /// 일정 전체. 여러 날짜 칸을 가로지르는 막대 렌더링은 [CalendarGrid]가
  /// 주(week) 단위로 직접 계산한다.
  List<CalendarEvent> get _eventsInFocusedMonth {
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    return _events
        .where(
          (e) =>
              !e.endDate.isBefore(monthStart) && !e.startDate.isAfter(monthEnd),
        )
        .toList();
  }

  /// 선택된 날짜가 지금 보고 있는 달 안에 있을 때만 일(day)을 반환한다.
  int? get _selectedDayInFocusedMonth {
    final selected = _selectedDate;
    if (selected == null) return null;
    if (selected.year != _focusedMonth.year ||
        selected.month != _focusedMonth.month) {
      return null;
    }
    return selected.day;
  }

  List<CalendarEvent> get _selectedDateEvents {
    final selected = _selectedDate;
    if (selected == null) return const [];
    return _events.where((e) => _eventCoversDate(e, selected)).toList();
  }

  void _goToPreviousMonth() => _moveMonth(-1);

  void _goToNextMonth() => _moveMonth(1);

  /// 달을 넘기면 그 달의 날짜를 하나 골라 둔다(오늘이 그 달이면 오늘, 아니면
  /// 1일) — 아래 일정 목록과 "+" 버튼이 항상 쓸 수 있게.
  void _moveMonth(int delta) {
    final month = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    final now = DateTime.now();
    final isTodayMonth = now.year == month.year && now.month == month.month;
    setState(() {
      _focusedMonth = month;
      _selectedDate = DateTime(
        month.year,
        month.month,
        isTodayMonth ? now.day : 1,
      );
    });
    _syncMonth(month);
  }

  void _onDaySelected(int day) {
    setState(
      () => _selectedDate = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        day,
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 알림 스위치/종 버튼. 켜면 "정각" 알림(일정 시간에 한 번)을 걸고, 끄면 알림을
  /// 없앤다. 이미 지난 시각이라 못 거는 경우에는 알림을 되돌려 놓은 뒤 팝업으로
  /// 알려준다.
  Future<void> _onReminderToggled(CalendarEvent event, bool turnOn) async {
    if (!turnOn) {
      setState(() => event.reminderOffset = null);
      await _syncReminder(event);
      await _persist();
      return;
    }
    final previous = event.reminderOffset;
    setState(() => event.reminderOffset = ReminderOffset.atStart);
    final attemptedAt = event.reminderAt;
    final outcome = await _syncReminder(event);
    if (outcome.result != _ReminderResult.ok && mounted) {
      setState(() => event.reminderOffset = previous);
    }
    await _persist();
    if (outcome.result == _ReminderResult.past &&
        attemptedAt != null &&
        mounted) {
      await showReminderPastDialog(context, attemptedAt: attemptedAt);
    }
    // 시간 정보가 없는 일정(학사일정 등)은 언제 울리는지 팝업으로 알려준다. 여러 날
    // 일정은 시작일과 마감일 둘 다, 시작일이 이미 지났으면 남은 마감일만 나온다.
    if (outcome.result == _ReminderResult.ok && event.isAllDay && mounted) {
      await showReminderSetDialog(context, dates: outcome.scheduled);
    }
  }

  /// [event]에 걸려 있던 알림 예약을 전부 취소한다(시작일 알림과, 여러 날 일정의
  /// 마감일 알림).
  Future<void> _cancelReminders(CalendarEvent event) async {
    await _notifications.cancelReminder(event.id);
    await _notifications.cancelReminder('${event.id}#end');
  }

  /// [event]의 알림을 폰에 (다시) 예약하거나, 알림이 꺼져 있으면 예약을 취소한다.
  /// 울려야 할 시각([CalendarEvent.reminderAts]) 중 아직 안 지난 것만 건다 — 하나라도
  /// 걸리면 성공이고, 건 시각들을 [scheduled]로 돌려준다. 전부 지났으면
  /// [_ReminderResult.past], 권한이 없으면 안내 메시지를 띄우고
  /// [_ReminderResult.denied]를 돌려준다. 실패하면 호출한 쪽이 알림 상태를 되돌린다.
  Future<({_ReminderResult result, List<DateTime> scheduled})> _syncReminder(
    CalendarEvent event,
  ) async {
    final all = event.reminderAts;
    if (all.isEmpty) {
      await _cancelReminders(event);
      return (result: _ReminderResult.ok, scheduled: const <DateTime>[]);
    }

    final granted = await _notifications.requestPermission();
    if (!mounted) {
      return (result: _ReminderResult.denied, scheduled: const <DateTime>[]);
    }
    if (!granted) {
      _showMessage('알림을 받으려면 설정에서 알림 권한을 허용해주세요');
      await _cancelReminders(event);
      return (result: _ReminderResult.denied, scheduled: const <DateTime>[]);
    }

    final now = DateTime.now();
    final scheduled = <DateTime>[];
    await _cancelReminders(event);
    for (var i = 0; i < all.length; i++) {
      if (all[i].isBefore(now)) continue;
      await _notifications.scheduleReminder(
        // 첫 번째는 시작일, 두 번째는 마감일 알림 — 따로 취소할 수 있게 번호를 나눈다.
        eventId: i == 0 ? event.id : '${event.id}#end',
        title: event.title,
        body: '${event.label} · ${event.reminderOffset!.label}',
        scheduledAt: all[i],
      );
      scheduled.add(all[i]);
    }
    return (
      result: scheduled.isEmpty ? _ReminderResult.past : _ReminderResult.ok,
      scheduled: scheduled,
    );
  }

  /// 일정 카드를 눌렀을 때 — 상세 팝업을 열고, 거기서 고른 동작을 처리한다.
  Future<void> _openEventDetail(CalendarEvent event) async {
    final action = await showEventDetailSheet(
      context,
      event: event,
      onReminderToggled: (turnOn) => _onReminderToggled(event, turnOn),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case EventDetailAction.delete:
        await _confirmAndDelete(event);
      case EventDetailAction.edit:
        await _openEditor(event);
    }
  }

  /// "일정을 삭제할까요?" 확인 뒤 일정을 지운다. 걸려 있던 알림 예약도 같이
  /// 취소해야 한다(안 그러면 없는 일정의 알림이 울린다).
  Future<void> _confirmAndDelete(CalendarEvent event) async {
    final confirmed = await showEventDeleteDialog(
      context,
      eventTitle: event.title,
    );
    if (!confirmed || !mounted) return;

    await _cancelReminders(event);
    setState(() => _events.removeWhere((e) => e.id == event.id));
    await _persist();
  }

  Future<void> _onAddPressed() async {
    if (_selectedDate == null) return;
    await _openEditor(null);
  }

  /// 수정/추가 화면을 열고, 저장돼 돌아오면 목록에 반영하고 알림을 다시 건다.
  /// [event]가 null이면 새 일정이다.
  Future<void> _openEditor(CalendarEvent? event) async {
    final saved = await Navigator.of(context).push<CalendarEvent>(
      MaterialPageRoute(
        builder: (_) => EventEditScreen(
          event: event,
          initialDate: _selectedDate ?? DateTime.now(),
        ),
      ),
    );
    if (saved == null || !mounted) return;

    // 알림을 걸 수 없으면(권한 거부/이미 지난 시각) 일정은 저장하고 알림만 뺀다.
    final attemptedAt = saved.reminderAt;
    final result = (await _syncReminder(saved)).result;
    if (result != _ReminderResult.ok) saved.reminderOffset = null;

    setState(() {
      final index = _events.indexWhere((e) => e.id == saved.id);
      if (index == -1) {
        _events.add(saved);
      } else {
        _events[index] = saved;
      }
      // 저장한 일정이 보이는 날짜로 따라간다.
      _focusedMonth = DateTime(saved.startDate.year, saved.startDate.month);
      _selectedDate = saved.startDate;
    });
    await _persist();
    if (result == _ReminderResult.past && attemptedAt != null && mounted) {
      await showReminderPastDialog(context, attemptedAt: attemptedAt);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.cobalt,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final selectedDay = _selectedDayInFocusedMonth;
    final selectedDate = _selectedDate;
    final dayEvents = _selectedDateEvents;

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      extendBody: true,
      // 다른 탭은 홈이 그 탭 화면으로 바꿔 준다(콜백이 없으면 이전 화면으로 돌아감).
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: 3,
        onTap: (index) {
          if (index == 3) return;
          final onTabTap = widget.onTabTap;
          if (onTabTap != null) {
            onTabTap(index);
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                      '${_focusedMonth.year}',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_focusedMonth.month}월',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.04,
                    ),
                  ),
                  const Spacer(),
                  _monthButton(Icons.chevron_left, _goToPreviousMonth),
                  const SizedBox(width: 8),
                  _monthButton(Icons.chevron_right, _goToNextMonth),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 달력 격자와 날짜 줄은 고정하고, 아래 일정 목록만
                      // 스크롤된다.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: CalendarMonthGrid(
                          focusedMonth: _focusedMonth,
                          events: _eventsInFocusedMonth,
                          selectedDay: selectedDay,
                          today: DateTime.now(),
                          onDaySelected: _onDaySelected,
                        ),
                      ),
                      if (selectedDay != null && selectedDate != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
                          child: Row(
                            children: [
                              Text(
                                '${selectedDate.month}월 ${selectedDate.day}일 '
                                '${weekdayLabelsSunFirst[selectedDate.weekday % 7]}요일',
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '일정 ${dayEvents.length}개',
                                style: const TextStyle(
                                  color: AppColors.cobalt,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: _onAddPressed,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.cobalt,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.cobalt.withValues(
                                          alpha: 0.35,
                                        ),
                                        offset: const Offset(0, 4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: dayEvents.isEmpty
                              ? const Center(
                                  child: Text(
                                    '이 날은 일정이 없어요',
                                    style: TextStyle(
                                      color: Color(0xFF6B6B70),
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    0,
                                    20,
                                    130,
                                  ),
                                  itemCount: dayEvents.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) {
                                    final event = dayEvents[index];
                                    return EventRow(
                                      event: event,
                                      onReminderToggled: (turnOn) =>
                                          _onReminderToggled(event, turnOn),
                                      onTap: () => _openEventDetail(event),
                                    );
                                  },
                                ),
                        ),
                      ],
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

  Widget _monthButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.cobaltDeep,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

/// 샘플 학사일정 데이터. 참고 스크린샷(여러 날에 걸친 일정이 막대 하나로
/// 이어지는 레이아웃, 원래는 "2026년 9월")에 보이는 날짜 범위/색을 눈으로
/// 보고 근사했다 — 실제 학사일정 API 연동 전까지의 하드코딩 목업. 앱을 실행한
/// 달에 바로 일정이 보이도록 날짜는 스크린샷 속 일(day) 그대로, 달/연도만
/// 실행 시점의 현재 달로 맞춘다. 제목 중 일부는 스크린샷에서 말줄임표로 잘려
/// 원문을 확인할 수 없어 그럴듯한 학사일정 제목으로 추정했다(아래 각 추정
/// 항목에 주석으로 표시).
// 실제 학사일정으로 바꾼 뒤로는 쓰지 않지만, 사용자 요청으로 지우지 않고 남겨 둔다.
// ignore: unused_element
List<CalendarEvent> _buildSampleEvents() {
  final now = DateTime.now();
  var nextId = 0;
  CalendarEvent make(int startDay, int endDay, Color color, String title) {
    nextId++;
    return CalendarEvent(
      id: 'sample-$nextId',
      startDate: DateTime(now.year, now.month, startDay),
      endDate: DateTime(now.year, now.month, endDay),
      label: '학사일정',
      title: title,
      color: color,
    );
  }

  final blue = calendarEventPalette[0];
  final purple = calendarEventPalette[1];
  final orange = calendarEventPalette[2];
  final green = calendarEventPalette[3];
  final pink = calendarEventPalette[4];

  return [
    make(1, 4, blue, '2026학년도 2학기 수강신청 변경'),
    // 추정: 스크린샷에서 "2026…"으로 잘려 원문 확인 불가.
    make(1, 1, green, '2026학년도 2학기 복학 신청 기간'),
    // 추정: 스크린샷에서 "2026학년도 2…"로 잘려 원문 확인 불가.
    make(6, 7, blue, '2026학년도 2학기 수강정정 기간'),
    make(8, 9, purple, '2026학년도 2학기 폐강과목 공지'),
    make(8, 11, orange, '2027학년도 대학입학전형 수시모집 원서접수'),
    make(8, 8, orange, '2026학년도 2학기 폐강과목 수강 변경'),
    make(14, 15, purple, '왕방축제'),
    make(17, 19, blue, '수료생 재심사 등록'),
    // 20~23일은 위와 같은 일정의 다음 주 세그먼트(주 경계를 넘는 일정은
    // 주마다 독립된 막대로 끊어 그린다).
    make(20, 23, blue, '수료생 재심사 등록'),
    // 추정: 스크린샷에서 "수업…"으로 잘려 원문 확인 불가.
    make(21, 21, purple, '수업평가 참여 기간'),
    // 추정: 스크린샷에서 "학기 …"로 잘려 원문 확인 불가.
    make(30, 30, pink, '2학기 수업일수 1/4선'),
  ];
}

/// [event]의 날짜 범위([CalendarEvent.startDate]~[CalendarEvent.endDate])가
/// [date]를 포함하는지 날짜 단위로 비교한다(시:분 무시).
bool _eventCoversDate(CalendarEvent event, DateTime date) {
  final day = DateTime(date.year, date.month, date.day);
  final start = DateTime(
    event.startDate.year,
    event.startDate.month,
    event.startDate.day,
  );
  final end = DateTime(
    event.endDate.year,
    event.endDate.month,
    event.endDate.day,
  );
  return !day.isBefore(start) && !day.isAfter(end);
}
