import 'course_catalog_service.dart';
import 'my_timetable_service.dart';
import 'student_info_service.dart';

/// 화면을 옮길 때마다 같은 세션(jsessionId/wmonid/userId2)으로 같은 API를
/// 반복 호출하지 않도록 하는 가벼운 인메모리 캐시.
///
/// 화면들은 `ServiceFactory`로 받은 서비스 인스턴스를 직접 호출하는 대신, 이
/// 클래스의 `getXxx` 메서드에 그 서비스 인스턴스를 넘겨 호출한다. 캐시 키에
/// 세션 식별자를 포함시켜, 세션이 바뀌었는데 [clear]를 놓친 경우에도 다른
/// 세션의 캐시를 잘못 재사용하지 않게 방어한다(식별자가 다르면 캐시 미스).
///
/// 실패한 요청(예외)은 캐시에 저장하지 않는다 — 다음 호출에서 다시 시도된다.
///
/// 로그아웃하면 다른 학생이 같은 기기로 재로그인할 수 있으므로, 로그아웃
/// 처리 지점([home_screen.dart]의 `AvatarMenuAction.logout` 분기)에서 반드시
/// [clear]를 호출해 캐시를 비워야 한다.
class SessionCache {
  SessionCache._();

  static final Map<String, StudentInfoResponse> _studentInfoCache = {};
  static final Map<String, List<CourseCatalogItem>> _courseCatalogCache = {};
  static final Map<String, MyTimetableResponse> _myTimetableCache = {};

  /// [StudentInfoServiceBase.fetchStudentInfo] 결과를 [userId2] 기준으로
  /// 캐싱한다. 이 서비스 호출은 jsessionId/wmonid를 쓰지 않으므로(명세:
  /// SUGANG_SIMPLE_COOKIE 패턴) 키에도 포함하지 않는다.
  static Future<StudentInfoResponse> getStudentInfo(
    StudentInfoServiceBase service, {
    required String userId2,
    bool forceRefresh = false,
  }) async {
    final key = userId2;
    if (!forceRefresh) {
      final cached = _studentInfoCache[key];
      if (cached != null) return cached;
    }
    final result = await service.fetchStudentInfo(userId2: userId2);
    _studentInfoCache[key] = result;
    return result;
  }

  /// [CourseCatalogServiceBase.fetchCourseCatalog] 결과를 세션 식별자 +
  /// 조회 파라미터 기준으로 캐싱한다.
  ///
  /// [userId]는 캐시 키에 포함하지 않는다 — 개설과목 조회는 공개 데이터라
  /// userId 값과 무관하게 같은 결과를 돌려준다(`course_catalog_service.dart`
  /// 문서: "공개 데이터 조회라 user_id/userId는 고정값(기본 guest)을 넣어도
  /// 동작한다"). home_screen.dart(userId 생략)와 timetable_screen.dart
  /// (userId: 본인 userId2 전달)처럼 호출부마다 이 값이 달라도, 같은
  /// 세션·학기·필터 조회라면 캐시를 공유해야 중복 호출이 사라진다.
  static Future<List<CourseCatalogItem>> getCourseCatalog(
    CourseCatalogServiceBase service, {
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    String icKwa = '%',
    String? icKwa1,
    String? userId,
    bool forceRefresh = false,
  }) async {
    final key = '$jsessionId:$wmonid:$year:$semester:$icKwa:$icKwa1';
    if (!forceRefresh) {
      final cached = _courseCatalogCache[key];
      if (cached != null) return cached;
    }
    final result = await service.fetchCourseCatalog(
      year: year,
      semester: semester,
      jsessionId: jsessionId,
      wmonid: wmonid,
      icKwa: icKwa,
      icKwa1: icKwa1,
      userId: userId,
    );
    _courseCatalogCache[key] = result;
    return result;
  }

  /// [MyTimetableServiceBase.fetchMyTimetable] 결과를 세션 식별자 + 조회
  /// 파라미터 기준으로 캐싱한다.
  static Future<MyTimetableResponse> getMyTimetable(
    MyTimetableServiceBase service, {
    required int year,
    required int semester,
    required String jsessionId,
    required String wmonid,
    required String userId2,
    bool forceRefresh = false,
  }) async {
    final key = '$jsessionId:$wmonid:$userId2:$year:$semester';
    if (!forceRefresh) {
      final cached = _myTimetableCache[key];
      if (cached != null) return cached;
    }
    final result = await service.fetchMyTimetable(
      year: year,
      semester: semester,
      jsessionId: jsessionId,
      wmonid: wmonid,
      userId2: userId2,
    );
    _myTimetableCache[key] = result;
    return result;
  }

  /// 로그아웃 시 반드시 호출해야 한다 — 다음 로그인이 다른 학생일 수 있으므로
  /// 이전 세션의 캐시가 남아있으면 안 된다.
  static void clear() {
    _studentInfoCache.clear();
    _courseCatalogCache.clear();
    _myTimetableCache.clear();
  }
}
