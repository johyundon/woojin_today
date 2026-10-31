import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../services/class_schedule_parser.dart';
import '../../services/course_catalog_service.dart';
import '../../services/my_enrolled_courses.dart';
import '../../services/my_timetable_service.dart';
import '../../services/service_factory.dart';
import '../../services/session_cache.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import '../home/widgets/home_bottom_nav.dart';
import 'ai_recommend/ai_recommend_result_screen.dart';
import 'ai_recommend/ai_recommend_wizard_screen.dart';
import 'course_filters.dart';
import 'models/ai_recommend_answers.dart';
import 'models/planned_course.dart';
import 'models/saved_timetable.dart';
import 'services/ai_recommend_service.dart';
import 'services/saved_timetable_storage.dart';
import 'syllabus_screen.dart';
import 'saved_timetables_screen.dart';
import 'timetable_colors.dart';
import 'widgets/course_add_panel.dart';
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
    this.onTabTap,
  });

  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  /// 테스트에서 mock 주입용. [HomeScreen]과 동일한 패턴.
  final CourseCatalogServiceBase? courseCatalogService;
  final MyTimetableServiceBase? myTimetableService;
  final SavedTimetableStorage? savedTimetableStorage;
  final DateTime Function()? now;

  /// 하단 탭 바를 눌렀을 때 호출된다(홈이 그 탭 화면으로 바꿔 준다). 없으면 이전
  /// 화면으로 돌아가기만 한다.
  final ValueChanged<int>? onTabTap;

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
        widget.courseCatalogService ?? ServiceFactory.courseCatalog();
    _myTimetableService =
        widget.myTimetableService ?? ServiceFactory.myTimetable();
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
    _searchFocusNode.dispose();
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
    final now = _now();
    return Scaffold(
      // 키보드 양옆 둥근 모서리 틈으로 Scaffold 바탕이 비쳐 파랑이 보이지
      // 않도록, 바탕은 흰색으로 두고 파랑은 body 영역에만 깐다.
      backgroundColor: Colors.white,
      extendBody: true,
      bottomNavigationBar: _addPanelOpen
          ? null
          : HomeBottomNav(selectedIndex: 0, onTap: _onTabTap),
      body: ColoredBox(
        color: AppColors.cobalt,
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                child: TimetableHeader(
                  semesterLabel: '$_year년 $_semester학기',
                  totalCredits: _totalCredits,
                  savedCount: _savedCount,
                  headerKey: _headerKey,
                  onBack: () => Navigator.of(context).pop(),
                  onSemesterTap: _openSemesterMenu,
                  onSave: _openSaveDialog,
                  onOpenSavedList: _openSavedList,
                  onAutoFill: _openAiRecommendWizard,
                  onAddCourse: () =>
                      setState(() => _addPanelOpen = !_addPanelOpen),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                  child: ColoredBox(
                    color: TimetableColors.panelBackground,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _bodyHeight = constraints.maxHeight;
                        // 그리드 자체가 아니라 "그리드를 제외한 나머지 요소들의
                        // 실측 높이"를 기준으로 상한을 계산해서, 핸들을 아무리
                        // 당겨도 화면(Column)이 넘치지 않는 값으로만 움직이게
                        // 한다.
                        final panelHeight = constraints.maxHeight * 0.75;
                        final displayedGridHeight =
                            _computedMaxGridViewportHeight(
                              filterPanelOpen: false,
                              extraReserve: _addPanelOpen ? panelHeight : 0,
                            );
                        _scheduleChromeMeasurement(displayedGridHeight);

                        final gridColumn = Column(
                          children: [
                            Column(
                              key: _chromeAboveGridKey,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 18),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: QuickActionsRow(
                                    loading: _myTimetableLoading,
                                    onLoadMyTimetable: _loadMyTimetable,
                                    notificationsEnabled: _notificationsEnabled,
                                    onNotificationsChanged: (v) => setState(
                                      () => _notificationsEnabled = v,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                            Padding(
                              key: _gridWrapperKey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: TimetableGrid(
                                courses: _confirmedCourses,
                                pendingSlot: _pendingSlot,
                                onEmptyCellTap: _onEmptyCellTap,
                                onRemoveCourse: _removeCourse,
                                onCourseTap: (course) =>
                                    _showCourseDetail(course.toCatalogItem()),
                                today: Weekday.values[now.weekday - 1],
                                viewportHeight: displayedGridHeight,
                              ),
                            ),
                            // 하단 탭 바(extendBody)에 그리드가 가려지지 않도록 남기는 여백.
                            // 그리드 최대 높이 계산을 위해 실측 키를 그대로 붙인다.
                            SizedBox(
                              key: _chromeBelowGridKey,
                              height: _addPanelOpen ? 0 : 100,
                            ),
                          ],
                        );

                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            gridColumn,
                            if (_addPanelOpen)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                height: panelHeight,
                                child: _buildAddPanel(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPanel() {
    final grades = _catalog.map((e) => e.targetGrade).toSet().toList()..sort();
    final courseTypes = _catalog.map((e) => e.courseType).toSet().toList()
      ..sort();
    // 3.0 넘는 학점(복수전공/논문 등 예외적인 값)은 필터 옵션에서 숨긴다 —
    // 사용자 요청.
    final credits =
        _catalog.map((e) => e.credit).where((c) => c <= 3.0).toSet().toList()
          ..sort();
    final areas =
        _catalog
            .map((e) => extractArea(e.courseType))
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();

    return CourseAddPanel(
      onClose: () => setState(() => _addPanelOpen = false),
      searchFilterBar: SearchFilterBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onQueryChanged: (q) => setState(() => _query = q),
        filters: _filters,
        filterPanelOpen: _filterPanelOpen,
        onToggleFilterPanel: () =>
            setState(() => _filterPanelOpen = !_filterPanelOpen),
        onFiltersChanged: () => setState(() {}),
        availableGrades: grades,
        availableCourseTypes: courseTypes,
        availableCredits: credits,
        availableAreas: areas,
        pendingSlot: _pendingSlot,
        onClearPendingSlot: _clearPendingSlot,
      ),
      results: _buildResultsList(),
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
            Pressable.effect(
              child: TextButton(
                onPressed: () => _loadCatalog(forceRefresh: true),
                child: const Text('다시 시도'),
              ),
            ),
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
        );
      },
    );
  }

  /// 하단 탭 바를 눌렀을 때. 0(시간표)은 이미 이 화면이라 아무것도 하지 않는다.
  /// 다른 탭은 홈이 넘겨준 [TimetableScreen.onTabTap]으로 그 탭 화면으로 바꾼다
  /// (세션/콜백을 가진 쪽이 홈이라서). 콜백이 없으면 이전 화면으로 돌아간다.
  void _onTabTap(int index) {
    if (index == 0) return;
    final onTabTap = widget.onTabTap;
    if (onTabTap != null) {
      onTabTap(index);
    } else {
      Navigator.of(context).pop();
    }
  }
}
