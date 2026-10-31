import 'dart:async';

import '../my_timetable_service.dart';
import 'fake_course_catalog_service.dart';

/// 실제 내 시간표 조회 API(`BlsnTotalTimeTableLst.jsp`)를 호출하지 않고, 가짜
/// 수강 과목을 돌려주는 서비스. 앱은 항상 실제 서비스를 쓰고, 테스트에서만 쓴다.
///
/// 아래 코드 집합은 [FakeCourseCatalogService.fakeCatalog] 중 시간이 겹치지
/// 않는 6과목(16학점)을 골라, "이미 수강신청을 마친 학생"의 정상적인
/// 시간표처럼 보이게 구성했다.
class FakeMyTimetableService implements MyTimetableServiceBase {
  static const Set<String> fakeEnrolledCodes = {
    'CS201-01',
    'CS301-01',
    'CS320-01',
    'CS410-01',
    'GE101-01',
    'GE130-01',
  };

  @override
  Future<MyTimetableResponse> fetchMyTimetable({
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MyTimetableResponse(
      courses: FakeCourseCatalogService.fakeCatalog
          .where((c) => fakeEnrolledCodes.contains('${c.courseCode}-${c.section}'))
          .toList(),
    );
  }
}
