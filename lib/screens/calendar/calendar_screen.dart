import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/academic_schedule_service.dart';
import '../../services/notification_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import '../../utils/weekday_labels.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import 'event_edit_screen.dart';
import 'models/calendar_event.dart';
import 'services/academic_schedule_merge.dart';
import 'services/calendar_event_storage.dart';
import '../home/widgets/home_bottom_nav.dart';
import 'widgets/calendar_colors.dart';
import 'widgets/calendar_expanded_grid.dart';
import 'widgets/calendar_month_grid.dart';
import 'widgets/event_delete_dialog.dart';
import 'widgets/event_detail_sheet.dart';
import 'widgets/event_row.dart';
import 'widgets/reminder_past_dialog.dart';
import 'widgets/reminder_set_dialog.dart';
import 'widgets/reminder_settings_sheet.dart';

/// [_CalendarScreenState._syncReminder]의 결과.
enum _ReminderResult { ok, denied, past }

/// "캘린더" 화면(v7). 거의 흰 바탕 위쪽에서 달을 넘기고, 흰 패널의 월간
/// 격자에서 날짜를 고르면 그날의 일정이 시간순 카드로 아래에 나온다. 일정 추가는
/// 하단 탭 바 위 오른쪽의 "+" 버튼으로 한다.
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

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
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

  /// 달력이 펼쳐진 정도(0=접힘: 점 달력 + 그날 일정 목록, 1=펼침: 날짜 칸 안에
  /// 일정 막대). 끄는 동안은 손가락을 따라 움직이고, 손을 떼면 가까운 쪽(또는
  /// 튕긴 방향)으로 마저 움직인다.
  late final AnimationController _expand = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  /// 이만큼(논리 픽셀) 끌면 끝까지 펼쳐진다.
  static const double _expandDragExtent = 280;

  /// "아래로 끌면…" 안내 말풍선을 본 적 있는지(한 번 펼치거나 닫으면 true).
  static const _hintSeenKey = 'calendar_expand_hint_seen';
  final _prefs = SharedPreferencesAsync();

  /// 안내 말풍선을 손잡이 바로 아래에 붙이는 연결 고리.
  final _hintLink = LayerLink();
  bool _showHint = false;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _expand.dispose();
    super.dispose();
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
    unawaited(_maybeShowHint());
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

  /// 펼친 달력에서 날짜를 누르면 그날을 고르고 접어서 일정 목록을 보여 준다.
  void _onExpandedDaySelected(int day) {
    _onDaySelected(day);
    _settleExpand(0);
  }

  /// 손잡이를 누르면 펼치거나 접는다(끄는 동작을 모르는 학생용).
  void _toggleExpand() => _settleExpand(_expand.value > 0.5 ? 0 : 1);

  /// 캘린더에 처음 들어왔을 때 한 번, 손잡이 아래에 안내 말풍선을 띄우고 달력을
  /// 살짝 내렸다 올려 끌 수 있다는 걸 보여 준다. 말풍선은 잠깐 뒤 사라지며, 한 번
  /// 펼치거나 닫기 전까지는 다음에 들어올 때 다시 뜬다.
  Future<void> _maybeShowHint() async {
    final seen = await _prefs.getBool(_hintSeenKey) ?? false;
    if (seen || !mounted) return;
    setState(() => _showHint = true);
    _hintTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted || _expand.value != 0 || _expand.isAnimating) return;
      _expand
          .animateTo(
            0.15,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOut,
          )
          .then((_) {
            if (!mounted) return;
            _expand.animateTo(
              0,
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeInOut,
            );
          });
      _hintTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showHint = false);
      });
    });
  }

  /// 안내를 다 본 것으로 저장하고 말풍선을 내린다.
  void _markHintSeen() {
    _hintTimer?.cancel();
    if (_showHint) setState(() => _showHint = false);
    unawaited(_prefs.setBool(_hintSeenKey, true));
  }

  void _onPanelDragUpdate(DragUpdateDetails details) {
    _expand.value += (details.primaryDelta ?? 0) / _expandDragExtent;
  }

  void _onPanelDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 300) {
      _settleExpand(1);
    } else if (velocity < -300) {
      _settleExpand(0);
    } else {
      _settleExpand(_expand.value > 0.5 ? 1 : 0);
    }
  }

  /// 남은 거리에 비례한 시간으로 끝까지 펼치거나 접는다.
  void _settleExpand(double target) {
    if (target == 1) _markHintSeen();
    final remaining = (target - _expand.value).abs();
    if (remaining == 0) return;
    _expand.animateTo(
      target,
      duration: _expand.duration! * remaining,
      curve: Curves.easeOutCubic,
    );
  }

  /// 접힌 화면과 펼친 화면을 [_expand] 값에 맞춰 섞어 그린다. 접힌 화면(아래 일정
  /// 목록)은 아래로 살짝 밀리며 사라지고, 펼친 달력은 위에서부터 아래로 드러나며
  /// 나타난다.
  Widget _expandTransition({
    required Widget expanded,
    required Widget collapsed,
  }) {
    return AnimatedBuilder(
      animation: _expand,
      builder: (context, _) {
        final t = _expand.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // 한쪽이 빠졌다 들어와도 서로 자리를 바꿔 잡지 않게 키를 단다.
            if (t < 1)
              IgnorePointer(
                key: const ValueKey('collapsed-layer'),
                ignoring: t > 0.5,
                child: Opacity(
                  opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 40 * t),
                    child: collapsed,
                  ),
                ),
              ),
            if (t > 0)
              IgnorePointer(
                key: const ValueKey('expanded-layer'),
                ignoring: t <= 0.5,
                child: Opacity(
                  opacity: ((t - 0.15) / 0.85).clamp(0.0, 1.0),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: 0.35 + 0.65 * t,
                      child: expanded,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// 달력 맨 아래 가운데의 손잡이(짧은 회색 막대 + 화살표). 접힌 상태에선 ⌄,
  /// 펼친 상태에선 ⌃이고, 누르면 펼치거나 접는다.
  Widget _expandHandle({required bool expanded}) {
    final handle = Pressable(
      key: ValueKey(expanded ? 'expand-handle-up' : 'expand-handle-down'),
      onTap: _toggleExpand,
      child: Container(
        width: 72,
        height: 22,
        // 투명 바탕이라도 손잡이 칸 전체가 눌리도록 색을 깐다.
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: CalendarColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
    return Center(
      child: expanded
          ? handle
          : CompositedTransformTarget(link: _hintLink, child: handle),
    );
  }

  /// 처음 한 번 손잡이 아래에 뜨는 안내 말풍선.
  Widget _hintBubble() {
    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _hintLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        offset: const Offset(0, 4),
        child: Container(
          key: const ValueKey('expand-hint'),
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
          decoration: BoxDecoration(
            color: AppColors.inkNavy,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '아래로 끌면 일정이 달력에 보여요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Pressable.icon(
                onTap: _markHintSeen,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 종 버튼·상세 팝업의 알림 줄. 알림 설정 창을 열고, 저장하면 넣은 "며칠 전"대로
  /// 다시 건다(빈 목록이면 끈다). 시간 정보가 없는 일정(학사일정 등)은 언제 울리는지
  /// 팝업으로 알려준다 — 여러 날 일정은 마감 하루 전·마감일까지 아직 안 지난 것만.
  /// 이미 지난 날짜는 빼고 걸었다고 배너로 알려준다.
  Future<void> _openReminderSettings(CalendarEvent event) async {
    final picked = await showReminderSettingsSheet(context, event: event);
    if (picked == null || !mounted) return;
    final days = picked.days;
    final outcome = await _setReminderDays(event, days, time: picked.time);
    if (outcome.result != _ReminderResult.ok || days.isEmpty || !mounted) {
      return;
    }
    if (event.isAllDay) {
      await showReminderSetDialog(context, dates: outcome.scheduled);
    } else if (outcome.skipped > 0) {
      showTopBanner(
        context,
        title: '지난 알림은 빼고 걸었어요',
        message: '이미 지난 날짜 ${outcome.skipped}개는 울리지 않아요',
        icon: Icons.notifications_paused_rounded,
      );
    }
  }

  /// [event]의 알림 날짜를 [days]로 바꾸고 다시 예약한다. 하나도 못 걸면(권한
  /// 거부·전부 지난 시각) 원래대로 되돌리고, 전부 지났으면 팝업으로 알려준다.
  Future<({_ReminderResult result, List<DateTime> scheduled, int skipped})>
  _setReminderDays(
    CalendarEvent event,
    List<int> days, {
    TimeOfDay? time,
  }) async {
    final previous = List.of(event.reminderDaysBefore);
    final previousTime = event.reminderTime;
    setState(() {
      event.setReminderDaysBefore(days);
      event.reminderTime = time;
    });
    final attemptedAt = event.reminderAt;
    final outcome = await _syncReminder(event);
    if (outcome.result != _ReminderResult.ok && mounted) {
      setState(() {
        event.setReminderDaysBefore(previous);
        event.reminderTime = previousTime;
      });
    }
    await _persist();
    if (outcome.result == _ReminderResult.past &&
        attemptedAt != null &&
        mounted) {
      await showReminderPastDialog(context, attemptedAt: attemptedAt);
    }
    return outcome;
  }

  /// [event]에 걸려 있을 수 있는 알림 예약을 전부 취소한다("며칠 전"마다의 시작일
  /// 알림과, 여러 날 일정의 마감 하루 전·마감일 알림).
  Future<void> _cancelReminders(CalendarEvent event) async {
    for (final suffix in CalendarEvent.allReminderIdSuffixes) {
      await _notifications.cancelReminder('${event.id}$suffix');
    }
  }

  /// [event]의 알림을 폰에 (다시) 예약하거나, 알림이 꺼져 있으면 예약을 취소한다.
  /// 울려야 할 알림([CalendarEvent.reminders]) 중 아직 안 지난 것만 건다 — 하나라도
  /// 걸리면 성공이고, 건 시각들을 [scheduled]로 돌려준다. 전부 지났으면
  /// [_ReminderResult.past], 권한이 없으면 안내 메시지를 띄우고
  /// [_ReminderResult.denied]를 돌려준다. [skipped]는 지나서 건너뛴 "며칠 전"(시작일
  /// 기준 알림)의 수다. 실패하면 호출한 쪽이 알림 상태를 되돌린다.
  Future<({_ReminderResult result, List<DateTime> scheduled, int skipped})>
  _syncReminder(CalendarEvent event) async {
    const none = <DateTime>[];
    final all = event.reminders;
    if (all.isEmpty) {
      await _cancelReminders(event);
      return (result: _ReminderResult.ok, scheduled: none, skipped: 0);
    }

    final granted = await _notifications.requestPermission();
    if (!mounted) {
      return (result: _ReminderResult.denied, scheduled: none, skipped: 0);
    }
    if (!granted) {
      _showMessage('알림을 받으려면 설정에서 알림 권한을 허용해주세요');
      await _cancelReminders(event);
      return (result: _ReminderResult.denied, scheduled: none, skipped: 0);
    }

    final now = DateTime.now();
    final scheduled = <DateTime>[];
    var skipped = 0;
    await _cancelReminders(event);
    for (final reminder in all) {
      if (reminder.at.isBefore(now)) {
        if (reminder.kind == ReminderKind.start) skipped++;
        continue;
      }
      await _notifications.scheduleReminder(
        // "며칠 전"마다, 그리고 마감 하루 전·마감일 알림을 따로 취소할 수 있게
        // 번호를 나눈다.
        eventId: '${event.id}${reminder.idSuffix}',
        title: event.title,
        body: reminder.body,
        scheduledAt: reminder.at,
      );
      scheduled.add(reminder.at);
    }
    return (
      result: scheduled.isEmpty ? _ReminderResult.past : _ReminderResult.ok,
      scheduled: scheduled,
      skipped: skipped,
    );
  }

  /// 일정 카드를 눌렀을 때 — 상세 팝업을 열고, 거기서 고른 동작을 처리한다.
  Future<void> _openEventDetail(CalendarEvent event) async {
    final action = await showEventDetailSheet(
      context,
      event: event,
      onReminderTap: () => _openReminderSettings(event),
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
    if (result != _ReminderResult.ok) saved.setReminderDaysBefore(const []);

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
      return const AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.canvas,
          body: Center(child: CircularProgressIndicator(color: AppColors.blue)),
        ),
      );
    }

    final selectedDay = _selectedDayInFocusedMonth;
    final selectedDate = _selectedDate;
    final dayEvents = _selectedDateEvents;

    // 거의 흰 바탕이라 상태 표시줄 글자를 어둡게 둔다(앱 테마는 아직 어두운 테마).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        extendBody: true,
        // "+"는 하단 탭 바 바로 위 오른쪽에 떠 있다(v7).
        floatingActionButton: _addButton(),
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
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Row(
                  children: [
                    _monthButton(
                      Icons.chevron_left_rounded,
                      _goToPreviousMonth,
                    ),
                    Expanded(
                      child: Text(
                        '${_focusedMonth.year}년 ${_focusedMonth.month}월',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textStrong,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.88,
                        ),
                      ),
                    ),
                    _monthButton(Icons.chevron_right_rounded, _goToNextMonth),
                  ],
                ),
              ),
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  // 패널을 아래로 끌면 달력이 펼쳐지고 위로 끌면 접힌다. 일정
                  // 목록 안에서 끄는 건 목록 스크롤이 먼저 받는다.
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onVerticalDragStart: (_) => _expand.stop(),
                    onVerticalDragUpdate: _onPanelDragUpdate,
                    onVerticalDragEnd: _onPanelDragEnd,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _expandTransition(
                            expanded: Padding(
                              key: const ValueKey('calendar-expanded'),
                              // 하단 탭 바와 "+" 버튼에 마지막 주가
                              // 가리지 않게.
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.paddingOf(context).bottom + 72,
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: CalendarExpandedGrid(
                                      focusedMonth: _focusedMonth,
                                      events: _eventsInFocusedMonth,
                                      selectedDay: selectedDay,
                                      today: DateTime.now(),
                                      onDaySelected: _onExpandedDaySelected,
                                      onEventTap: _openEventDetail,
                                    ),
                                  ),
                                  _expandHandle(expanded: true),
                                ],
                              ),
                            ),
                            collapsed: Column(
                              key: const ValueKey('calendar-collapsed'),
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 달력 격자와 날짜 줄은 고정하고, 아래 일정 목록만
                                // 스크롤된다.
                                CalendarMonthGrid(
                                  focusedMonth: _focusedMonth,
                                  events: _eventsInFocusedMonth,
                                  selectedDay: selectedDay,
                                  today: DateTime.now(),
                                  onDaySelected: _onDaySelected,
                                ),
                                // 손잡이는 원래 달력과 날짜 줄 사이 여백(26)
                                // 안에 넣어 화면 높이가 늘지 않게 한다.
                                _expandHandle(expanded: false),
                                if (selectedDay != null &&
                                    selectedDate != null) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      4,
                                      4,
                                      4,
                                      12,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '${selectedDate.month}월 ${selectedDate.day}일 '
                                          '${weekdayLabelsSunFirst[selectedDate.weekday % 7]}요일',
                                          style: const TextStyle(
                                            color: AppColors.textStrong,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.45,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '일정 ${dayEvents.length}개',
                                          style: const TextStyle(
                                            color: AppColors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
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
                                                color: AppColors.textSub,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          )
                                        : Builder(
                                            builder: (context) =>
                                                ListView.separated(
                                                  // 하단 탭 바(extendBody라 아래 여백에 들어 있다)와
                                                  // "+" 버튼에 마지막 카드가 가리지 않게.
                                                  padding: EdgeInsets.only(
                                                    bottom:
                                                        MediaQuery.paddingOf(
                                                          context,
                                                        ).bottom +
                                                        80,
                                                  ),
                                                  itemCount: dayEvents.length,
                                                  separatorBuilder: (_, _) =>
                                                      const SizedBox(height: 8),
                                                  itemBuilder: (context, index) {
                                                    final event =
                                                        dayEvents[index];
                                                    return EventRow(
                                                      event: event,
                                                      // 종 버튼은 바로 켜고 끄지 않고 알림
                                                      // 설정 창을 연다(사용자 결정, 2026-11-13).
                                                      onReminderToggled: (_) =>
                                                          _openReminderSettings(
                                                            event,
                                                          ),
                                                      onTap: () =>
                                                          _openEventDetail(
                                                            event,
                                                          ),
                                                    );
                                                  },
                                                ),
                                          ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // 처음 한 번 손잡이 아래에 뜨는 안내 말풍선.
                        if (_showHint) _hintBubble(),
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

  /// 일정 추가 버튼(파란 둥근 사각형, 파란 그림자).
  Widget _addButton() {
    return Pressable.icon(
      onTap: _onAddPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.blue.withValues(alpha: 0.28),
              offset: const Offset(0, 6),
              blurRadius: 16,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  /// 달 넘기기 버튼(흰 둥근 사각형, 옅은 그림자).
  Widget _monthButton(IconData icon, VoidCallback onTap) {
    return Pressable.icon(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Icon(icon, size: 22, color: AppColors.textStrong),
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
