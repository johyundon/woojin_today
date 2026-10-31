import 'package:flutter/material.dart';

import '../../../services/academic_schedule_service.dart';
import '../models/calendar_event.dart';

/// [mergeAcademicSchedule]의 결과.
class AcademicScheduleMerge {
  const AcademicScheduleMerge({
    required this.events,
    required this.removed,
    required this.changed,
  });

  /// 합친 뒤의 전체 일정.
  final List<CalendarEvent> events;

  /// 빠진 일정(샘플, 학교에서 사라진 일정). 걸려 있던 알림을 취소해야 한다.
  final List<CalendarEvent> removed;

  /// 종료일이 바뀌었고 알림이 걸려 있는 일정. 알림을 다시 걸어야 한다(마감일 알림).
  final List<CalendarEvent> changed;
}

/// 저장된 일정 [current]에 [year]년 [month]월 학사일정 [fetched]를 합친다.
///
/// - 직접 만든 일정(`local-`)은 건드리지 않는다.
/// - 예전 샘플 일정(`sample-`)은 실제 일정으로 바꾸기 위해 뺀다.
/// - 그 달에 걸친 학교 일정(`school-`) 중 [fetched]에 없는 것은 뺀다.
/// - 같은 id(시작일+제목)가 이미 있으면 그 일정을 그대로 둬서 알림 설정이 이어진다.
///   종료일만 바뀌었으면 새 날짜로 바꾸고 알림 설정은 옮긴다.
/// - 새 일정은 제목 낱말로 색을 정해([academicScheduleColor]) 추가한다.
AcademicScheduleMerge mergeAcademicSchedule({
  required List<CalendarEvent> current,
  required List<AcademicScheduleItem> fetched,
  required int year,
  required int month,
}) {
  final monthStart = DateTime(year, month, 1);
  final monthEnd = DateTime(year, month + 1, 0);
  bool inMonth(CalendarEvent e) =>
      !e.endDate.isBefore(monthStart) && !e.startDate.isAfter(monthEnd);

  final byId = {for (final item in fetched) item.id: item};
  final kept = <String>{};
  final events = <CalendarEvent>[];
  final removed = <CalendarEvent>[];
  final changed = <CalendarEvent>[];

  for (final e in current) {
    if (e.id.startsWith('sample-')) {
      removed.add(e);
      continue;
    }
    if (!e.id.startsWith('school-')) {
      events.add(e);
      continue;
    }
    final item = byId[e.id];
    if (item == null) {
      if (inMonth(e)) {
        removed.add(e);
      } else {
        events.add(e);
      }
      continue;
    }
    kept.add(e.id);
    if (_sameDay(item.end, e.endDate)) {
      events.add(e);
      continue;
    }
    final updated = _fromItem(item)..reminderOffset = e.reminderOffset;
    events.add(updated);
    if (updated.hasReminder) changed.add(updated);
  }

  for (final item in fetched) {
    if (kept.add(item.id)) events.add(_fromItem(item));
  }
  return AcademicScheduleMerge(
    events: events,
    removed: removed,
    changed: changed,
  );
}

/// 학사일정 막대 색. 분류 정보가 없어 제목 낱말로 나눈다(사용자 결정, 2026-10-31):
/// 시험 → 주황, 수강·등록 → 파랑, 방학·휴업 → 초록, 나머지 → 보라.
Color academicScheduleColor(String title) {
  if (title.contains('시험')) return calendarEventPalette[2];
  if (title.contains('수강') || title.contains('등록')) {
    return calendarEventPalette[0];
  }
  if (title.contains('방학') || title.contains('휴업')) {
    return calendarEventPalette[3];
  }
  return calendarEventPalette[1];
}

CalendarEvent _fromItem(AcademicScheduleItem item) => CalendarEvent(
  id: item.id,
  startDate: item.start,
  endDate: item.end,
  label: '학사일정',
  title: item.title,
  color: academicScheduleColor(item.title),
);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
