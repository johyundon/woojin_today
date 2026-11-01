part of 'timetable_screen.dart';

/// "강의시간 알림" 토글과 실제 로컬 알림 예약을 맡는다.
///
/// 켜져 있는 동안은 그리드의 과목([_confirmedCourses])이 바뀔 때마다 강의시간
/// 알림을 전부 취소하고 지금 과목으로 다시 예약한다(수업 10분 전, 매주 반복).
/// 예약은 OS가 들고 있어서 앱을 꺼도 계속 울린다.
mixin TimetableReminderMixin on TimetableSessionMixin {
  late final NotificationService _notificationService =
      widget.notificationService ?? NotificationService.instance;
  late final ClassReminderSettings _reminderSettings =
      widget.classReminderSettings ?? ClassReminderSettings();

  bool _notificationsEnabled = false;

  /// 취소·예약을 순서대로 하나씩 처리하기 위한 대기열. 과목이 연달아 바뀌어도
  /// 앞의 예약이 끝난 뒤 다음 예약을 하므로 결과가 섞이지 않는다.
  Future<void> _reminderQueue = Future.value();

  Future<void> _loadReminderSetting() async {
    final enabled = await _reminderSettings.isEnabled();
    if (!mounted || !enabled) return;
    setState(() => _notificationsEnabled = true);
    // 설정을 읽는 사이에 시간표가 먼저 채워졌으면 그 과목으로 맞춘다.
    if (_confirmedCourses.isNotEmpty) _syncClassReminders();
  }

  @override
  void _onConfirmedCoursesChanged() {
    if (_notificationsEnabled) _syncClassReminders();
  }

  Future<void> _onNotificationsToggled(bool turnOn) async {
    if (!turnOn) {
      setState(() => _notificationsEnabled = false);
      _syncClassReminders();
      await _reminderSettings.setEnabled(false);
      if (!mounted) return;
      showTopBanner(
        context,
        icon: Icons.notifications_off_rounded,
        title: '강의시간 알림을 껐어요',
        message: '예약해 둔 수업 알림을 모두 지웠어요.',
      );
      return;
    }

    final granted = await _notificationService.requestPermission();
    if (!mounted) return;
    if (!granted) {
      showTopBanner(
        context,
        icon: Icons.notifications_paused_rounded,
        title: '알림 권한이 꺼져 있어요',
        message: '설정에서 알림 권한을 허용해주세요.',
      );
      return;
    }

    setState(() => _notificationsEnabled = true);
    _syncClassReminders();
    await _reminderSettings.setEnabled(true);
    if (!mounted) return;
    showTopBanner(
      context,
      icon: Icons.notifications_active_rounded,
      title: '강의시간 알림을 켰어요',
      message: _confirmedCourses.isEmpty
          ? '시간표에 과목을 넣으면 수업 $classReminderLeadMinutes분 전에 알려드릴게요.'
          : '수업 시작 $classReminderLeadMinutes분 전에 알려드릴게요.',
    );
  }

  /// 강의시간 알림을 전부 취소하고, 켜져 있으면 지금 과목으로 다시 예약한다.
  void _syncClassReminders() {
    final enabled = _notificationsEnabled;
    final courses = _confirmedCourses;
    final now = _now();
    _reminderQueue = _reminderQueue.then((_) async {
      try {
        await _notificationService.cancelAllClassReminders();
        if (!enabled) return;
        for (final r in buildClassReminders(courses)) {
          await _notificationService.scheduleWeeklyClassReminder(
            eventId: r.id,
            title: r.title,
            body: r.body,
            firstAt: nextWeeklyOccurrence(now, r.weekday, r.minutesOfDay),
          );
        }
      } catch (e) {
        debugPrint('[ClassReminder] 알림 예약 실패: $e');
      }
    });
  }
}
