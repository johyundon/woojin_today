import 'package:flutter/material.dart';

import '../../services/class_schedule_parser.dart';
import '../../services/course_catalog_service.dart';
import '../../services/my_enrolled_courses.dart';
import '../../services/my_timetable_service.dart';
import 'course_filters.dart';
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
  final _semesterKey = GlobalKey();

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
      debugPrint(
        '[Timetable] _loadCatalog 완료: year=$_year semester=$_semester '
        'catalog.length=${catalog.length}',
      );
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

  Future<void> _openSemesterMenu() async {
    final renderBox =
        _semesterKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (renderBox == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(
          Offset(0, renderBox.size.height + 8),
          ancestor: overlay,
        ),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(const Offset(160, 8)),
          ancestor: overlay,
        ),
      ),
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
            child: Text(
              '${option.year}년 ${option.semester}학기',
              style: const TextStyle(color: TimetableColors.textPrimary),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
              child: TimetableHeader(
                semesterLabel: '$_year년 $_semester학기',
                totalCredits: _totalCredits,
                savedCount: _savedCount,
                semesterKey: _semesterKey,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TimetableGrid(
                courses: _confirmedCourses,
                pendingSlot: _pendingSlot,
                onEmptyCellTap: _onEmptyCellTap,
                onRemoveCourse: _removeCourse,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: TimetableColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
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
            Expanded(child: _buildResultsList()),
          ],
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
    debugPrint(
      '[Timetable] _buildResultsList: catalog.length=${_catalog.length} '
      'results.length=${results.length} query="$_query" '
      'filters.isDefault=${_filters.isDefault} pendingSlot=$_pendingSlot',
    );
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
