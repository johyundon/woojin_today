// 일정 데이터에 새로 생긴 필드(시작/끝 시간, 장소, "N분 전" 알림)와, 옛 저장분이
// 그대로 열리는지(하위 호환) 확인한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/calendar/models/calendar_event.dart';

CalendarEvent _event({
  TimeOfDay? startTime,
  TimeOfDay? endTime,
  String? location,
  ReminderOffset? reminderOffset,
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
    reminderOffset: reminderOffset,
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

    test('정각/10분 전/1시간 전/하루 전을 시작 시각에서 거꾸로 계산한다', () {
      const start = TimeOfDay(hour: 15, minute: 0);
      DateTime? at(ReminderOffset o) =>
          _event(startTime: start, reminderOffset: o).reminderAt;

      expect(at(ReminderOffset.atStart), DateTime(2026, 10, 14, 15, 0));
      expect(at(ReminderOffset.tenMinutes), DateTime(2026, 10, 14, 14, 50));
      expect(at(ReminderOffset.oneHour), DateTime(2026, 10, 14, 14, 0));
      expect(at(ReminderOffset.oneDay), DateTime(2026, 10, 13, 15, 0));
    });

    test('종일 일정은 당일 오전 9시를 시작으로 본다', () {
      final event = _event(reminderOffset: ReminderOffset.tenMinutes);
      expect(event.isAllDay, isTrue);
      expect(event.reminderAt, DateTime(2026, 10, 14, 8, 50));
    });

    test('날짜 경계를 넘는 하루 전 알림도 맞게 계산한다', () {
      final event = _event(
        startDate: DateTime(2026, 11, 1),
        startTime: const TimeOfDay(hour: 8, minute: 0),
        reminderOffset: ReminderOffset.oneDay,
      );
      expect(event.reminderAt, DateTime(2026, 10, 31, 8, 0));
    });
  });

  group('reminders (여러 날 일정)', () {
    CalendarEvent event({
      String id = 'sample-1',
      required DateTime start,
      required DateTime end,
      String title = '왕방축제',
      ReminderOffset? offset = ReminderOffset.atStart,
    }) => CalendarEvent(
      id: id,
      startDate: start,
      endDate: end,
      label: '학사일정',
      title: title,
      color: Colors.purple,
      reminderOffset: offset,
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

    test('"10분 전"이면 모든 알림이 그만큼 앞당겨진다', () {
      final reminders = event(
        start: DateTime(2026, 10, 14),
        end: DateTime(2026, 10, 16),
        offset: ReminderOffset.tenMinutes,
      ).reminders;

      expect(reminders.map((r) => r.at), [
        DateTime(2026, 10, 14, 8, 50),
        DateTime(2026, 10, 15, 8, 50),
        DateTime(2026, 10, 16, 8, 50),
      ]);
    });

    test('내가 만든 일정은 여러 날이어도 시작일 한 번이고 문구도 그대로다', () {
      final reminders = event(
        id: 'local-1',
        start: DateTime(2026, 11, 1),
        end: DateTime(2026, 11, 30),
      ).reminders;

      expect(reminders.single.at, DateTime(2026, 11, 1, 9, 0));
      expect(reminders.single.body, '학사일정 · 정각');
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
          offset: null,
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
        reminderOffset: ReminderOffset.tenMinutes,
      );
      final restored = CalendarEvent.fromJson(original.toJson());

      expect(restored.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(restored.endTime, const TimeOfDay(hour: 16, minute: 30));
      expect(restored.location, '도서관 3층');
      expect(restored.reminderOffset, ReminderOffset.tenMinutes);
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
      expect(restored.reminderOffset, isNull);
      expect(restored.hasReminder, isFalse);
    });

    test('옛 알림 시각은 같은 시각에 울리도록 변환된다(9시 아니면 그 시각이 시작 시각)', () {
      final restored = CalendarEvent.fromJson(legacy(hour: 9, minute: 30));
      expect(restored.reminderOffset, ReminderOffset.atStart);
      expect(restored.startTime, const TimeOfDay(hour: 9, minute: 30));
      expect(restored.reminderAt, DateTime(2026, 10, 14, 9, 30));
    });

    test('옛 알림 시각이 오전 9시면 종일 일정의 "정각"이 된다', () {
      final restored = CalendarEvent.fromJson(legacy(hour: 9, minute: 0));
      expect(restored.isAllDay, isTrue);
      expect(restored.reminderOffset, ReminderOffset.atStart);
      expect(restored.reminderAt, DateTime(2026, 10, 14, 9, 0));
    });

    test('모르는 알림 방식 이름은 null로 읽는다', () {
      final json = _event().toJson()..['reminderOffset'] = 'unknown';
      expect(CalendarEvent.fromJson(json).reminderOffset, isNull);
    });
  });
}
