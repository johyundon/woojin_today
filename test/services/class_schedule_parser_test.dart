// rawSchedule 파싱(요일+교시 추출)과 findCurrentClass(현재 수업 판단) 로직을
// 검증한다. 둘 다 네트워크 호출이 없는 순수 로직이다.
//
// 주의: class_schedule_parser.dart 전체가 "추정(비검증)" 구현이다 — 명세서에
// rawSchedule 포맷/교시표 정의가 없어 추측으로 만들었다. 이 테스트는 "추측한
// 그대로 동작하는지"만 검증하며, 실제 대진대 데이터와 맞는지는 보장하지 않는다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/class_schedule_parser.dart';
import 'package:daejin_app/services/course_catalog_service.dart';

/// 테스트용 [CourseCatalogItem]을 간단히 만드는 헬퍼. [rawSchedule] 외
/// 필드는 테스트와 무관하므로 고정값을 쓴다.
CourseCatalogItem _item({
  required String rawSchedule,
  String courseName = '테스트과목',
}) {
  return CourseCatalogItem(
    seq: 1,
    courseCode: 'CSE301',
    section: '01',
    courseName: courseName,
    courseType: '전공',
    credit: 3,
    targetGrade: '3',
    professor: '홍길동',
    rawSchedule: rawSchedule,
    room: '1호관 101',
    isClosed: false,
    capacity: 30,
    waitlistCount: 0,
    enrollmentRatio: '10/30',
  );
}

void main() {
  group('parseRawSchedule', () {
    test('"월1,2,3목4,5" 포맷(여러 요일, 쉼표로 구분된 여러 교시)을 파싱한다', () {
      final slots = parseRawSchedule('월1,2,3목4,5');

      expect(slots, [
        const ClassPeriodSlot(day: Weekday.mon, period: 1),
        const ClassPeriodSlot(day: Weekday.mon, period: 2),
        const ClassPeriodSlot(day: Weekday.mon, period: 3),
        const ClassPeriodSlot(day: Weekday.thu, period: 4),
        const ClassPeriodSlot(day: Weekday.thu, period: 5),
      ]);
    });

    test('요일 블록 사이에 공백이 있어도 파싱한다("월1,2 화3")', () {
      final slots = parseRawSchedule('월1,2 화3');

      expect(slots, [
        const ClassPeriodSlot(day: Weekday.mon, period: 1),
        const ClassPeriodSlot(day: Weekday.mon, period: 2),
        const ClassPeriodSlot(day: Weekday.tue, period: 3),
      ]);
    });

    test('교시가 하나뿐인 단일 요일 블록도 파싱한다("금9")', () {
      final slots = parseRawSchedule('금9');

      expect(slots, [const ClassPeriodSlot(day: Weekday.fri, period: 9)]);
    });

    test('토/일을 포함한 모든 요일 글자를 인식한다', () {
      final slots = parseRawSchedule('토1일2');

      expect(slots, [
        const ClassPeriodSlot(day: Weekday.sat, period: 1),
        const ClassPeriodSlot(day: Weekday.sun, period: 2),
      ]);
    });

    test('패턴이 전혀 안 맞는 문자열은 빈 리스트를 반환한다(예외 안 던짐)', () {
      expect(parseRawSchedule(''), isEmpty);
      expect(parseRawSchedule('알수없는포맷'), isEmpty);
      expect(parseRawSchedule('MWF 9:00-10:00'), isEmpty);
    });
  });

  group('findCurrentClass', () {
    test('특정 시각이 수업 시간 "안"이면 해당 과목을 반환한다', () {
      // 2026-10-06은 화요일. "화3" = 3교시(추정 교시표: 11:00~11:50).
      final course = _item(rawSchedule: '화3');
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = findCurrentClass(courses: [course], now: now);

      expect(result, same(course));
    });

    test('특정 시각이 수업 시간 "밖"이면 null을 반환한다', () {
      // 같은 화요일, 3교시(11:00~11:50) 수업이지만 조회 시각은 12:30.
      final course = _item(rawSchedule: '화3');
      final now = DateTime(2026, 10, 6, 12, 30);

      final result = findCurrentClass(courses: [course], now: now);

      expect(result, isNull);
    });

    test('요일이 다르면 null을 반환한다', () {
      // "화3" 수업인데 조회 시각은 수요일.
      final course = _item(rawSchedule: '화3');
      final now = DateTime(2026, 10, 7, 11, 20); // 2026-10-07은 수요일.

      final result = findCurrentClass(courses: [course], now: now);

      expect(result, isNull);
    });

    test('같은 시각에 두 과목이 겹치면(데이터 이상) 리스트에서 먼저 나오는 과목을 반환한다', () {
      final first = _item(rawSchedule: '화3', courseName: '첫번째');
      final second = _item(rawSchedule: '화3', courseName: '두번째');
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = findCurrentClass(courses: [first, second], now: now);

      expect(result, same(first));
    });

    test('빈 과목 리스트면 null을 반환한다', () {
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = findCurrentClass(courses: const [], now: now);

      expect(result, isNull);
    });
  });
}
