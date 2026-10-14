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

  group('reminderAts (여러 날 일정)', () {
    CalendarEvent multiDay({required String id, ReminderOffset? offset}) =>
        CalendarEvent(
          id: id,
          startDate: DateTime(2026, 10, 14),
          endDate: DateTime(2026, 10, 15),
          label: '학사일정',
          title: '왕방축제',
          color: Colors.purple,
          reminderOffset: offset,
        );

    test('여러 날 학사일정은 시작일과 마감일 오전 9시, 두 번이다', () {
      final event = multiDay(id: 'sample-1', offset: ReminderOffset.atStart);
      expect(event.isMultiDay, isTrue);
      expect(event.reminderAts, [
        DateTime(2026, 10, 14, 9, 0),
        DateTime(2026, 10, 15, 9, 0),
      ]);
    });

    test('"10분 전"이면 두 알림 모두 그만큼 앞당겨진다', () {
      final event = multiDay(id: 'sample-1', offset: ReminderOffset.tenMinutes);
      expect(event.reminderAts, [
        DateTime(2026, 10, 14, 8, 50),
        DateTime(2026, 10, 15, 8, 50),
      ]);
    });

    test('내가 만든 일정은 여러 날이어도 시작일 한 번만이다', () {
      final event = multiDay(id: 'local-1', offset: ReminderOffset.atStart);
      expect(event.reminderAts, [DateTime(2026, 10, 14, 9, 0)]);
    });

    test('하루짜리 학사일정은 한 번이고, 알림이 꺼져 있으면 없다', () {
      final single = CalendarEvent(
        id: 'sample-2',
        startDate: DateTime(2026, 10, 14),
        endDate: DateTime(2026, 10, 14),
        label: '학사일정',
        title: '수강정정',
        color: Colors.blue,
        reminderOffset: ReminderOffset.atStart,
      );
      expect(single.reminderAts, [DateTime(2026, 10, 14, 9, 0)]);
      expect(multiDay(id: 'sample-1').reminderAts, isEmpty);
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
