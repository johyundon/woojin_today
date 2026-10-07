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

part 'timetable_session_mixin.dart';
part 'timetable_data_loading_mixin.dart';
part 'timetable_course_mixin.dart';
part 'timetable_semester_mixin.dart';
part 'timetable_save_load_mixin.dart';
part 'timetable_grid_resize_mixin.dart';

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

class _TimetableScreenState extends State<TimetableScreen>
    with
        TimetableSessionMixin,
        TimetableDataLoadingMixin,
        TimetableCourseMixin,
        TimetableSemesterMixin,
        TimetableSaveLoadMixin,
        TimetableGridResizeMixin {
  // TODO: 실제 수업 시간 알림(로컬 알림 스케줄링)은 구현돼 있지 않다. 이
  // 토글은 디자인(상태 1~10 공통 헤더)에 맞춘 UI 상태만 갖고 있다 — 알림
  // 관련 패키지/권한 처리는 이번 작업 범위 밖이라 추측으로 구현하지 않았다.
  bool _notificationsEnabled = true;

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
          onAdd: () => _addCourse(item),
          onViewDetail: () => _showCourseDetail(item),
          showAddButtons: _pendingSlot != null,
        );
      },
    );
  }
}
