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
  late final CourseCatalogService _courseCatalogService;
  late final MyTimetableService _myTimetableService;
  late final SavedTimetableStorage _savedTimetableStorage;
  late final DateTime Function() _now;

  late int _year;
  late int _semester;
  final _headerKey = GlobalKey();

  List<PlannedCourse> _confirmedCourses = [];
  List<CourseCatalogItem> _catalog = [];
  bool _catalogLoading = false;
  String? _catalogError;
  bool _myTimetableLoading = false;

  final _searchController = TextEditingController();
  String _query = '';
  final _filters = CourseFilters();
  bool _filterPanelOpen = false;
  PendingSlot? _pendingSlot;

  int _savedCount = 0;

  bool get _hasSession => widget.jsessionId != null && widget.wmonid != null;
  bool get _hasFullSession => _hasSession && widget.userId2 != null;
}
