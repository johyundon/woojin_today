import 'package:flutter/material.dart';

import '../../services/class_schedule_parser.dart';
import '../../services/course_catalog_service.dart';
import '../../services/my_enrolled_courses.dart';
import '../../services/my_timetable_service.dart';
import 'course_filters.dart';
import 'grid_layout.dart';
import 'models/planned_course.dart';
import 'models/saved_timetable.dart';
import 'services/saved_timetable_storage.dart';
import 'syllabus_screen.dart';
import 'saved_timetables_screen.dart';
import 'timetable_colors.dart';
import 'widgets/course_detail_dialog.dart';
import 'widgets/course_result_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/save_timetable_dialog.dart';
import 'widgets/search_panel.dart';
import 'widgets/timetable_grid.dart';
import 'widgets/timetable_header.dart';

/// 현재 학기를 추정한다. home_screen.dart의 `_estimateCurrentSemester`와
/// 로직이 같지만, 그쪽은 private(화면 파일 밖에서 재사용 불가)이라 이 화면
/// 전용으로 똑같이 작게 복제했다 — 이 화면 하나를 위해 홈 화면 파일을
/// 건드리고 싶지 않았다.
({int year, int semester}) _estimateCurrentSemester(DateTime now) {
  if (now.month >= 3 && now.month <= 8) {
    return (year: now.year, semester: 1);
  } else if (now.month >= 9 && now.month <= 12) {
    return (year: now.year, semester: 2);
  } else {
    return (year: now.year - 1, semester: 2);
  }
}

({int year, int semester}) _stepSemester(
  ({int year, int semester}) s,
  int steps,
) {
  var year = s.year;
  var semester = s.semester;
  if (steps >= 0) {
    for (var i = 0; i < steps; i++) {
      if (semester == 1) {
        semester = 2;
      } else {
        semester = 1;
        year++;
      }
    }
  } else {
    for (var i = 0; i < -steps; i++) {
      if (semester == 2) {
        semester = 1;
      } else {
        semester = 2;
        year--;
      }
    }
  }
  return (year: year, semester: semester);
}

