import 'package:daejin_app/services/course_catalog_service.dart';
import 'package:daejin_app/services/my_timetable_service.dart';

/// [matchEnrolledCourses]의 결과.
class MyEnrolledCoursesResult {
  const MyEnrolledCoursesResult({
    required this.courses,
    required this.unmatchedCodes,
  });

  /// 내가 듣는 과목들(카탈로그 정보 포함). 순서는 [MyTimetableResponse.courseSectionCodes]의
  /// 순회 순서를 따른다.
  final List<CourseCatalogItem> courses;

  /// 내 시간표(`MyTimetableResponse.courseSectionCodes`)에는 있지만
  /// 개설과목 조회 결과([CourseCatalogItem] 목록)에서 같은 "과목코드-분반" 키를
  /// 찾지 못한 코드. 학기/연도가 어긋나거나 카탈로그가 갱신되지 않은 경우 등에
  /// 발생할 수 있으므로 예외를 던지지 않고 조용히 구분만 한다.
  final Set<String> unmatchedCodes;
}

/// 1단계(개설과목 조회) 결과 [catalog]와 2단계(내 시간표 코드 조회) 결과
/// [myTimetable]을 "과목코드-분반" 키로 대조해, 실제 내가 듣는 과목 목록을
/// 만든다.
///
/// 폐강 여부([CourseCatalogItem.isClosed])로 필터링하지 않는다 — 카탈로그에
/// 있는 그대로(폐강 과목이라도) 매칭한다.
MyEnrolledCoursesResult matchEnrolledCourses({
  required List<CourseCatalogItem> catalog,
  required MyTimetableResponse myTimetable,
}) {
  final catalogByCode = <String, CourseCatalogItem>{
    for (final item in catalog) '${item.courseCode}-${item.section}': item,
  };

  final courses = <CourseCatalogItem>[];
  final unmatchedCodes = <String>{};

  for (final code in myTimetable.courseSectionCodes) {
    final item = catalogByCode[code];
    if (item == null) {
      unmatchedCodes.add(code);
    } else {
      courses.add(item);
    }
  }

  return MyEnrolledCoursesResult(
    courses: courses,
    unmatchedCodes: unmatchedCodes,
  );
}
