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

    test('며칠 전마다 그날 오전 9시(기본)에 울리고, reminderAt은 가장 가까운 것이다', () {
      // 일정 시각(15:00)과 상관없이 기본 알림 시각은 오전 9시다.
      final event = _event(
        startTime: const TimeOfDay(hour: 15, minute: 0),
        days: const [0, 14, 1],
      );
      expect(event.reminderDaysBefore, [14, 1, 0]); // 큰 수부터 정렬
      expect(event.reminderAts, [
        DateTime(2026, 9, 30, 9, 0),
        DateTime(2026, 10, 13, 9, 0),
        DateTime(2026, 10, 14, 9, 0),
      ]);
      expect(event.reminderAt, DateTime(2026, 10, 14, 9, 0));
      expect(event.reminders.map((r) => r.body), [
        '내 일정 · 2주 전',
        '내 일정 · 1일 전',
        '내 일정 · 당일',
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
      final event = _event(startDate: DateTime(2026, 11, 1), days: const [1])
        ..reminderTime = const TimeOfDay(hour: 8, minute: 0);
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

    test('여러 날 학사일정도 고른 날에만 울리고, 마감 알림은 따로 걸지 않는다', () {
      final reminders = event(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30),
        title: '2026학년도 겨울계절학기 수강신청',
        days: const [14, 0, -17],
      ).reminders;

      expect(reminders.map((r) => r.at), [
        DateTime(2026, 10, 18, 9, 0),
        DateTime(2026, 11, 1, 9, 0),
        DateTime(2026, 11, 18, 9, 0),
      ]);
      expect(reminders.map((r) => r.kind).toSet(), {ReminderKind.start});
      expect(reminders.map((r) => r.body), [
        '14일 뒤 시작 · 11월 1일 ~ 11월 30일',
        '오늘부터 시작 · 11월 30일까지',
        '진행 중 · 11월 30일까지',
      ]);
      expect(reminders.last.idSuffix, '#d-17');
      expect(CalendarEvent.allReminderIdSuffixes, contains('#d-17'));
      // 예전 버전이 건 마감 알림도 취소할 수 있게 번호는 남아 있다.
      expect(
        CalendarEvent.allReminderIdSuffixes,
        containsAll(['#before', '#end']),
      );
    });

    test('화면에 보이는 이름: 기본 줄은 며칠 전, 직접 고른 날은 날짜', () {
      final e = event(
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30),
      );
      expect(e.reminderDayLabel(0), '시작일');
      expect(e.reminderDayLabel(14), '2주 전');
      expect(e.reminderDayLabel(-17), '11월 18일');
      expect(e.reminderDayLabel(5), '10월 27일');
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

    test('알림 시간을 정하면 고른 날 모두 그 시각에 울리고, 저장/불러오기도 된다', () {
      final event = _event(days: const [1, 0])
        ..reminderTime = const TimeOfDay(hour: 21, minute: 30);
      expect(event.reminderAts, [
        DateTime(2026, 10, 13, 21, 30),
        DateTime(2026, 10, 14, 21, 30),
      ]);

      final restored = CalendarEvent.fromJson(event.toJson());
      expect(restored.reminderTime, const TimeOfDay(hour: 21, minute: 30));
      // 옛 형식 키(reminderHour)로 잘못 읽혀 시작 시각이 바뀌지 않는다.
      expect(restored.startTime, isNull);
      expect(restored.reminderDaysBefore, [1, 0]);

      // 정하지 않으면 종일 일정은 오전 9시(기본).
      expect(_event(days: const [0]).reminderAts, [
        DateTime(2026, 10, 14, 9, 0),
      ]);
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
      expect(restored.reminderTime, const TimeOfDay(hour: 9, minute: 30));
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