/// "시간표 짜기" 화면. 홈 화면의 "시간표를 짜볼까요?" 추천 카드에서 진입한다.
///
/// 세션 쿠키(jsessionId/wmonid/userId2)는 로그인 흐름을 통해 그대로 전달받되,
/// 셋 중 하나라도 없으면(세션 없음) 크래시 없이 "불러올 수 없음" 상태로
/// 방어적으로 처리한다(home_screen.dart와 동일한 원칙).
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({
    super.key,
    this.jsessionId,
    this.wmonid,
    this.userId2,
    this.courseCatalogService,
    this.myTimetableService,
    this.savedTimetableStorage,
    this.now,
  });

  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  /// 테스트에서 mock 주입용. [HomeScreen]과 동일한 패턴.
  final CourseCatalogService? courseCatalogService;
  final MyTimetableService? myTimetableService;
  final SavedTimetableStorage? savedTimetableStorage;
  final DateTime Function()? now;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
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

  // 그리드 아래 핸들을 드래그해서 조절하는 그리드 뷰포트 높이.
  double _gridViewportHeight = 360;
  static const double _minGridViewportHeight = 240;
  static const double _maxGridViewportHeight = 640;

  // 그리드를 아무리 늘려도 검색 결과 리스트에 항상 남겨줄 최소 높이.
  static const double _minResultsReserve = 0;

  // 드래그 가능한 최댓값을 계산하기 위해, 그리드를 제외한 나머지 요소들
  // (헤더~빠른실행줄, 핸들~검색바)의 실제 렌더 높이를 매 프레임 실측한다.
  // "스크롤뷰로 감싸서 넘치면 자체 스크롤" 방식은 핸들의 드래그 제스처와
  // 스크롤뷰의 드래그 제스처가 서로 경합해서(제스처 아레나 충돌) 드래그
  // 방향에 따라 번갈아 씹히는 문제가 있어 포기했다 — 대신 애초에 넘칠 수
  // 없는 값으로만 _gridViewportHeight가 움직이게 만든다.
  final _chromeAboveGridKey = GlobalKey();
  final _chromeBelowGridKey = GlobalKey();
  final _gridWrapperKey = GlobalKey();
  double _chromeAboveHeight = 0;
  double _chromeBelowHeight = 0;
  // TimetableGrid 내부의 요일 라벨 행 + 여백처럼 viewportHeight에 포함되지
  // 않는 고정 높이분. 실측치에서 역산한다(그리드 자체는 고정폭 레이아웃이라
  // 이 값이 뷰포트 크기와 무관하게 항상 같다).
  double _gridChromeHeight = 0;
  double _bodyHeight = 0;

  double get _computedMaxGridViewportHeight {
    final cap =
        _bodyHeight -
        _minResultsReserve -
        _chromeAboveHeight -
        _chromeBelowHeight -
        _gridChromeHeight;
    return cap.clamp(_minGridViewportHeight, _maxGridViewportHeight);
  }

  void _scheduleChromeMeasurement(double gridViewportHeightThisBuild) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final above = _chromeAboveGridKey.currentContext?.size?.height;
      final below = _chromeBelowGridKey.currentContext?.size?.height;
      final gridWrapper = _gridWrapperKey.currentContext?.size?.height;
      if (above == null || below == null || gridWrapper == null) return;

      final gridChrome = gridWrapper - gridViewportHeightThisBuild;
      final changed =
          (above - _chromeAboveHeight).abs() > 0.5 ||
          (below - _chromeBelowHeight).abs() > 0.5 ||
          (gridChrome - _gridChromeHeight).abs() > 0.5;
      if (!changed) return;

      setState(() {
        _chromeAboveHeight = above;
        _chromeBelowHeight = below;
        _gridChromeHeight = gridChrome;
      });
    });
  }

  // TODO: 실제 수업 시간 알림(로컬 알림 스케줄링)은 구현돼 있지 않다. 이
  // 토글은 디자인(상태 1~10 공통 헤더)에 맞춘 UI 상태만 갖고 있다 — 알림
  // 관련 패키지/권한 처리는 이번 작업 범위 밖이라 추측으로 구현하지 않았다.
  bool _notificationsEnabled = true;

  int _savedCount = 0;

  bool get _hasSession => widget.jsessionId != null && widget.wmonid != null;
  bool get _hasFullSession => _hasSession && widget.userId2 != null;

  @override
  void initState() {
    super.initState();
    _courseCatalogService =
        widget.courseCatalogService ?? CourseCatalogService();
    _myTimetableService = widget.myTimetableService ?? MyTimetableService();
    _savedTimetableStorage =
        widget.savedTimetableStorage ?? SavedTimetableStorage();
    _now = widget.now ?? DateTime.now;

    final current = _estimateCurrentSemester(_now());
    _year = current.year;
    _semester = current.semester;

    _loadSavedCount();
    if (_hasSession) {
      _loadCatalog();
    }
    if (_hasFullSession) {
      _loadMyTimetable();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCount() async {
    final items = await _savedTimetableStorage.loadAll();
    if (!mounted) return;
    setState(() => _savedCount = items.length);
  }

  Future<void> _loadCatalog() async {
    if (!_hasSession) return;
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final catalog = await _courseCatalogService.fetchCourseCatalog(
        year: _year,
        semester: _semester,
        jsessionId: widget.jsessionId!,
        wmonid: widget.wmonid!,
        icKwa: '%',
        userId: widget.userId2,
      );
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _catalogLoading = false;
      });
    } on CourseCatalogException catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogLoading = false;
        _catalogError = '개설과목을 불러오지 못했어요.';
      });
    }
  }

  Future<void> _loadMyTimetable() async {
    if (!_hasFullSession) return;
    setState(() => _myTimetableLoading = true);
    try {
      final catalog = _catalog.isNotEmpty
          ? _catalog
          : await _courseCatalogService.fetchCourseCatalog(
              year: _year,
              semester: _semester,
              jsessionId: widget.jsessionId!,
              wmonid: widget.wmonid!,
              icKwa: '%',
              userId: widget.userId2,
            );
      final myTimetable = await _myTimetableService.fetchMyTimetable(
        year: _year,
        semester: _semester,
        jsessionId: widget.jsessionId!,
        wmonid: widget.wmonid!,
        userId2: widget.userId2!,
      );
      final matched = matchEnrolledCourses(
        catalog: catalog,
        myTimetable: myTimetable,
      );
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _confirmedCourses = matched.courses
            .map(PlannedCourse.fromCatalogItem)
            .toList();
        _myTimetableLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _myTimetableLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('내 시간표를 불러오지 못했어요.')));
    }
  }

  // Figma 시안(node-id=6-38)에서 드롭다운이 "학기" 필이 아니라 헤더 줄
  // 왼쪽 끝(뒤로가기 화살표 쪽)에 맞춰서 뜬다 — 그 폭을 그대로 흉내낸
  // 고정값. 헤더 Row 자체는 Spacer 때문에 화면 폭만큼 넓어서, 메뉴 폭을
  // renderBox.size에서 그대로 따오면 지나치게 넓어진다.
  static const double _semesterMenuWidth = 180;

  Future<void> _openSemesterMenu() async {
    final renderBox =
        _headerKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (renderBox == null) return;

    final topLeft = renderBox.localToGlobal(
      Offset(0, renderBox.size.height + 8),
      ancestor: overlay,
    );

    final position = RelativeRect.fromRect(
      Rect.fromLTWH(topLeft.dx, topLeft.dy, _semesterMenuWidth, 0),
      Offset.zero & overlay.size,
    );

    final current = _estimateCurrentSemester(_now());
    final options = [for (var i = 1; i >= -3; i--) _stepSemester(current, i)];

    final selected = await showMenu<({int year, int semester})>(
      context: context,
      position: position,
      color: TimetableColors.surfaceElevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        for (final option in options)
          PopupMenuItem(
            value: option,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${option.year}년 ${option.semester}학기',
              style: const TextStyle(
                color: TimetableColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );

    if (!mounted || selected == null) return;
    if (selected.year == _year && selected.semester == _semester) return;

    setState(() {
      _year = selected.year;
      _semester = selected.semester;
      // 학기를 바꾸면 이전 학기 데이터는 더 이상 유효하지 않다 — 그리드/검색
      // 결과를 비우고 새 학기 데이터를 다시 불러온다.
      _confirmedCourses = [];
      _catalog = [];
      _pendingSlot = null;
      _filters.clear();
    });
    if (_hasSession) {
      _loadCatalog();
    }
    if (_hasFullSession) {
      _loadMyTimetable();
    }
  }

  void _onEmptyCellTap(Weekday day, int startHour) {
    setState(() => _pendingSlot = PendingSlot(day: day, startHour: startHour));
  }

  void _clearPendingSlot() {
    setState(() => _pendingSlot = null);
  }

  void _removeCourse(PlannedCourse course) {
    setState(() {
      _confirmedCourses = _confirmedCourses
          .where((c) => c.key != course.key)
          .toList();
    });
  }

  void _addCourse(CourseCatalogItem item) {
    final planned = PlannedCourse.fromCatalogItem(item);
    setState(() {
      _confirmedCourses = [
        ..._confirmedCourses.where((c) => c.key != planned.key),
        planned,
      ];
      _pendingSlot = null;
    });
  }

  /// 규칙 기반 자동 시간표 추천: 외부 AI 호출 없이, 현재 빈 시간대에 완전히
  /// 들어맞는 미확정 개설과목을 앞에서부터 그리디하게 채운다. 이미 확정된
  /// 과목·폐강 과목·그리드 범위(월~금 8~22시) 밖 교시는 후보에서 제외한다.
  void _autoFillSchedule() {
    if (_catalog.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('추천할 개설과목 데이터가 없어요.')));
      return;
    }

    final occupied = <Weekday, List<({int start, int end})>>{
      for (final day in gridWeekdays) day: [],
    };
    for (final course in _confirmedCourses) {
      for (final slot in parseRawSchedule(course.rawSchedule)) {
        final range = assumedPeriodTimes[slot.period];
        if (range == null || !occupied.containsKey(slot.day)) continue;
        occupied[slot.day]!.add((start: range.startMinutes, end: range.endMinutes));
      }
    }

    bool fitsFreely(List<ClassPeriodSlot> slots) {
      for (final slot in slots) {
        if (!occupied.containsKey(slot.day)) return false;
        final range = assumedPeriodTimes[slot.period];
        if (range == null ||
            range.startMinutes < gridStartHour * 60 ||
            range.endMinutes > gridEndHour * 60) {
          return false;
        }
        final overlaps = occupied[slot.day]!.any(
          (r) => range.startMinutes < r.end && range.endMinutes > r.start,
        );
        if (overlaps) return false;
      }
      return true;
    }

    final existingKeys = _confirmedCourses.map((c) => c.key).toSet();
    final picked = <CourseCatalogItem>[];

    for (final item in _catalog) {
      if (item.isClosed) continue;
      final key = '${item.courseCode}-${item.section}';
      if (existingKeys.contains(key)) continue;

      final slots = parseRawSchedule(item.rawSchedule);
      if (slots.isEmpty || !fitsFreely(slots)) continue;

      for (final slot in slots) {
        final range = assumedPeriodTimes[slot.period]!;
        occupied[slot.day]!.add((start: range.startMinutes, end: range.endMinutes));
      }
      picked.add(item);
      existingKeys.add(key);
    }

    if (picked.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('빈 시간대에 맞는 과목을 찾지 못했어요.')));
      return;
    }

    setState(() {
      _confirmedCourses = [
        ..._confirmedCourses,
        ...picked.map(PlannedCourse.fromCatalogItem),
      ];
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${picked.length}과목을 추천해서 채웠어요.')));
  }

  Future<void> _showCourseDetail(CourseCatalogItem item) async {
    await showDialog<void>(
      context: context,
      builder: (_) => CourseDetailDialog(
        course: item,
        onViewSyllabus: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => SyllabusScreen(course: item)),
          );
        },
      ),
    );
  }

  Future<void> _openSaveDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const SaveTimetableDialog(),
    );
    if (name == null) return;

    final saved = SavedTimetable(
      id: _now().millisecondsSinceEpoch.toString(),
      name: name,
      year: _year,
      semester: _semester,
      savedAt: _now(),
      courses: _confirmedCourses,
    );
    await _savedTimetableStorage.save(saved);
    await _loadSavedCount();
  }

  Future<void> _openSavedList() async {
    final selected = await Navigator.of(context).push<SavedTimetable>(
      MaterialPageRoute(
        builder: (_) => SavedTimetablesScreen(storage: _savedTimetableStorage),
      ),
    );
    await _loadSavedCount();
    if (selected == null || !mounted) return;
    setState(() {
      _year = selected.year;
      _semester = selected.semester;
      _confirmedCourses = selected.courses;
      _catalog = [];
      _pendingSlot = null;
      _filters.clear();
    });
    if (_hasSession) {
      _loadCatalog();
    }
  }

  bool _matchesQuery(CourseCatalogItem item) {
    if (_query.isEmpty) return true;
    final q = _query.toLowerCase();
    return item.courseName.toLowerCase().contains(q) ||
        item.courseCode.toLowerCase().contains(q) ||
        item.professor.toLowerCase().contains(q);
  }

  List<CourseCatalogItem> get _filteredResults {
    return _catalog.where((item) {
      if (!_matchesQuery(item)) return false;
      if (!_filters.matches(item)) return false;
      final slot = _pendingSlot;
      if (slot != null &&
          !CourseFilters.matchesSlot(
            item: item,
            day: slot.day,
            startMinutes: slot.startMinutes,
            endMinutes: slot.endMinutes,
          )) {
        return false;
      }
      return true;
    }).toList();
  }

  double get _totalCredits =>
      _confirmedCourses.fold(0.0, (sum, c) => sum + c.credit);

  @override
  Widget build(BuildContext context) {
    final grades = _catalog.map((e) => e.targetGrade).toSet().toList()..sort();
    final courseTypes = _catalog.map((e) => e.courseType).toSet().toList()
      ..sort();
    final credits = _catalog.map((e) => e.credit).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: TimetableColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _bodyHeight = constraints.maxHeight;
            // 그리드 자체가 아니라 "그리드를 제외한 나머지 요소들의 실측
            // 높이"를 기준으로 상한을 계산해서, 핸들을 아무리 당겨도 화면
            // (Column)이 넘치지 않는 값으로만 움직이게 한다.
            final displayedGridHeight = _gridViewportHeight.clamp(
              _minGridViewportHeight,
              _computedMaxGridViewportHeight,
            );
            _scheduleChromeMeasurement(displayedGridHeight);

            return Column(
              children: [
                Column(
                  key: _chromeAboveGridKey,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                      child: TimetableHeader(
                        semesterLabel: '$_year년 $_semester학기',
                        totalCredits: _totalCredits,
                        savedCount: _savedCount,
                        headerKey: _headerKey,
                        onBack: () => Navigator.of(context).pop(),
                        onSemesterTap: _openSemesterMenu,
                        onSave: _openSaveDialog,
                        onOpenSavedList: _openSavedList,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: QuickActionsRow(
                        loading: _myTimetableLoading,
                        onLoadMyTimetable: _loadMyTimetable,
                        notificationsEnabled: _notificationsEnabled,
                        onNotificationsChanged: (v) =>
                            setState(() => _notificationsEnabled = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                Padding(
                  key: _gridWrapperKey,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TimetableGrid(
                    courses: _confirmedCourses,
                    pendingSlot: _pendingSlot,
                    onEmptyCellTap: _onEmptyCellTap,
                    onRemoveCourse: _removeCourse,
                    onAutoFill: _autoFillSchedule,
                    viewportHeight: displayedGridHeight,
                  ),
                ),
                Column(
                  key: _chromeBelowGridKey,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: (details) {
                        setState(() {
                          _gridViewportHeight =
                              (_gridViewportHeight + details.delta.dy).clamp(
                                _minGridViewportHeight,
                                _computedMaxGridViewportHeight,
                              );
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: TimetableColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: SearchFilterBar(
                        controller: _searchController,
                        onQueryChanged: (q) => setState(() => _query = q),
                        filters: _filters,
                        filterPanelOpen: _filterPanelOpen,
                        onToggleFilterPanel: () =>
                            setState(() => _filterPanelOpen = !_filterPanelOpen),
                        onFiltersChanged: () => setState(() {}),
                        availableGrades: grades,
                        availableCourseTypes: courseTypes,
                        availableCredits: credits,
                        pendingSlot: _pendingSlot,
                        onClearPendingSlot: _clearPendingSlot,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                Expanded(child: _buildResultsList()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_hasSession) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '로그인 세션이 없어 과목을 검색할 수 없어요.\n다시 로그인해주세요.',
            textAlign: TextAlign.center,
            style: TextStyle(color: TimetableColors.textSecondary),
          ),
        ),
      );
    }

    if (_catalogLoading) {
      return const Center(
        child: CircularProgressIndicator(color: TimetableColors.accent),
      );
    }

    if (_catalogError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _catalogError!,
              style: const TextStyle(color: TimetableColors.textSecondary),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadCatalog, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final results = _filteredResults;
    if (results.isEmpty) {
      return const Center(
        child: Text(
          '검색 결과가 없어요',
          style: TextStyle(color: TimetableColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return CourseResultCard(
          course: item,
          onTap: () => _showCourseDetail(item),
          showAddButtons: _pendingSlot != null,
          onAdd: () => _addCourse(item),
        );
      },
    );
  }
}
