import 'package:daejin_app/screens/calendar/models/calendar_event.dart';
import 'package:daejin_app/screens/calendar/services/academic_schedule_merge.dart';
import 'package:daejin_app/services/academic_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

AcademicScheduleItem _item(DateTime start, DateTime end, String title) =>
    AcademicScheduleItem(start: start, end: end, title: title);

CalendarEvent _event(
  String id, {
  DateTime? start,
  DateTime? end,
  String title = 'x',
  ReminderOffset? reminder,
}) => CalendarEvent(
  id: id,
  startDate: start ?? DateTime(2026, 10, 1),
  endDate: end ?? start ?? DateTime(2026, 10, 1),
  label: '학사일정',
  title: title,
  color: Colors.blue,
  reminderOffset: reminder,
);

void main() {
  final midterm = _item(DateTime(2026, 10, 20), DateTime(2026, 10, 26), '중간시험');
  final survey = _item(
    DateTime(2026, 10, 20),
    DateTime(2026, 11, 1),
    '중간 수업평가',
  );

  test('샘플은 빼고, 직접 만든 일정은 그대로 두고, 새 학사일정은 추가한다', () {
    final mine = _event('local-1', title: '팀플');
    final r = mergeAcademicSchedule(
      current: [_event('sample-1'), mine],
      fetched: [midterm],
      year: 2026,
      month: 10,
    );

    expect(r.events.map((e) => e.id), ['local-1', midterm.id]);
    expect(identical(r.events.first, mine), isTrue);
    expect(r.removed.single.id, 'sample-1');
    expect(r.events.last.label, '학사일정');
    expect(r.events.last.color, academicScheduleColor('중간시험'));
  });

  test('이미 있는 학사일정은 그 일정을 그대로 둬서 알림 설정이 이어진다', () {
    final saved = _event(
      midterm.id,
      start: midterm.start,
      end: midterm.end,
      title: '중간시험',
      reminder: ReminderOffset.atStart,
    );
    final r = mergeAcademicSchedule(
      current: [saved],
      fetched: [midterm],
      year: 2026,
      month: 10,
    );

    expect(r.events.length, 1);
    expect(identical(r.events.single, saved), isTrue);
    expect(r.removed, isEmpty);
    expect(r.changed, isEmpty);
  });

  test('종료일이 바뀌면 새 날짜로 바꾸고, 알림이 있으면 다시 걸 목록에 넣는다', () {
    final saved = _event(
      midterm.id,
      start: midterm.start,
      end: DateTime(2026, 10, 25),
      title: '중간시험',
      reminder: ReminderOffset.atStart,
    );
    final r = mergeAcademicSchedule(
      current: [saved],
      fetched: [midterm],
      year: 2026,
      month: 10,
    );

    expect(r.events.single.endDate, DateTime(2026, 10, 26));
    expect(r.events.single.reminderOffset, ReminderOffset.atStart);
    expect(r.changed.single.id, midterm.id);
  });

  test('그 달의 학사일정 중 학교에서 사라진 것만 빼고, 다른 달 일정은 남긴다', () {
    final gone = _event('school-20261005-없어진 일정', start: DateTime(2026, 10, 5));
    final otherMonth = _event(
      'school-20261201-12월 일정',
      start: DateTime(2026, 12, 1),
    );
    final r = mergeAcademicSchedule(
      current: [gone, otherMonth],
      fetched: [midterm],
      year: 2026,
      month: 10,
    );

    expect(r.removed.single.id, gone.id);
    expect(r.events.map((e) => e.id), [otherMonth.id, midterm.id]);
  });

  test('달을 넘는 일정은 다음 달 응답에서 다시 받아도 하나만 남는다', () {
    final october = mergeAcademicSchedule(
      current: const [],
      fetched: [midterm, survey],
      year: 2026,
      month: 10,
    );
    final november = mergeAcademicSchedule(
      current: october.events,
      fetched: [survey],
      year: 2026,
      month: 11,
    );

    expect(november.events.where((e) => e.id == survey.id).length, 1);
    expect(november.events.length, 2);
    expect(november.removed, isEmpty);
  });

  test('제목 낱말로 색을 나눈다', () {
    expect(academicScheduleColor('중간시험'), calendarEventPalette[2]);
    expect(academicScheduleColor('겨울 계절학기 수강 신청'), calendarEventPalette[0]);
    expect(academicScheduleColor('재학생 등록 기간'), calendarEventPalette[0]);
    expect(academicScheduleColor('겨울방학'), calendarEventPalette[3]);
    expect(academicScheduleColor('개교기념일 휴업'), calendarEventPalette[3]);
    expect(academicScheduleColor('수업일수 1/3선'), calendarEventPalette[1]);
  });
}
