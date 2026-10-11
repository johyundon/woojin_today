import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import 'models/calendar_event.dart';
import 'services/calendar_event_storage.dart';
import 'widgets/add_schedule_sheet.dart';
import 'widgets/calendar_expand_handle.dart';
import 'widgets/calendar_grid.dart';
import 'widgets/calendar_search_bar.dart';
import 'widgets/event_card.dart';
import 'widgets/month_navigator.dart';
import 'widgets/reminder_time_sheet.dart';

const List<String> _weekdayKorLabels = ['일', '월', '화', '수', '목', '금', '토'];

/// "우진이의 캘린더" 화면 (Figma node 6:39).
///
/// 이 노드는 실제 Figma 벡터 레이어가 아니라 다른 앱을 캡처한 스크린샷 7장이
/// 평탄화된 상태라 `get_design_context`로 쓸만한 코드를 뽑을 수 없었다. 스크린샷을
/// 눈으로 보고 레이아웃/색상/간격을 근사해 재현했다.
///
/// 학사일정 API 연동이 없어(`kUseMockApi = true`) 일정은 최초 1회 하드코딩된
/// 샘플로 시드되지만, 알림(로컬 푸시)을 걸 수 있어야 해서 이후로는
/// [CalendarEventStorage]로 기기 로컬에 저장된다 — 저장이 없으면 앱을 껐다
/// 켰을 때 "화면상 꺼진 토글인데 전에 걸어둔 알림은 그대로 울리는" 불일치가
/// 생긴다.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _storage = CalendarEventStorage();
  final _notifications = NotificationService.instance;

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  List<CalendarEvent> _events = [];
  bool _loaded = false;

  /// false(압축, 기본)면 날짜 박스 + 요약 줄, true(확장)면 박스 없이 긴
  /// 이름표 막대. [CalendarExpandHandle]을 드래그해서 전환한다.
  bool _expandedView = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final saved = await _storage.loadAll();
    if (saved.isNotEmpty) {
      setState(() {
        _events = saved;
        _loaded = true;
      });
      return;
    }
    // 최초 실행 — 샘플 데이터로 시드하고 바로 저장해둔다(그래야 알림을
    // 걸었을 때 다음 실행에서도 그 상태가 유지된다).
    final seed = _buildSampleEvents();
    await _storage.saveAll(seed);
    if (!mounted) return;
    setState(() {
      _events = seed;
      _loaded = true;
    });
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

  void _goToPreviousMonth() {
    setState(
      () =>
          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1),
    );
  }

  void _goToNextMonth() {
    setState(
      () =>
          _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1),
    );
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

  /// [event.startDate]와 [time]을 합친 실제 알림 시각. 여러 날짜짜리
  /// 일정이어도 마감일이 아닌 시작일 기준으로 한 번만 울린다(제품 결정).
  DateTime _reminderMoment(CalendarEvent event, TimeOfDay time) {
    return DateTime(
      event.startDate.year,
      event.startDate.month,
      event.startDate.day,
      time.hour,
      time.minute,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onReminderToggled(CalendarEvent event, bool turnOn) async {
    if (!turnOn) {
      setState(() => event.reminderTime = null);
      await _notifications.cancelReminder(event.id);
      await _persist();
      return;
    }
    await _promptAndScheduleReminder(event);
  }

  /// "HH:mm 알림" 텍스트를 눌러 이미 켜진 알림의 시간을 바꿀 때 호출된다.
  /// 토글을 껐다 켜지 않고도 바로 시간 설정 시트를 다시 띄운다.
  Future<void> _onEditReminderTime(CalendarEvent event) {
    return _promptAndScheduleReminder(event);
  }

  /// 시간 설정 시트를 띄워 알림을 (다시) 예약한다. 토글을 켤 때와 이미 켜진
  /// 알림의 시간을 바꿀 때 둘 다 이 로직을 그대로 쓴다.
  Future<void> _promptAndScheduleReminder(CalendarEvent event) async {
    final granted = await _notifications.requestPermission();
    if (!mounted) return;
    if (!granted) {
      _showMessage('알림을 받으려면 설정에서 알림 권한을 허용해주세요');
      return;
    }

    final time = await showReminderTimeSheet(
      context,
      eventTitle: event.title,
      initialTime: event.reminderTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return; // 취소 -> 이전 상태 그대로 유지.

    final scheduledAt = _reminderMoment(event, time);
    if (scheduledAt.isBefore(DateTime.now())) {
      _showMessage('이미 지난 일정이라 알림을 걸 수 없어요');
      return;
    }

    setState(() => event.reminderTime = time);
    await _notifications.scheduleReminder(
      eventId: event.id,
      title: event.title,
      body:
          '${event.label} · ${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')} 알림',
      scheduledAt: scheduledAt,
    );
    await _persist();
  }

  Future<void> _onAddPressed() async {
    final selected = _selectedDate;
    if (selected == null) return;
    final result = await showAddScheduleSheet(context);
    if (result == null) return;
    final (title, time) = result;

    final newEvent = CalendarEvent(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      startDate: selected,
      endDate: selected,
      label: '내 일정',
      title: title,
      color: AppColors.accent,
      reminderTime: time,
    );
    final scheduledAt = _reminderMoment(newEvent, time);
    if (scheduledAt.isBefore(DateTime.now())) {
      _showMessage('이미 지난 시각이라 알림 없이 일정만 추가할게요');
      newEvent.reminderTime = null;
    } else {
      final granted = await _notifications.requestPermission();
      if (granted) {
        await _notifications.scheduleReminder(
          eventId: newEvent.id,
          title: newEvent.title,
          body:
              '${newEvent.label} · '
              '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')} 알림',
          scheduledAt: scheduledAt,
        );
      } else {
        _showMessage('알림 권한이 없어 일정만 추가할게요');
        newEvent.reminderTime = null;
      }
    }

    setState(() => _events.add(newEvent));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    final selectedDay = _selectedDayInFocusedMonth;
    final selectedDate = _selectedDate;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CalendarSearchBar(),
                    const SizedBox(height: 12),
                    MonthNavigator(
                      focusedMonth: _focusedMonth,
                      onPreviousMonth: _goToPreviousMonth,
                      onNextMonth: _goToNextMonth,
                    ),
                    const SizedBox(height: 4),
                    CalendarGrid(
                      focusedMonth: _focusedMonth,
                      events: _eventsInFocusedMonth,
                      selectedDay: selectedDay,
                      expanded: _expandedView,
                      onDaySelected: _onDaySelected,
                    ),
                    CalendarExpandHandle(
                      expanded: _expandedView,
                      onChanged: (value) =>
                          setState(() => _expandedView = value),
                    ),
                    if (selectedDay != null && selectedDate != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        '${selectedDate.month}월 ${selectedDate.day}일 '
                        '(${_weekdayKorLabels[selectedDate.weekday % 7]})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final event in _selectedDateEvents)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: EventCard(
                            event: event,
                            onReminderToggled: (turnOn) =>
                                _onReminderToggled(event, turnOn),
                            onEditReminderTime: () =>
                                _onEditReminderTime(event),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: selectedDay != null && selectedDate != null
          ? FloatingActionButton.extended(
              onPressed: _onAddPressed,
              backgroundColor: AppColors.surface,
              elevation: 0,
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.border),
              ),
              icon: const Icon(Icons.add, color: AppColors.accent),
              label: Text(
                '${selectedDate.month}월 ${selectedDate.day}일 '
                '(${_weekdayKorLabels[selectedDate.weekday % 7]})',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
