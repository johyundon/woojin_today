// 홈 "다가오는 일정" 카드(셔틀버스 카드 자리): 내 일정 → 학사일정 순으로 가장
// 가까운 일정을 고르고, 남은 날을 "D-3 · 11.11(수)"처럼 보여준다.

import 'package:daejin_app/screens/calendar/models/calendar_event.dart';
import 'package:daejin_app/screens/home/widgets/upcoming_event_card.dart';
import 'package:daejin_app/services/academic_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 11, 8, 9); // 일요일

CalendarEvent _mine(
  String title,
  DateTime start, {
  DateTime? end,
  TimeOfDay? time,
  String id = 'local-1',
}) => CalendarEvent(
  id: id,
  startDate: start,
  endDate: end ?? start,
  label: '내 일정',
  title: title,
  color: Colors.blue,
  startTime: time,
);

AcademicScheduleItem _academic(String title, DateTime start, [DateTime? end]) =>
    AcademicScheduleItem(start: start, end: end ?? start, title: title);

void main() {
  group('pickUpcomingEvent', () {
    test('내 일정이 있으면 학사일정보다 내 일정 중 가장 가까운 것을 고른다', () {
      final e = pickUpcomingEvent(
        mine: [
          _mine('스터디', DateTime(2026, 11, 12), id: 'local-a'),
          _mine('팀플 회의', DateTime(2026, 11, 10), id: 'local-b'),
        ],
        academic: [_academic('중간고사', DateTime(2026, 11, 9))],
        now: _now,
      );
      expect(e?.title, '팀플 회의');
    });

    test('지난 일정은 빼고, 내 일정이 없으면 학사일정에서 고른다', () {
      final e = pickUpcomingEvent(
        mine: [_mine('지난 약속', DateTime(2026, 11, 1))],
        academic: [
          _academic('지난 학사일정', DateTime(2026, 11, 2)),
          _academic('수강정정', DateTime(2026, 11, 11)),
        ],
        now: _now,
      );
      expect(e?.title, '수강정정');
    });

    test('학교 학사일정(id가 local-로 시작하지 않음)은 내 일정으로 치지 않는다', () {
      final e = pickUpcomingEvent(
        mine: [_mine('학교 일정', DateTime(2026, 11, 9), id: 'academic-x')],
        academic: const [],
        now: _now,
      );
      expect(e, isNull);
    });

    test('같은 날이면 시작 시각이 빠른 것을 고른다', () {
      final e = pickUpcomingEvent(
        mine: [
          _mine(
            '저녁',
            DateTime(2026, 11, 9),
            time: const TimeOfDay(hour: 18, minute: 0),
            id: 'local-a',
          ),
          _mine(
            '아침',
            DateTime(2026, 11, 9),
            time: const TimeOfDay(hour: 8, minute: 0),
            id: 'local-b',
          ),
        ],
        academic: const [],
        now: _now,
      );
      expect(e?.title, '아침');
    });
  });

  group('upcomingEventFooter', () {
    test('앞으로의 일정은 D-day와 날짜·요일', () {
      final e = UpcomingEvent(
        title: 'x',
        start: DateTime(2026, 11, 11),
        end: DateTime(2026, 11, 11),
      );
      expect(upcomingEventFooter(e, _now), 'D-3 · 11.11(수)');
    });

    test('오늘 일정은 시각을 함께', () {
      final e = UpcomingEvent(
        title: 'x',
        start: DateTime(2026, 11, 8),
        end: DateTime(2026, 11, 8),
        startTime: const TimeOfDay(hour: 14, minute: 0),
      );
      expect(upcomingEventFooter(e, _now), '오늘 14:00');
    });

    test('이미 시작한 여러 날 일정은 진행 중과 끝나는 날', () {
      final e = UpcomingEvent(
        title: 'x',
        start: DateTime(2026, 11, 5),
        end: DateTime(2026, 11, 12),
      );
      expect(upcomingEventFooter(e, _now), '진행 중 · ~11.12');
    });
  });
}
