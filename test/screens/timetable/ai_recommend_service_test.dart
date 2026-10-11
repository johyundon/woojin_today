// generateTimetableCandidates(AI 시간표 자동 생성 후보 생성)이 설문 답변의
// 제약(학점 상한, 공강 요일, 폐강 과목 제외, 시간 겹침 없음)을 지키는지
// 검증한다. 셔플이 섞여 매 호출 결과가 달라지므로, 정확한 조합이 아니라
// "어떤 결과가 나오든 지켜야 하는 성질"을 검증한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/timetable/models/ai_recommend_answers.dart';
import 'package:daejin_app/screens/timetable/services/ai_recommend_service.dart';
import 'package:daejin_app/services/class_schedule_parser.dart';
import 'package:daejin_app/services/course_catalog_service.dart';

CourseCatalogItem _item({
  required String courseCode,
  required String rawSchedule,
  String courseType = '전공',
  double credit = 3,
  bool isClosed = false,
}) {
  return CourseCatalogItem(
    seq: 1,
    courseCode: courseCode,
    section: '01',
    courseName: '$courseCode 과목',
    courseType: courseType,
    credit: credit,
    targetGrade: '3',
    professor: '홍길동',
    rawSchedule: rawSchedule,
    room: '1호관 101',
    isClosed: isClosed,
    capacity: 30,
    waitlistCount: 0,
    enrollmentRatio: '10/30',
  );
}

final _catalog = [
  _item(courseCode: 'A101', rawSchedule: '월09:00-10:30', courseType: '전공필수'),
  _item(courseCode: 'A102', rawSchedule: '화09:00-10:30', courseType: '전공선택'),
  _item(courseCode: 'A103', rawSchedule: '수09:00-10:30', courseType: '전공선택'),
  _item(courseCode: 'A104', rawSchedule: '목09:00-10:30', courseType: '전공선택'),
  _item(courseCode: 'A105', rawSchedule: '금09:00-10:30', courseType: '전공선택'),
  _item(courseCode: 'B201', rawSchedule: '월13:00-14:30', courseType: '교양선택1영역'),
  _item(courseCode: 'B202', rawSchedule: '화13:00-14:30', courseType: '교양선택2영역'),
  _item(courseCode: 'B203', rawSchedule: '수13:00-14:30', courseType: '교양선택3영역'),
  _item(
    courseCode: 'C301',
    rawSchedule: '월09:00-10:30',
    isClosed: true,
  ), // 폐강 — 절대 뽑히면 안 됨.
];

/// 한 후보 안에서 같은 요일 슬롯끼리 시간이 겹치지 않는지 확인한다.
bool _hasNoOverlap(List<ClassTimeSlot> slots) {
  for (var i = 0; i < slots.length; i++) {
    for (var j = i + 1; j < slots.length; j++) {
      if (slots[i].day != slots[j].day) continue;
      final overlap =
          slots[i].startMinutes < slots[j].endMinutes &&
          slots[i].endMinutes > slots[j].startMinutes;
      if (overlap) return false;
    }
  }
  return true;
}

void main() {
  test('기본 candidateCount(3)개를 만든다', () {
    final candidates = generateTimetableCandidates(
      catalog: _catalog,
      answers: AiRecommendAnswers(credit: 9),
    );
    expect(candidates, hasLength(3));
  });

  test('폐강 과목은 어떤 후보에도 포함되지 않는다', () {
    final candidates = generateTimetableCandidates(
      catalog: _catalog,
      answers: AiRecommendAnswers(credit: 15),
      candidateCount: 5,
    );
    for (final candidate in candidates) {
      expect(candidate.any((c) => c.courseCode == 'C301'), isFalse);
    }
  });

  test('목표 학점보다 크게(3학점 넘게) 초과하지 않는다', () {
    final candidates = generateTimetableCandidates(
      catalog: _catalog,
      answers: AiRecommendAnswers(credit: 9),
      candidateCount: 5,
    );
    for (final candidate in candidates) {
      final total = candidate.fold(0.0, (sum, c) => sum + c.credit);
      expect(total, lessThanOrEqualTo(9 + 3));
    }
  });

  test('특정 공강 요일을 지정하면 그 요일엔 수업을 넣지 않는다', () {
    final candidates = generateTimetableCandidates(
      catalog: _catalog,
      answers: AiRecommendAnswers(
        credit: 15,
        freeDayMode: FreeDayMode.specificDay,
        specificFreeDay: Weekday.mon,
      ),
      candidateCount: 5,
    );
    for (final candidate in candidates) {
      for (final course in candidate) {
        final slots = parseRawSchedule(course.rawSchedule);
        expect(slots.any((s) => s.day == Weekday.mon), isFalse);
      }
    }
  });

  test('같은 후보 안에서는 시간이 겹치는 과목을 동시에 담지 않는다', () {
    final candidates = generateTimetableCandidates(
      catalog: _catalog,
      answers: AiRecommendAnswers(credit: 15),
      candidateCount: 5,
    );
    for (final candidate in candidates) {
      final allSlots = candidate
          .expand((c) => parseRawSchedule(c.rawSchedule))
          .toList();
      expect(_hasNoOverlap(allSlots), isTrue);
    }
  });
}
