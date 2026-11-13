// 일정 데이터에 새로 생긴 필드(시작/끝 시간, 장소, "N분 전" 알림)와, 옛 저장분이
// 그대로 열리는지(하위 호환) 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/calendar/models/calendar_event.dart';

CalendarEvent _event({
  TimeOfDay? startTime,
  TimeOfDay? endTime,
  String? location,
  List<int> days = const [],
  DateTime? startDate,
}) {
  final date = startDate ?? DateTime(2026, 10, 14);
  return CalendarEvent(
    id: 'e1',
    startDate: date,
    endDate: date,
    label: '내 일정',
    title: '팀플 회의',
    color: Colors.blue,
    startTime: startTime,
    endTime: endTime,
    location: location,
    reminderDaysBefore: days,
  );
}

void main() {
  group('reminderAt', () {
    test('알림이 꺼져 있으면 null', () {
      expect(
        _event(startTime: const TimeOfDay(hour: 15, minute: 0)).reminderAt,
        isNull,
      );
    });

    test('며칠 전마다 그날의 일정 시각에 울리고, reminderAt은 가장 가까운 것이다', () {
      final event = _event(
        startTime: const TimeOfDay(hour: 15, minute: 0),
        days: const [0, 14, 1],
      );
      expect(event.reminderDaysBefore, [14, 1, 0]); // 큰 수부터 정렬
      expect(event.reminderAts, [
        DateTime(2026, 9, 30, 15, 0),
        DateTime(2026, 10, 13, 15, 0),
        DateTime(2026, 10, 14, 15, 0),
      ]);
      expect(event.reminderAt, DateTime(2026, 10, 14, 15, 0));
      expect(event.reminders.map((r) => r.body), [
        '내 일정 · 2주 전',
        '내 일정 · 1일 전',
        '내 일정 · 정각',
      ]);
    });

    test('종일 일정은 오전 9시에 울리고 0일 전은 "당일"이다', () {
      final event = _event(days: const [7, 0]);
      expect(event.isAllDay, isTrue);
      expect(event.reminderAts, [
        DateTime(2026, 10, 7, 9, 0),
        DateTime(2026, 10, 14, 9, 0),
      ]);
      expect(event.reminders.last.body, '내 일정 · 당일');
    });

    test('날짜 경계를 넘는 하루 전 알림도 맞게 계산한다', () {
      final event = _event(
        startDate: DateTime(2026, 11, 1),
        startTime: const TimeOfDay(hour: 8, minute: 0),
        days: const [1],
      );
      expect(event.reminderAt, DateTime(2026, 10, 31, 8, 0));
    });

    test('범위(4주 전~시작 60일 뒤) 밖과 중복은 버린다', () {
      final event = _event(days: const [29, -61, 28, 3, 3, -2]);
      expect(event.reminderDaysBefore, [28, 3, -2]);
    });

    test('날짜마다 예약 번호가 다르고, 취소 목록에 모두 들어 있다', () {
      final event = _event(days: const [28, 7, 0]);
      final suffixes = event.reminders.map((r) => r.idSuffix).toList();
      expect(suffixes, ['#d28', '#d7', '']);
      expect(CalendarEvent.allReminderIdSuffixes, containsAll(suffixes));
      expect(
        CalendarEvent.allReminderIdSuffixes,
        containsAll(['#before', '#end']),
      );
    });
  });

  group('reminders (여러 날 일정)', () {
    CalendarEvent event({
      String id = 'sample-1',
      required DateTime start,
      required DateTime end,
      String title = '왕방축제',
      List<int> days = const [0],
    }) => CalendarEvent(
      id: id,
      startDate: start,
      endDate: end,
      label: '학사일정',
      title: title,
      color: Colors.purple,
      reminderDaysBefore: days,
    );

    test('11/1~11/30 신청 기간은 시작·마감 하루 전·마감일 오전 9시, 세 번이다', () {
      final reminders = event(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30),
        title: '2026학년도 겨울계절학기 수강신청',
      ).reminders;

      expect(reminders.map((r) => r.at), [
        DateTime(2026, 11, 1, 9, 0),
        DateTime(2026, 11, 29, 9, 0),
        DateTime(2026, 11, 30, 9, 0),
      ]);
      expect(reminders.map((r) => r.kind), [
        ReminderKind.start,
        ReminderKind.dayBeforeEnd,
        ReminderKind.end,
      ]);
      expect(reminders.map((r) => r.body), [
        '오늘부터 시작 · 11월 30일까지',
        '내일 마감 · 11월 30일',
        '오늘 마감',
      ]);
    });

    test('신청·납부 같은 말이 없으면 "마감" 대신 "끝나요"라고 한다', () {
      final reminders = event(
        start: DateTime(2026, 12, 21),
        end: DateTime(2027, 2, 28),
        title: '동계방학',
      ).reminders;

      expect(reminders.map((r) => r.body), [
        '오늘부터 시작 · 2월 28일까지',
        '내일 끝나요 · 2월 28일',
        '오늘 끝나요',
      ]);
      // 달·해가 바뀌어도 하루 전은 정확히 그 전날이다.
      expect(reminders[1].at, DateTime(2027, 2, 27, 9, 0));
    });

    test('2일짜리는 하루 전이 시작일과 겹쳐서 시작·마감 두 번이다', () {
      final reminders = event(
        start: DateTime(2026, 10, 14),
        end: DateTime(2026, 10, 15),
      ).reminders;

      expect(reminders.map((r) => r.at), [
        DateTime(2026, 10, 14, 9, 0),
        DateTime(2026, 10, 15, 9, 0),
      ]);
    });

    test('3일짜리부터 하루 전 알림이 생긴다', () {
      final reminders = event(
        start: DateTime(2026, 10, 14),
        end: DateTime(2026, 10, 16),
      ).reminders;

      expect(reminders.map((r) => r.kind), ReminderKind.values);
    });

    test('며칠 전 알림은 시작일 기준으로 더해지고 마감 알림은 그대로다', () {
      final reminders = event(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30),
        title: '2026학년도 겨울계절학기 수강신청',
        days: const [14, 7, 0],
      ).reminders;

      expect(reminders.map((r) => r.at), [
        DateTime(2026, 10, 18, 9, 0),
        DateTime(2026, 10, 25, 9, 0),
        DateTime(2026, 11, 1, 9, 0),
        DateTime(2026, 11, 29, 9, 0),
        DateTime(2026, 11, 30, 9, 0),
      ]);
      expect(reminders.first.body, '14일 뒤 시작 · 11월 1일 ~ 11월 30일');
      final suffixes = reminders.map((r) => r.idSuffix).toList();
      expect(suffixes.toSet().length, suffixes.length);
    });

    test('진행 중인 날도 고를 수 있고, 마감 전날·마감일과 겹치면 한 번만 울린다', () {
      final reminders = event(
        start: DateTime(2026, 11, 20),
        end: DateTime(2026, 11, 26),
        title: '2027학년도 학생회 총선거',
        // 11/23(진행 중), 11/25(마감 전날과 겹침), 11/26(마감일과 겹침)
        days: const [-3, -5, -6],
      ).reminders;

      expect(reminders.map((r) => r.at), [
        DateTime(2026, 11, 23, 9, 0),
        DateTime(2026, 11, 25, 9, 0),
        DateTime(2026, 11, 26, 9, 0),
      ]);
      expect(reminders.first.body, '진행 중 · 11월 26일까지');
      expect(reminders.first.idSuffix, '#d-3');
      expect(CalendarEvent.allReminderIdSuffixes, contains('#d-3'));
      expect(reminderDaysLabel(-3, allDay: true), '시작 3일 뒤');
    });

    test('내가 만든 일정은 여러 날이어도 시작일 한 번이고 문구도 그대로다', () {
      final reminders = event(
        id: 'local-1',
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30),
      ).reminders;

      expect(reminders.single.at, DateTime(2026, 11, 1, 9, 0));
      expect(reminders.single.body, '학사일정 · 당일');
    });

    test('하루짜리 학사일정은 한 번이고, 알림이 꺼져 있으면 없다', () {
      final single = event(
        id: 'sample-2',
        start: DateTime(2026, 10, 14),
        end: DateTime(2026, 10, 14),
        title: '수강정정',
      );
      expect(single.reminderAts, [DateTime(2026, 10, 14, 9, 0)]);
      expect(single.reminders.single.kind, ReminderKind.start);
      expect(
        event(
          start: DateTime(2026, 11, 1),
          end: DateTime(2026, 11, 30),
          days: const [],
        ).reminders,
        isEmpty,
      );
    });
  });

  group('JSON 저장/불러오기', () {
    test('새 필드가 그대로 왕복된다', () {
      final original = _event(
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 30),
        location: '도서관 3층',
        days: const [7, 0],
      );
      final restored = CalendarEvent.fromJson(original.toJson());

      expect(restored.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(restored.endTime, const TimeOfDay(hour: 16, minute: 30));
      expect(restored.location, '도서관 3층');
      expect(restored.reminderDaysBefore, [7, 0]);
      expect(restored.isAllDay, isFalse);
    });

    Map<String, dynamic> legacy({int? hour, int? minute}) => {
      'id': 'old-1',
      'startDate': '2026-10-14T00:00:00.000',
      'endDate': '2026-10-15T00:00:00.000',
      'label': '학사일정',
      'title': '왕방축제',
      'color': 0xFF8B5CF6,
      'reminderHour': hour,
      'reminderMinute': minute,
    };

    test('알림이 없던 옛 저장분은 종일, 장소 없음, 알림 없음으로 열린다', () {
      final restored = CalendarEvent.fromJson(legacy());
      expect(restored.isAllDay, isTrue);
      expect(restored.location, isNull);
      expect(restored.reminderDaysBefore, isEmpty);
      expect(restored.hasReminder, isFalse);
    });

    test('옛 알림 시각은 같은 시각에 울리도록 변환된다(9시 아니면 그 시각이 시작 시각)', () {
      final restored = CalendarEvent.fromJson(legacy(hour: 9, minute: 30));
      expect(restored.reminderDaysBefore, [0]);
      expect(restored.startTime, const TimeOfDay(hour: 9, minute: 30));
      expect(restored.reminderAt, DateTime(2026, 10, 14, 9, 30));
    });

    test('옛 알림 시각이 오전 9시면 종일 일정의 "정각"이 된다', () {
      final restored = CalendarEvent.fromJson(legacy(hour: 9, minute: 0));
      expect(restored.isAllDay, isTrue);
      expect(restored.reminderDaysBefore, [0]);
      expect(restored.reminderAt, DateTime(2026, 10, 14, 9, 0));
    });

    test('시점 하나(reminderOffset)를 저장하던 이전 형식은 며칠 전으로 옮긴다', () {
      Map<String, dynamic> old(String? name) => _event().toJson()
        ..remove('reminderDaysBefore')
        ..['reminderOffset'] = name;
      List<int> days(String? name) =>
          CalendarEvent.fromJson(old(name)).reminderDaysBefore;

      expect(days('oneDay'), [1]);
      expect(days('atStart'), [0]);
      // 일 단위로 나타낼 수 없어 당일(정각)로 옮긴다.
      expect(days('tenMinutes'), [0]);
      expect(days('oneHour'), [0]);
      expect(days(null), isEmpty);
      expect(days('unknown'), isEmpty);
    });
  });
}
