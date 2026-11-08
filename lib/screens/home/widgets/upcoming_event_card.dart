import 'package:flutter/material.dart';

import '../../../services/academic_schedule_service.dart';
import '../../../services/service_factory.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/weekday_labels.dart';
import '../../calendar/models/calendar_event.dart';
import '../../calendar/services/calendar_event_storage.dart';
import '../home_colors.dart';
import 'home_mini_card.dart';

/// 홈 카드에 보여줄 일정 하나.
class UpcomingEvent {
  const UpcomingEvent({
    required this.title,
    required this.start,
    required this.end,
    this.startTime,
  });

  final String title;

  /// 날짜만 쓴다(시각은 [startTime]).
  final DateTime start;
  final DateTime end;
  final TimeOfDay? startTime;
}

/// 가장 가까운 일정을 고른다. 내가 만든 일정이 있으면 그중에서, 없으면
/// 학사일정 중에서 고른다(학사일정은 위쪽 배너에도 나오므로 내 일정이 먼저).
/// 이미 끝난 일정은 빼고, 진행 중인 일정도 고를 수 있다.
UpcomingEvent? pickUpcomingEvent({
  required List<CalendarEvent> mine,
  required List<AcademicScheduleItem> academic,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);

  final myUpcoming = [
    for (final e in mine)
      if (e.isUserEvent && !day(e.endDate).isBefore(today))
        UpcomingEvent(
          title: e.title,
          start: day(e.startDate),
          end: day(e.endDate),
          startTime: e.startTime,
        ),
  ];
  final pool = myUpcoming.isNotEmpty
      ? myUpcoming
      : [
          for (final e in academic)
            if (!day(e.end).isBefore(today))
              UpcomingEvent(
                title: e.title,
                start: day(e.start),
                end: day(e.end),
              ),
        ];
  if (pool.isEmpty) return null;

  int minutes(UpcomingEvent e) =>
      (e.startTime?.hour ?? 0) * 60 + (e.startTime?.minute ?? 0);
  pool.sort((a, b) {
    final byDate = a.start.compareTo(b.start);
    return byDate != 0 ? byDate : minutes(a).compareTo(minutes(b));
  });
  return pool.first;
}

/// 카드 아래 줄: "오늘 14:00", "진행 중 · ~11.12", "D-3 · 11.11(수)".
String upcomingEventFooter(UpcomingEvent e, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  String two(int n) => n.toString().padLeft(2, '0');
  String md(DateTime d) => '${two(d.month)}.${two(d.day)}';

  if (e.start.isAfter(today)) {
    final days = e.start.difference(today).inDays;
    final weekday = weekdayLabelsMonFirst[e.start.weekday - 1];
    return 'D-$days · ${md(e.start)}($weekday)';
  }
  if (e.start == today) {
    final t = e.startTime;
    return t == null ? '오늘' : '오늘 ${two(t.hour)}:${two(t.minute)}';
  }
  return '진행 중 · ~${md(e.end)}';
}

/// 남색 "다가오는 일정" 카드(셔틀버스 카드 자리). 내 일정 → 학사일정 순으로
/// 가장 가까운 일정을 보여주고, 없으면 일정을 추가해 보라고 안내한다.
///
/// 학사일정은 이번 달·다음 달을 읽는다. 학사일정 서비스는 받은 목록을 하루 동안
/// 기기에 저장하므로, 위쪽 배너가 이미 받았으면 학교에 다시 묻지 않는다.
class UpcomingEventCard extends StatefulWidget {
  const UpcomingEventCard({
    super.key,
    required this.now,
    required this.onTap,
    this.storage,
    this.schedule,
  });

  final DateTime now;
  final VoidCallback onTap;

  /// 테스트에서 바꿔 끼우려고 주입할 수 있다.
  final CalendarEventStorage? storage;
  final AcademicScheduleServiceBase? schedule;

  @override
  State<UpcomingEventCard> createState() => _UpcomingEventCardState();
}

class _UpcomingEventCardState extends State<UpcomingEventCard> {
  UpcomingEvent? _event;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var mine = <CalendarEvent>[];
    try {
      mine = await (widget.storage ?? CalendarEventStorage()).loadAll();
    } catch (e) {
      debugPrint('[Home] 내 일정 읽기 실패: $e');
    }

    final academic = <AcademicScheduleItem>[];
    if (!mine.any((e) => e.isUserEvent)) {
      final schedule = widget.schedule ?? ServiceFactory.academicSchedule();
      final now = widget.now;
      final next = DateTime(now.year, now.month + 1);
      for (final (y, m) in [(now.year, now.month), (next.year, next.month)]) {
        try {
          academic.addAll(await schedule.fetchMonth(y, m));
        } catch (e) {
          debugPrint('[Home] $y-$m 학사일정 읽기 실패: $e');
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _event = pickUpcomingEvent(
        mine: mine,
        academic: academic,
        now: widget.now,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    return HomeMiniCard(
      icon: Icons.event_rounded,
      iconColor: AppColors.blue,
      label: '다가오는 일정',
      labelColor: HomeV7Colors.onNavySub,
      title: event?.title ?? '예정된 일정이\n없어요',
      titleColor: Colors.white,
      footer: Text(
        event == null
            ? '캘린더에서 일정을 추가해 보세요'
            : upcomingEventFooter(event, widget.now),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: HomeV7Colors.onNavySub,
          fontSize: 12,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: AppColors.inkNavy,
      onTap: widget.onTap,
    );
  }
}
