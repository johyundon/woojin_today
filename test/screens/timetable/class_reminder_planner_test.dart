import 'package:daejin_app/screens/timetable/models/planned_course.dart';
import 'package:daejin_app/screens/timetable/services/class_reminder_planner.dart';
import 'package:flutter_test/flutter_test.dart';

PlannedCourse _course(String schedule, {String room = '인문관 302'}) {
  return PlannedCourse(
    courseCode: '565013',
    section: '01',
    courseName: '일본어회화',
    courseType: '교양',
    credit: 2,
    targetGrade: '전체',
    professor: '홍길동',
    rawSchedule: schedule,
    room: room,
    enrollmentRatio: '0/30',
  );
}

void main() {
  group('buildClassReminders', () {
    test('수업 시작 10분 전 시각으로 요일마다 1건씩 만든다', () {
      final reminders = buildClassReminders([
        _course('월11:30-13:30 수09:00-10:00'),
      ]);

      expect(reminders.length, 2);
      expect(reminders[0].weekday, DateTime.monday);
      expect(reminders[0].minutesOfDay, 11 * 60 + 20);
      expect(reminders[0].title, '일본어회화 수업 10분 전');
      expect(reminders[0].body, '11:30 시작 · 인문관 302');
      expect(reminders[1].weekday, DateTime.wednesday);
      expect(reminders[1].minutesOfDay, 8 * 60 + 50);
      expect(reminders[0].id == reminders[1].id, isFalse);
    });

    test('시간표 원문이 없으면 알림도 없다', () {
      expect(buildClassReminders([_course('')]), isEmpty);
    });
  });

  group('nextWeeklyOccurrence', () {
    // 2026-10-14는 수요일.
    final now = DateTime(2026, 10, 14, 9, 0);

    test('이번 주 아직 안 지난 시각이면 이번 주', () {
      final result = nextWeeklyOccurrence(now, DateTime.wednesday, 9 * 60 + 30);
      expect(result, DateTime(2026, 10, 14, 9, 30));
    });

    test('이번 주 이미 지난 시각이면 다음 주로 넘긴다', () {
      final result = nextWeeklyOccurrence(now, DateTime.wednesday, 8 * 60);
      expect(result, DateTime(2026, 10, 21, 8, 0));
    });

    test('다른 요일은 가장 가까운 그 요일', () {
      expect(
        nextWeeklyOccurrence(now, DateTime.monday, 10 * 60),
        DateTime(2026, 10, 19, 10, 0),
      );
      expect(
        nextWeeklyOccurrence(now, DateTime.friday, 10 * 60),
        DateTime(2026, 10, 16, 10, 0),
      );
    });
  });
}
