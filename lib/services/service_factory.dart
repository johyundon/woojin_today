import '../config/mock_mode.dart';
import 'cafeteria_menu_service.dart';
import 'course_catalog_service.dart';
import 'fakes/fake_course_catalog_service.dart';
import 'fakes/fake_my_timetable_service.dart';
import 'my_timetable_service.dart';
import 'portal_login_service.dart';
import 'student_id_service.dart';
import 'student_info_service.dart';
import 'twin_rank_service.dart';

/// `kUseMockApi`에 따라 실제 서비스 또는 `services/fakes/`의 가짜 서비스를
/// 돌려주는 생성 지점을 한 곳으로 모은 팩토리. 로그인, 학번 찾기, 학생 정보, 학식, 학과 등수는
/// `kUseMockApi`와 상관없이 항상 실제 서비스를 쓴다.
///
/// 캐싱/싱글톤화는 하지 않는다 — 호출할 때마다 새 인스턴스를 만들어, 기존
/// 화면들이 하던 "매번 새로 생성" 동작을 그대로 유지한다.
class ServiceFactory {
  ServiceFactory._();

  static CourseCatalogServiceBase courseCatalog() =>
      kUseMockApi ? FakeCourseCatalogService() : CourseCatalogService();

  static MyTimetableServiceBase myTimetable() =>
      kUseMockApi ? FakeMyTimetableService() : MyTimetableService();

  /// 학생 정보(이름/학과/학년/지도교수)는 로그인한 본인의 실제 데이터를 홈 인사말과
  /// "내 정보"에 쓰므로, 로그인처럼 `kUseMockApi`와 상관없이 항상 실제 서버를 부른다.
  static StudentInfoServiceBase studentInfo() => StudentInfoService();

  /// 학식은 로그인처럼 `kUseMockApi`와 상관없이 항상 실제 서버를 부른다.
  static CafeteriaMenuServiceBase cafeteriaMenu() => CafeteriaMenuService();

  /// 학과 등수용 T-WIN 성적 조회. 로그인한 본인의 실제 성적을 보여줘야 하므로
  /// `kUseMockApi`와 상관없이 항상 실제 서버를 부른다(7일 캐시로 요청을 줄인다).
  static TwinRankServiceBase twinRank() => TwinRankService();

  static PortalLoginServiceBase portalLogin() => PortalLoginService();

  static StudentIdServiceBase studentId() => StudentIdService();
}
