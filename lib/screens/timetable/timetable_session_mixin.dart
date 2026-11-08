part of 'timetable_screen.dart';

/// [TimetableScreen]의 화면 전역 상태.
///
/// 데이터 로딩/학기 이동/과목 관리/저장·불러오기 등 다른 모든 책임
/// 믹스인이 공유해서 읽고 쓰는 핵심 필드(주입된 서비스, 학기, 확정/개설
/// 과목 목록, 검색·필터 상태)만 모아둔다 — 책임별로 쪼개려 해도 이
/// 필드들은 거의 모든 책임이 동시에 건드려서 한쪽에만 두면 순환 의존이
/// 생기므로, 공용 베이스 믹스인으로 분리했다. 실제 동작(메서드)은 각
/// 책임별 믹스인(TimetableDataLoadingMixin 등)에 둔다.
mixin TimetableSessionMixin on State<TimetableScreen> {
  late final CourseCatalogServiceBase _courseCatalogService;
  late final MyTimetableServiceBase _myTimetableService;
  late final SavedTimetableStorage _savedTimetableStorage;
  late final DateTime Function() _now;

  late int _year;
  late int _semester;
  final _headerKey = GlobalKey();

  List<PlannedCourse> _confirmedCoursesValue = [];

  /// 그리드에 확정된 과목. 새 목록을 넣을 때마다 [_onConfirmedCoursesChanged]가
  /// 불려 강의시간 알림을 다시 맞춘다(과목 추가/삭제·불러오기 등 모든 경로 공통).
  List<PlannedCourse> get _confirmedCourses => _confirmedCoursesValue;
  set _confirmedCourses(List<PlannedCourse> courses) {
    _confirmedCoursesValue = courses;
    _onConfirmedCoursesChanged();
  }

  /// [TimetableReminderMixin]이 구현한다.
  void _onConfirmedCoursesChanged();
  List<CourseCatalogItem> _catalog = [];
  bool _catalogLoading = false;
  String? _catalogError;

  /// 지금 학기 개설과목을 불러오기까지 끝냈는지(성공한 경우만 true).
  bool _catalogLoaded = false;

  /// 개설과목을 불러왔는데 비어 있다 = 학교가 그 학기 시간표를 아직 올리지
  /// 않았다(예: 다음 학기). 이때는 내 시간표도 있을 수 없어 불러오지 않는다.
  bool get _catalogNotReady => _catalogLoaded && _catalog.isEmpty;
  bool _myTimetableLoading = false;
  MyTimetableStatus _myTimetableStatus = MyTimetableStatus.idle;

  /// 지금 학기([_year]/[_semester])의 내 시간표를 학교에서 불러왔고 과목이
  /// 있는지. 학기를 바꾸거나 저장한 시간표를 불러오면 false로 돌린다.
  bool _hasRegisteredCourses = false;

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _query = '';
  final _filters = CourseFilters();
  bool _filterPanelOpen = false;
  bool _addPanelOpen = false;
  PendingSlot? _pendingSlot;

  int _savedCount = 0;

  bool get _hasSession => widget.jsessionId != null && widget.wmonid != null;
  bool get _hasFullSession => _hasSession && widget.userId2 != null;
}
