import '../config/mock_mode.dart';
import 'course_catalog_service.dart';
import 'fakes/fake_course_catalog_service.dart';
import 'fakes/fake_my_timetable_service.dart';
import 'fakes/fake_portal_login_service.dart';
import 'fakes/fake_student_id_service.dart';
import 'fakes/fake_student_info_service.dart';
import 'my_timetable_service.dart';
import 'portal_login_service.dart';
import 'student_id_service.dart';
import 'student_info_service.dart';

/// `kUseMockApi`에 따라 실제 서비스 또는 `services/fakes/`의 가짜 서비스를
/// 돌려주는 생성 지점을 한 곳으로 모은 팩토리.
///
/// 이전에는 각 화면이 `kUseMockApi ? Fake...() : Real...()` 삼항 연산자를
/// 직접 쓰고 `fakes/`를 각자 import했다. 이 파일만 `fakes/`를 import하면
/// 되도록, 화면들은 이 팩토리를 통해서만 서비스 인스턴스를 받는다.
///
/// 캐싱/싱글톤화는 하지 않는다 — 호출할 때마다 새 인스턴스를 만들어, 기존
/// 화면들이 하던 "매번 새로 생성" 동작을 그대로 유지한다.
class ServiceFactory {
  ServiceFactory._();

  static CourseCatalogServiceBase courseCatalog() =>
      kUseMockApi ? FakeCourseCatalogService() : CourseCatalogService();

  static MyTimetableServiceBase myTimetable() =>
      kUseMockApi ? FakeMyTimetableService() : MyTimetableService();

  static StudentInfoServiceBase studentInfo() =>
      kUseMockApi ? FakeStudentInfoService() : StudentInfoService();

  static PortalLoginServiceBase portalLogin() =>
      kUseMockApi ? FakePortalLoginService() : PortalLoginService();

  static StudentIdServiceBase studentId() =>
      kUseMockApi ? FakeStudentIdService() : StudentIdService();
}
