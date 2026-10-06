// 1단계(개설과목 조회) 결과와 2단계(내 시간표 코드 조회) 결과를 대조하는
// 순수 로직을 검증한다. 네트워크 호출이 없으므로 더미 인스턴스만 사용한다.

import 'package:flutter_test/flutter_test.dart';

import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/my_enrolled_courses.dart';
import 'package:daejin_app/services/my_timetable_service.dart';

/// 테스트용 [CourseCatalogItem]을 간단히 만드는 헬퍼. 이번 단계와 무관한
/// 필드는 고정값을 쓴다.
CourseCatalogItem _item({
  required String courseCode,
  required String section,
  String courseName = '테스트과목',
  bool isClosed = false,
}) {
  return CourseCatalogItem(
    seq: 1,
    courseCode: courseCode,
    section: section,
    courseName: courseName,
    courseType: '전공',
    credit: 3,
    targetGrade: '3',
    professor: '홍길동',
    rawSchedule: '월1,2',
    room: '1호관 101',
    isClosed: isClosed,
    capacity: 30,
    waitlistCount: 0,
    enrollmentRatio: '10/30',
  );
}

void main() {
  group('matchEnrolledCourses', () {
    test('내 시간표 코드가 카탈로그와 매칭되면 courses에 담긴다', () {
      final catalog = [
        _item(courseCode: 'CSE301', section: '01', courseName: '자료구조'),
        _item(courseCode: 'MAT201', section: '02', courseName: '선형대수'),
      ];
      final myTimetable = const MyTimetableResponse(
        courseSectionCodes: {'CSE301-01'},
      );

      final result = matchEnrolledCourses(
        catalog: catalog,
        myTimetable: myTimetable,
      );

      expect(result.courses, hasLength(1));
      expect(result.courses.single.courseName, '자료구조');
      expect(result.unmatchedCodes, isEmpty);
    });

    test('카탈로그에서 찾을 수 없는 코드는 unmatchedCodes로 들어간다', () {
      final catalog = [_item(courseCode: 'CSE301', section: '01')];
      final myTimetable = const MyTimetableResponse(
        courseSectionCodes: {'CSE301-01', 'ETC999-03'},
      );

      final result = matchEnrolledCourses(
        catalog: catalog,
        myTimetable: myTimetable,
      );

      expect(result.courses, hasLength(1));
      expect(result.unmatchedCodes, {'ETC999-03'});
    });

    test('내 시간표 코드가 비어 있으면 courses와 unmatchedCodes 모두 빈다', () {
      final catalog = [_item(courseCode: 'CSE301', section: '01')];
      final myTimetable = const MyTimetableResponse(courseSectionCodes: {});

      final result = matchEnrolledCourses(
        catalog: catalog,
        myTimetable: myTimetable,
      );

      expect(result.courses, isEmpty);
      expect(result.unmatchedCodes, isEmpty);
    });

    test('카탈로그가 비어 있으면 모든 코드가 unmatchedCodes로 들어간다', () {
      final myTimetable = const MyTimetableResponse(
        courseSectionCodes: {'CSE301-01'},
      );

      final result = matchEnrolledCourses(
        catalog: const [],
        myTimetable: myTimetable,
      );

      expect(result.courses, isEmpty);
      expect(result.unmatchedCodes, {'CSE301-01'});
    });

    test('폐강(isClosed=true)인 과목도 폐강 여부로 필터링하지 않고 정상 매칭된다', () {
      final catalog = [
        _item(courseCode: 'CSE301', section: '01', isClosed: true),
      ];
      final myTimetable = const MyTimetableResponse(
        courseSectionCodes: {'CSE301-01'},
      );

      final result = matchEnrolledCourses(
        catalog: catalog,
        myTimetable: myTimetable,
      );

      expect(result.courses, hasLength(1));
      expect(result.courses.single.isClosed, isTrue);
      expect(result.unmatchedCodes, isEmpty);
    });
  });
}
