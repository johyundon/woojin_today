// extractBuildingName/computeTransitLinks이 연강(간격 10분 이내) 구간에서
// 건물이 다른 경우에만 TransitLink를 만들고, 같은 건물이거나 간격이 너무
// 멀거나 건물명을 못 찾으면(에러 없이) 건너뛰는지 확인한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/screens/timetable/models/planned_course.dart';
import 'package:daejin_app/screens/timetable/transit_detection.dart';

PlannedCourse _course({
  required String courseCode,
  required String rawSchedule,
  required String room,
}) {
  return PlannedCourse(
    courseCode: courseCode,
    section: '01',
    courseName: courseCode,
    courseType: '전공선택',
    credit: 3,
    targetGrade: '3',
    professor: '홍길동',
    rawSchedule: rawSchedule,
    room: room,
    enrollmentRatio: '10/30',
  );
}

void main() {
  group('extractBuildingName', () {
    test('room 앞부분과 일치하는 건물명을 찾는다', () {
      expect(extractBuildingName('공대 가동301'), '공대 가동');
    });

    test('일치하는 건물이 없으면 null', () {
      expect(extractBuildingName('알수없는관101'), isNull);
    });
  });

  group('computeTransitLinks', () {
    test('건물이 다르고 간격이 10분 이내면 TransitLink를 만든다', () {
      final courses = [
        _course(courseCode: 'A', rawSchedule: '화09:00-10:30', room: '공대 다동502'),
        _course(courseCode: 'B', rawSchedule: '화10:30-12:00', room: '공대 가동302'),
      ];

      final links = computeTransitLinks(courses);

      expect(links, hasLength(1));
      expect(links.first.originBuilding, '공대 다동');
      expect(links.first.destinationBuilding, '공대 가동');
      expect(links.first.gapStartMinutes, 10 * 60 + 30);
      expect(links.first.gapEndMinutes, 10 * 60 + 30);
    });

    test('같은 건물이면 만들지 않는다', () {
      final courses = [
        _course(courseCode: 'A', rawSchedule: '화09:00-10:30', room: '공대 가동301'),
        _course(courseCode: 'B', rawSchedule: '화10:30-12:00', room: '공대 가동302'),
      ];

      expect(computeTransitLinks(courses), isEmpty);
    });

    test('간격이 10분보다 크면 만들지 않는다', () {
      final courses = [
        _course(courseCode: 'A', rawSchedule: '화09:00-10:30', room: '공대 다동502'),
        _course(courseCode: 'B', rawSchedule: '화10:45-12:00', room: '공대 가동302'),
      ];

      expect(computeTransitLinks(courses), isEmpty);
    });

    test('건물명을 못 찾으면 예외 없이 건너뛴다', () {
      final courses = [
        _course(courseCode: 'A', rawSchedule: '화09:00-10:30', room: '알수없는관502'),
        _course(courseCode: 'B', rawSchedule: '화10:30-12:00', room: '공대 가동302'),
      ];

      expect(computeTransitLinks(courses), isEmpty);
    });
  });
}
