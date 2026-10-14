// rawSchedule 파싱(요일+실제 시각 추출)과 findCurrentClass(현재 수업 판단)
// 로직을 검증한다. 둘 다 네트워크 호출이 없는 순수 로직이다.
//
// 포맷("월09:30-11:30")은 실기기 응답에서 확인된 샘플을 기준으로 한다
// (class_schedule_parser.dart 상단 설명 참고).

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
    test('"요일HH:MM-HH:MM" 포맷을 파싱한다', () {
      final slots = parseRawSchedule('월09:30-11:30');

      expect(slots, [
        const ClassTimeSlot(day: Weekday.mon, startMinutes: 570, endMinutes: 690),
      ]);
    });

    test('여러 요일 블록이 이어져 있어도 전부 파싱한다("월09:30-11:30목09:30-11:30")', () {
      final slots = parseRawSchedule('월09:30-11:30목09:30-11:30');

      expect(slots, [
        const ClassTimeSlot(day: Weekday.mon, startMinutes: 570, endMinutes: 690),
        const ClassTimeSlot(day: Weekday.thu, startMinutes: 570, endMinutes: 690),
      ]);
    });

    test('블록 사이에 공백/구분자가 있어도 파싱한다("월09:00-09:50 화10:00-10:50")', () {
      final slots = parseRawSchedule('월09:00-09:50 화10:00-10:50');

      expect(slots, [
        const ClassTimeSlot(day: Weekday.mon, startMinutes: 540, endMinutes: 590),
        const ClassTimeSlot(day: Weekday.tue, startMinutes: 600, endMinutes: 650),
      ]);
    });

    test('토/일을 포함한 모든 요일 글자를 인식한다', () {
      final slots = parseRawSchedule('토09:00-09:50일10:00-10:50');

      expect(slots, [
        const ClassTimeSlot(day: Weekday.sat, startMinutes: 540, endMinutes: 590),
        const ClassTimeSlot(day: Weekday.sun, startMinutes: 600, endMinutes: 650),
      ]);
    });

    test('종료 시각이 시작 시각보다 앞서면(데이터 이상) 그 블록은 건너뛴다', () {
      expect(parseRawSchedule('월11:30-09:30'), isEmpty);
    });

    test('패턴이 전혀 안 맞는 문자열은 빈 리스트를 반환한다(예외 안 던짐)', () {
      expect(parseRawSchedule(''), isEmpty);
      expect(parseRawSchedule('알수없는포맷'), isEmpty);
      expect(parseRawSchedule('월1,2,3목4,5'), isEmpty);
      expect(parseRawSchedule('MWF 9:00-10:00'), isEmpty);
    });
  });

  group('findCurrentClass', () {
    test('특정 시각이 수업 시간 "안"이면 해당 과목을 반환한다', () {
      // 2026-10-06은 화요일.
      final course = _item(rawSchedule: '화11:00-11:50');
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = findCurrentClass(courses: [course], now: now);

      expect(result, same(course));
    });

    test('특정 시각이 수업 시간 "밖"이면 null을 반환한다', () {
      final course = _item(rawSchedule: '화11:00-11:50');
      final now = DateTime(2026, 10, 6, 12, 30);

      final result = findCurrentClass(courses: [course], now: now);

      expect(result, isNull);
    });

    test('요일이 다르면 null을 반환한다', () {
      final course = _item(rawSchedule: '화11:00-11:50');
      final now = DateTime(2026, 10, 7, 11, 20); // 2026-10-07은 수요일.

      final result = findCurrentClass(courses: [course], now: now);

      expect(result, isNull);
    });

    test('같은 시각에 두 과목이 겹치면(데이터 이상) 리스트에서 먼저 나오는 과목을 반환한다', () {
      final first = _item(rawSchedule: '화11:00-11:50', courseName: '첫번째');
      final second = _item(rawSchedule: '화11:00-11:50', courseName: '두번째');
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

  group('nextClassAfterToday', () {
    test('내일 수업이 있으면 그 과목을 반환한다', () {
      // 2026-10-06은 화요일 -> 내일은 수요일.
      final course = _item(rawSchedule: '수09:00-09:50', courseName: '내일수업');
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = nextClassAfterToday(courses: [course], now: now);

      expect(result?.course, same(course));
      expect(result?.day, Weekday.wed);
    });

    test('내일은 공강이고 모레 수업이 있으면 모레 수업을 반환한다', () {
      // 2026-10-06은 화요일 -> 수요일 건너뛰고 목요일.
      final course = _item(rawSchedule: '목09:00-09:50', courseName: '모레수업');
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = nextClassAfterToday(courses: [course], now: now);

      expect(result?.course, same(course));
      expect(result?.day, Weekday.thu);
    });

    test('같은 날 여러 수업이 있으면 시작 시각이 가장 빠른 수업을 반환한다', () {
      final late_ = _item(rawSchedule: '수14:00-14:50', courseName: '늦은수업');
      final early = _item(rawSchedule: '수09:00-09:50', courseName: '이른수업');
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = nextClassAfterToday(courses: [late_, early], now: now);

      expect(result?.course, same(early));
    });

    test('일주일 내내 수업이 없으면 null을 반환한다', () {
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = nextClassAfterToday(courses: const [], now: now);

      expect(result, isNull);
    });

    test('오늘과 같은 요일 수업만 있으면(매주 반복) 7일째(다음주 같은 요일)에서 찾는다', () {
      // now가 화요일이고 유일한 수업도 화요일이면, 탐색 범위(1~7일 뒤)의
      // 마지막 날에서 매칭돼야 한다 — 탐색 범위가 한 주 전체를 커버하는지
      // 확인한다.
      final course = _item(rawSchedule: '화15:00-15:50', courseName: '매주화요일');
      final now = DateTime(2026, 10, 6, 11, 20);

      final result = nextClassAfterToday(courses: [course], now: now);

      expect(result?.course, same(course));
      expect(result?.day, Weekday.tue);
    });
  });
}
