import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../services/class_schedule_parser.dart';
import '../../services/course_catalog_service.dart';
import '../../services/graduation_credit_service.dart';
import '../../services/department_codes.dart';
import '../../services/my_timetable_service.dart';
import '../../services/notification_service.dart';
import '../../services/service_factory.dart';
import '../../services/session_cache.dart';
import '../../services/student_info_service.dart';
import '../../services/syllabus_service.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import '../home/widgets/home_bottom_nav.dart';
import 'ai_recommend/ai_recommend_result_screen.dart';
import 'ai_recommend/ai_recommend_wizard_screen.dart';
import 'course_filters.dart';
import 'models/ai_recommend_answers.dart';
import 'grid_layout.dart';
import 'models/planned_course.dart';
import 'models/saved_timetable.dart';
import 'services/ai_recommend_service.dart';
import 'services/class_reminder_planner.dart';
import 'services/class_reminder_settings.dart';
import 'services/saved_timetable_storage.dart';
import 'syllabus_screen.dart';
import 'saved_timetables_screen.dart';
import 'timetable_colors.dart';
import 'widgets/course_add_panel.dart';
import 'widgets/course_detail_dialog.dart';
import 'widgets/course_remove_dialog.dart';
import 'widgets/course_result_card.dart';
import 'widgets/course_result_tile.dart';
import 'widgets/my_timetable_status_bar.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/save_timetable_dialog.dart';
import 'widgets/search_panel.dart';
import 'widgets/timetable_grid.dart';
import 'widgets/timetable_header.dart';
import 'widgets/timetable_notice_dialog.dart';
import 'widgets/timetable_edit_bar.dart';
import 'widgets/timetable_top_bar.dart';

part 'timetable_session_mixin.dart';
part 'timetable_data_loading_mixin.dart';
part 'timetable_course_mixin.dart';
part 'timetable_semester_mixin.dart';
part 'timetable_save_load_mixin.dart';
part 'timetable_grid_resize_mixin.dart';
part 'timetable_reminder_mixin.dart';

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
    this.syllabusService,
    this.studentInfoService,
    this.savedTimetableStorage,
    this.notificationService,
    this.classReminderSettings,
    this.now,
    this.onTabTap,
    this.graduationCreditService,
  });

  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  /// 테스트에서 mock 주입용. [HomeScreen]과 동일한 패턴.
  final CourseCatalogServiceBase? courseCatalogService;
  final MyTimetableServiceBase? myTimetableService;
  final SyllabusServiceBase? syllabusService;

  /// 자동 생성이 내 학과·학년을 읽을 때 쓴다(없으면 실제 서비스).
  final StudentInfoServiceBase? studentInfoService;
  final SavedTimetableStorage? savedTimetableStorage;
  final NotificationService? notificationService;
  final ClassReminderSettings? classReminderSettings;
  final DateTime Function()? now;

  /// 맨 아래 "전체 학점 52 / 128"을 읽을 때 쓴다(없으면 실제 서비스).
  final GraduationCreditServiceBase? graduationCreditService;

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
        TimetableGridResizeMixin,
        TimetableReminderMixin,
        SingleTickerProviderStateMixin {
  // 과목 추가 패널이 아래에서 미끄러져 올라오고 내려가게 하는 애니메이션.
  // 닫히는 동안에도 패널을 남겨 두었다가, 다 내려간 뒤에 탭 바를 다시 보인다.
  late final AnimationController _addPanelController =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 340),
        reverseDuration: const Duration(milliseconds: 240),
      )..addStatusListener((_) {
        if (mounted) setState(() {});
      });
  late final Animation<Offset> _addPanelOffset =
      Tween(begin: const Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _addPanelController,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  bool get _addPanelShown => _addPanelOpen || !_addPanelController.isDismissed;

  /// 상단을 시안(Figma 2152-1429)처럼 "시간표 [학기 칩] ✏️ ⋮" 한 줄로 쓸지
  /// (사용자 결정 2026-11-16). false면 예전 [TimetableHeader]다(안 쓰지만
  /// 지우지 않고 남겨 둔다).
  static const bool _useFigmaTopBar = true;

  /// 졸업학점 현황의 전체 이수 학점·졸업 기준 학점. 못 받으면 null이고, 맨 아래
  /// 학점 줄에서 "전체 학점" 부분만 빠진다.
  int? _earnedTotalCredits;
  int? _requiredTotalCredits;

  Future<void> _loadTotalCredits() async {
    final userId2 = widget.userId2;
    if (userId2 == null) return;
    try {
      final summary =
          await (widget.graduationCreditService ?? GraduationCreditService())
              .fetchSummary(userId2: userId2);
      if (!mounted) return;
      setState(() {
        _earnedTotalCredits = summary.totalEarned;
        _requiredTotalCredits = summary.totalRequired;
      });
    } catch (e) {
      debugPrint('[Timetable] 전체 학점을 못 받았어요: $e');
    }
  }

  /// 햄버거를 눌렀을 때 예전 ⋮ 메뉴 시트(불러오기·자동 생성·저장·저장 목록)를
  /// 띄울지. 지금은 저장한 시간표 목록을 바로 연다(안 쓰지만 남겨 둔다).
  static const bool _useMoreMenu = false;

  /// "시간표 만들기" 편집 화면인지(과목 추가 시트가 열려 있음, 새 상단에서만).
  bool get _editMode => _useFigmaTopBar && _addPanelOpen;

  /// 시트가 멈추는 높이(화면 높이 비율, 낮은 것부터). 피드백 반영
  /// (2026-11-16): 15%·25%·50%·90%. 예전 시안(2272-18343)은 30%·61% 두 단계.
  static const List<double> _sheetStops = [0.15, 0.25, 0.5, 0.9];
  static const double _sheetMinFraction = 0.15;
  static const double _sheetMaxFraction = 0.9;

  /// 시간표 만들기를 열 때(과목 블록을 눌러 열 때도) 시트 높이.
  static const double _sheetStartFraction = 0.25;
  double _sheetFraction = _sheetStartFraction;

  void _onSheetDragUpdate(double dy) {
    final h = MediaQuery.sizeOf(context).height;
    setState(() {
      _sheetFraction = (_sheetFraction - dy / h).clamp(
        _sheetMinFraction,
        _sheetMaxFraction,
      );
    });
  }

  /// 펼친 과목 줄(담기·강의계획서 버튼 포함).
  final _expandedTileKey = GlobalKey();

  /// 시트가 낮으면(15%·25%) 펼친 과목의 버튼이 목록 아래로 밀려 안 보여서,
  /// 펼친 줄 아래 끝이 보이게 목록을 살짝 올린다.
  void _revealExpandedTile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tile = _expandedTileKey.currentContext;
      if (!mounted || tile == null) return;
      Scrollable.ensureVisible(
        tile,
        duration: const Duration(milliseconds: 200),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  /// 손을 떼면 가장 가까운 멈춤 높이에 붙인다. 빠르게 튕기면(초당 300 넘게)
  /// 그 방향의 다음 멈춤 높이로 간다.
  void _onSheetDragEnd(double velocity) {
    final current = _sheetFraction;
    double target;
    if (velocity < -300) {
      target = _sheetStops.firstWhere(
        (s) => s > current + 0.01,
        orElse: () => _sheetStops.last,
      );
    } else if (velocity > 300) {
      target = _sheetStops.lastWhere(
        (s) => s < current - 0.01,
        orElse: () => _sheetStops.first,
      );
    } else {
      target = _sheetStops.reduce(
        (a, b) => (a - current).abs() <= (b - current).abs() ? a : b,
      );
    }
    setState(() => _sheetFraction = target);
  }

  String get _creditsText {
    final credits = _totalCredits;
    return credits == credits.roundToDouble()
        ? credits.toInt().toString()
        : credits.toString();
  }

  /// ⋮ 메뉴를 열고 고른 일을 한다.
  Future<void> _openMoreMenu() async {
    final action = await showTimetableMoreSheet(
      context,
      showLoadMine: !_catalogNotReady,
      savedCount: _savedCount,
    );
    if (!mounted || action == null) return;
    switch (action) {
      case TimetableMoreAction.loadMine:
        await _loadMyTimetable(announce: true);
      case TimetableMoreAction.autoFill:
        _openAiRecommendWizard();
      case TimetableMoreAction.save:
        await _openSaveDialog();
      case TimetableMoreAction.savedList:
        await _openSavedList();
    }
  }

  /// 시간표가 비어 있을 때 격자 가운데 뜨는 안내와 "시간표 만들기" 버튼(시안).
  Widget _emptyTimetablePrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 시안 캡처 크기(안내 약 13, 버튼 약 120x38)에 맞춤(2026-11-16).
        const Text(
          '시간표를 만들어 주세요',
          style: TextStyle(
            color: AppColors.textSub,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Pressable(
          key: const ValueKey('timetable-create'),
          onTap: () => _setAddPanelOpen(true),
          child: Container(
            width: 120,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '시간표 만들기',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 시간표 격자. 시간표가 비어 있으면(새 화면에서) 가로줄 없이 가운데에
  /// "시간표를 만들어 주세요" 안내를 띄운다(시안).
  Widget _gridWithEmptyPrompt(DateTime now, double viewportHeight) {
    final empty =
        _useFigmaTopBar &&
        _confirmedCourses.isEmpty &&
        _pendingSlot == null &&
        !_myTimetableLoading &&
        !_addPanelOpen;
    return Stack(
      children: [
        TimetableGrid(
          courses: _confirmedCourses,
          pendingSlot: _pendingSlot,
          onEmptyCellTap: _readOnlyNote != null ? (_, _) {} : _onEmptyCellTap,
          onCourseTap: (course) => _onGridCourseTap(course.toCatalogItem()),
          today: Weekday.values[now.weekday - 1],
          viewportHeight: viewportHeight,
          showHourLines: !empty,
          onCourseRemove: _editMode ? _confirmRemoveCourse : null,
          previewCourse: _gridPreviewCourse,
          scrollController: _gridScroll,
        ),
        if (empty)
          Positioned.fill(child: Center(child: _emptyTimetablePrompt())),
      ],
    );
  }

  /// 맨 아래 "이번 학기 15 학점 | 전체 학점 52 / 128" 줄(시안).
  Widget _creditSummaryBar() {
    final credits = _totalCredits;
    final thisSemester = credits == credits.roundToDouble()
        ? credits.toInt().toString()
        : credits.toString();
    const label = TextStyle(
      color: AppColors.textSub,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    const value = TextStyle(
      color: AppColors.textStrong,
      fontSize: 15,
      fontWeight: FontWeight.w800,
    );
    final earned = _earnedTotalCredits;
    final required = _requiredTotalCredits;
    return Container(
      key: const ValueKey('timetable-credit-bar'),
      height: 44,
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      // 판 한가운데(가로·세로 모두)에 놓는다(사용자 요청, 2026-11-16). 글자들은
      // 한 덩어리 글(Text.rich)로 묶어 아랫선이 맞게 한다.
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: '이번 학기 ', style: label),
                TextSpan(text: '$thisSemester 학점', style: value),
              ],
            ),
          ),
          if (earned != null) ...[
            Container(
              width: 1,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: AppColors.checkLine,
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: '전체 학점 ', style: label),
                  TextSpan(text: '$earned', style: value),
                  if (required != null)
                    TextSpan(text: ' / $required', style: label),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _setAddPanelOpen(bool open) {
    final wasOpen = _addPanelOpen;
    setState(() {
      _addPanelOpen = open;
      if (open) {
        _sheetFraction = _sheetStartFraction;
        if (!wasOpen) _editStartCourses = _confirmedCourses;
      }
      if (!open) {
        _pinnedCourse = null;
        _expandedCourseKey = null;
        _previewCourse = null;
      }
    });
    open ? _addPanelController.forward() : _addPanelController.reverse();
  }

  /// "시간표 만들기" 화면을 연 뒤 과목을 담거나 뺐는지(순서는 따지지 않음).
  bool get _hasUnsavedEdits {
    final before = _editStartCourses.map((c) => c.key).toSet();
    final now = _confirmedCourses.map((c) => c.key).toSet();
    return before.length != now.length || !before.containsAll(now);
  }

  /// "시간표 만들기" 화면의 뒤로가기. 바뀐 게 있으면 시안의 확인창
  /// (AppConfirmModal "작성 중인 내용이 있어요")을 띄우고, "나가기"를 고르면
  /// 연 때의 과목 목록으로 되돌린 뒤 닫는다(2026-11-16).
  Future<void> _onEditBack() async {
    if (_hasUnsavedEdits) {
      final leave = await showAppConfirmModal(
        context,
        title: '작성 중인 내용이 있어요',
        message: '지금 나가면 내용이 저장되지 않아요.',
        cancelLabel: '계속 작성',
        confirmLabel: '나가기',
        cancelKey: const ValueKey('edit-leave-cancel'),
        confirmKey: const ValueKey('edit-leave-confirm'),
      );
      if (!leave || !mounted) return;
      setState(() => _confirmedCourses = _editStartCourses);
    }
    _setAddPanelOpen(false);
  }

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
    _loadReminderSetting();
    if (_useFigmaTopBar) _loadTotalCredits();
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
    _addPanelController.dispose();
    _resultsScroll.dispose();
    _gridScroll.dispose();
    super.dispose();
  }

  Future<void> _showCourseDetail(CourseCatalogItem item) async {
    item = _withCatalogEnrollment(item);
    await showDialog<void>(
      context: context,
      barrierColor: TimetableColors.barrier,
      builder: (_) => CourseDetailDialog(
        course: item,
        onViewSyllabus: () {
          Navigator.of(context).pop();
          _openSyllabus(item);
        },
      ),
    );
  }

  /// 블록의 "×"를 누르면 "삭제하시겠습니까?"를 묻고, 삭제를 누를 때만 뺀다.
  Future<void> _confirmRemoveCourse(PlannedCourse course) async {
    final ok = await showCourseRemoveDialog(context);
    if (!ok || !mounted) return;
    _removeCourse(course);
    // 목록에서 펼쳐 둔 과목의 회색 미리보기가 빈자리에 남아 지운 과목이
    // 남은 것처럼 보이지 않게, 과목을 빼면 펼침·미리보기도 접는다
    // (사용자 요청, 2026-11-26).
    setState(() {
      _expandedCourseKey = null;
      _previewCourse = null;
    });
  }

  /// 시간표에 담긴 과목은 정원·담은 인원·학년이 없을 수 있어서(학교의 내
  /// 시간표 응답에는 없다), 지금 학기 개설과목 목록에 같은 과목·분반이 있으면
  /// 그 값으로 채운다(개설학과 등 나머지는 그대로).
  CourseCatalogItem _withCatalogEnrollment(CourseCatalogItem item) {
    if (item.capacity != 0 && item.targetGrade.trim().isNotEmpty) return item;
    for (final c in _catalog) {
      if (c.courseCode == item.courseCode && c.section == item.section) {
        return item.withEnrollment(
          capacity: item.capacity == 0 ? c.capacity : item.capacity,
          enrolled: item.capacity == 0 ? c.waitlistCount : item.waitlistCount,
          targetGrade: item.targetGrade.trim().isEmpty
              ? c.targetGrade
              : item.targetGrade,
        );
      }
    }
    return item;
  }

  void _openSyllabus(CourseCatalogItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SyllabusScreen(
          course: item,
          year: _year,
          semester: _semester,
          jsessionId: widget.jsessionId,
          wmonid: widget.wmonid,
          userId2: widget.userId2,
          syllabusService: widget.syllabusService,
        ),
      ),
    );
  }

  /// "시간표 만들기" 시트에서 펼쳐 둔 과목(과목코드+분반). 시간표 격자의 과목을
  /// 누르면 그 과목이 시트 맨 위에 펼쳐진 채 나온다(팝업 대신, 2026-11-16).
  String? _expandedCourseKey;
  CourseCatalogItem? _pinnedCourse;

  /// 목록에서 눌러 펼친 과목. 아직 담지 않았으면 격자에 들어갈 자리를 회색으로
  /// 미리 보여 준다(사용자 요청, 2026-11-19).
  CourseCatalogItem? _previewCourse;
  final _gridScroll = ScrollController();

  /// 격자에 그릴 미리보기 과목. 시트가 열려 있고, 그 과목이 지금 펼쳐져 있고,
  /// 아직 담지 않았을 때만.
  PlannedCourse? get _gridPreviewCourse {
    final item = _previewCourse;
    if (!_addPanelOpen || item == null) return null;
    if (_expandedCourseKey != _courseKey(item) || _isAdded(item)) return null;
    return PlannedCourse.fromCatalogItem(item);
  }

  /// 목록의 과목 줄을 눌렀을 때. 펼치면서 그 과목이 이미 담은 과목과 시간이
  /// 겹치면 알림창을 먼저 띄운다(사용자 요청, 2026-11-26): "확인"이면 겹치는
  /// 기존 과목을 빼고 이 과목을 담고, "취소"면 아무것도 바꾸지 않는다.
  Future<void> _onResultTileTap(CourseCatalogItem item) async {
    final key = _courseKey(item);
    if (_expandedCourseKey == key) {
      setState(() {
        _expandedCourseKey = null;
        _previewCourse = null;
      });
      return;
    }
    if (_conflictsWith(item).isNotEmpty) {
      final added = await _addCourseResolvingConflicts(item);
      if (!added || !mounted) return;
    }
    setState(() {
      _expandedCourseKey = key;
      _previewCourse = item;
    });
    _revealExpandedTile();
    _revealPreviewOnGrid();
  }

  /// 이미 담은 과목 중 [item]과 시간이 겹치는 것(같은 과목의 다른 분반은 담을 때
  /// 어차피 바뀌므로 뺀다).
  List<PlannedCourse> _conflictsWith(CourseCatalogItem item) {
    final slots = parseRawSchedule(item.rawSchedule);
    return _confirmedCourses.where((c) {
      if (c.courseCode == item.courseCode) return false;
      return parseRawSchedule(c.rawSchedule).any(
        (a) => slots.any(
          (b) =>
              a.day == b.day &&
              a.startMinutes < b.endMinutes &&
              b.startMinutes < a.endMinutes,
        ),
      );
    }).toList();
  }

  /// 과목을 담는다. 시간이 겹치는 과목이 있으면 확인창을 띄우고, "확인"이면
  /// 겹치는 기존 과목을 뺀 뒤 담는다. 담았으면 true.
  Future<bool> _addCourseResolvingConflicts(CourseCatalogItem item) async {
    final conflicts = _conflictsWith(item);
    if (conflicts.isNotEmpty) {
      final names = conflicts.map((c) => c.courseName).join(', ');
      final ok = await showCourseConflictDialog(
        context,
        existingNames: names,
        newName: item.courseName,
      );
      if (!ok || !mounted) return false;
      setState(() {
        final keys = conflicts.map((c) => c.key).toSet();
        _confirmedCourses = _confirmedCourses
            .where((c) => !keys.contains(c.key))
            .toList();
      });
    }
    _addCourse(item);
    return true;
  }

  /// 미리보기 블록이 격자 화면 밖(위·아래)에 있으면 첫 블록이 보이게 격자를
  /// 스크롤한다.
  void _revealPreviewOnGrid() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preview = _gridPreviewCourse;
      if (!mounted || preview == null || !_gridScroll.hasClients) return;
      final layouts = buildBlockLayouts([preview]);
      if (layouts.isEmpty) return;
      final start = layouts.map((l) => l.startMinutes).reduce(math.min);
      final end = layouts
          .where((l) => l.startMinutes == start)
          .map((l) => l.endMinutes)
          .reduce(math.max);
      final top = (start - gridStartHour * 60) / 60 * gridHourRowHeight;
      final bottom = (end - gridStartHour * 60) / 60 * gridHourRowHeight;
      final position = _gridScroll.position;
      final viewTop = position.pixels;
      final viewBottom = viewTop + position.viewportDimension;
      double? target;
      if (top < viewTop) {
        target = top - 8;
      } else if (bottom > viewBottom) {
        target = bottom - position.viewportDimension + 8;
      }
      if (target == null) return;
      _gridScroll.animateTo(
        target.clamp(0, position.maxScrollExtent),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }
  final _resultsScroll = ScrollController();

  String _courseKey(CourseCatalogItem item) =>
      '${item.courseCode}-${item.section}';

  bool _isAdded(CourseCatalogItem item) => _confirmedCourses.any(
    (c) => c.courseCode == item.courseCode && c.section == item.section,
  );

  /// 시간표 격자의 과목을 눌렀을 때. 팝업 대신 "시간표 만들기"(편집 화면)를
  /// 열고 아래 시트 맨 위에 그 과목을 펼쳐 보여 준다(일반 화면에서 눌러도 같음,
  /// 사용자 요청 2026-11-16). 예전 화면([_useFigmaTopBar]가 false)은 팝업 그대로.
  void _onGridCourseTap(CourseCatalogItem item) {
    if (!_useFigmaTopBar) {
      _showCourseDetail(item);
      return;
    }
    item = _withCatalogEnrollment(item);
    if (!_addPanelOpen) _setAddPanelOpen(true);
    setState(() {
      _pinnedCourse = item;
      _expandedCourseKey = _courseKey(item);
      // 시트는 처음 높이로 두고(사용자 요청, 2026-11-16), 목록을 맨 위로 올려
      // 고른 과목이 바로 보이게 한다.
      _sheetFraction = _sheetStartFraction;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultsScroll.hasClients) _resultsScroll.jumpTo(0);
      _revealExpandedTile();
    });
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
    // 거의 흰 바탕이라 상태 표시줄 글자를 어둡게 둔다(앱 테마는 아직 어두운 테마).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        extendBody: true,
        bottomNavigationBar: _addPanelShown
            ? null
            : HomeBottomNav(selectedIndex: 0, onTap: _onTabTap),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (_editMode)
                TimetableEditBar(
                  creditsLabel: '$_creditsText학점',
                  onBack: _onEditBack,
                  onSave: _openSaveDialog,
                )
              else if (_useFigmaTopBar)
                TimetableTopBar(
                  semesterLabel: '$_year년 $_semester학기',
                  semesterKey: _headerKey,
                  onSemesterTap: _openSemesterMenu,
                  // 햄버거는 예전처럼 저장한 시간표 목록을 바로 연다(사용자 요청,
                  // 2026-11-16). 불러오기·자동 생성·저장은 "시간표 만들기" 화면에 있다.
                  onMoreTap: _useMoreMenu ? _openMoreMenu : _openSavedList,
                  // 시안: 시간표가 비어 있으면 연필 대신 "시간표 만들기" 버튼.
                  // 과목 추가 창이 열려 있으면 닫을 수 있게 연필을 둔다.
                  onEditTap: _confirmedCourses.isEmpty && !_addPanelOpen
                      ? null
                      : () => _setAddPanelOpen(!_addPanelOpen),
                )
              else
                TimetableHeader(
                  semesterLabel: '$_year년 $_semester학기',
                  totalCredits: _totalCredits,
                  savedCount: _savedCount,
                  headerKey: _headerKey,
                  onBack: () => Navigator.of(context).pop(),
                  onSemesterTap: _openSemesterMenu,
                  onSave: _openSaveDialog,
                  readOnlyNote: _readOnlyNote,
                  onOpenSavedList: _openSavedList,
                  onAutoFill: _openAiRecommendWizard,
                  onAddCourse: () => _setAddPanelOpen(!_addPanelOpen),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _bodyHeight = constraints.maxHeight;
                    // 그리드 자체가 아니라 "그리드를 제외한 나머지 요소들의
                    // 실측 높이"를 기준으로 상한을 계산해서, 핸들을 아무리
                    // 당겨도 화면(Column)이 넘치지 않는 값으로만 움직이게
                    // 한다.
                    // 시안(2272-18343): 시트는 화면 높이의 최소 30%~최대 61% 사이를
                    // 손잡이로 끌어 오간다. 격자 높이는 최소 높이만 비워 두고,
                    // 시트를 더 올리면 격자 위로 겹쳐 덮는다(시안 "최대").
                    final screenHeight = MediaQuery.sizeOf(context).height;
                    // 90%는 상단 바 아래 영역보다 클 수 있어, 손잡이가 잘리지
                    // 않게 그 영역 높이를 넘지 않게 한다.
                    final panelHeight = _useFigmaTopBar
                        ? math.min(
                            screenHeight * _sheetFraction,
                            constraints.maxHeight,
                          )
                        : constraints.maxHeight * 0.75;
                    final reserveHeight = _useFigmaTopBar
                        ? screenHeight * _sheetMinFraction
                        : panelHeight;
                    final displayedGridHeight = _computedMaxGridViewportHeight(
                      filterPanelOpen: false,
                      extraReserve: _addPanelOpen ? reserveHeight : 0,
                    );
                    _scheduleChromeMeasurement(displayedGridHeight);

                    final gridColumn = Column(
                      children: [
                        Column(
                          key: _chromeAboveGridKey,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_editMode)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  12,
                                  18,
                                  0,
                                ),
                                child: TimetableEditActions(
                                  // 시안처럼 "자동 생성" 옆에 늘 둔다(사용자 요청,
                                  // 2026-11-16: 개설과목이 아직 없는 학기라고 빼지 않음).
                                  showLoadMine: true,
                                  loading: _myTimetableLoading,
                                  onLoadMine: () =>
                                      _loadMyTimetable(announce: true),
                                  onAutoFill: _openAiRecommendWizard,
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  14,
                                  22,
                                  0,
                                ),
                                child: QuickActionsRow(
                                  loading: _myTimetableLoading,
                                  onLoadMyTimetable: () =>
                                      _loadMyTimetable(announce: true),
                                  // 새 상단에서는 "내 시간표 불러오기"가 ⋮ 메뉴로
                                  // 옮겨 가서, 이 줄엔 알림 스위치만 남는다.
                                  showLoadButton:
                                      !_useFigmaTopBar && !_catalogNotReady,
                                  showNotificationToggle:
                                      _isViewingCurrentSemester,
                                  notificationsEnabled: _notificationsEnabled,
                                  onNotificationsChanged:
                                      _onNotificationsToggled,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              child: MyTimetableStatusBar(
                                status: _myTimetableStatus,
                                onRetry: _loadMyTimetable,
                                semesterWord: _semesterWord,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                        if (_useFigmaTopBar && !_editMode)
                          // 시안(2152-1429): 격자를 화면 폭 전체의 흰 판(위쪽만 크게
                          // 둥글게)에 담고, 학점 줄도 그 판 안 아래쪽에 둔다.
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(32),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0x0F000000),
                                    offset: Offset(0, -4),
                                    blurRadius: 20,
                                  ),
                                ],
                              ),
                              // 편집 화면에서 돌아온 첫 프레임엔 높이 실측이 한 박자
                              // 늦어 내용이 잠깐 넘칠 수 있어, 넘침 경고 대신 잘라 보인다.
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      key: _gridWrapperKey,
                                      padding: const EdgeInsets.fromLTRB(
                                        14,
                                        20,
                                        14,
                                        0,
                                      ),
                                      child: _gridWithEmptyPrompt(
                                        now,
                                        displayedGridHeight,
                                      ),
                                    ),
                                    Column(
                                      key: _chromeBelowGridKey,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (!_addPanelOpen) _creditSummaryBar(),
                                        SizedBox(
                                          height: _addPanelOpen ? 0 : 100,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else ...[
                          // 디자인 23처럼 그리드를 흰 카드(모서리 16, 옅은 그림자)에 담는다.
                          Padding(
                            key: _gridWrapperKey,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                10,
                                12,
                                10,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: TimetableColors.panelBackground,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: _gridWithEmptyPrompt(
                                now,
                                displayedGridHeight,
                              ),
                            ),
                          ),
                          // 하단 탭 바(extendBody)에 그리드가 가려지지 않도록 남기는
                          // 여백. 그리드 최대 높이 계산을 위해 실측 키를 붙인다.
                          SizedBox(
                            key: _chromeBelowGridKey,
                            height: _addPanelOpen ? 0 : 100,
                          ),
                        ],
                      ],
                    );

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        gridColumn,
                        if (_addPanelShown)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            height: panelHeight,
                            child: IgnorePointer(
                              ignoring: !_addPanelOpen,
                              child: SlideTransition(
                                position: _addPanelOffset,
                                child: _buildAddPanel(),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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
      onClose: () => _setAddPanelOpen(false),
      // 새 화면에서는 손잡이로 시트 높이를 최소~최대 사이로 바꾼다(닫기는 뒤로가기).
      onHandleDragUpdate: _useFigmaTopBar ? _onSheetDragUpdate : null,
      onHandleDragEnd: _useFigmaTopBar ? _onSheetDragEnd : null,
      searchFilterBar: SearchFilterBar(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onQueryChanged: (q) => setState(() => _query = q),
        filters: _filters,
        filterPanelOpen: _filterPanelOpen,
        // 필터를 열어도 시트 높이는 그대로 둔다(예전엔 최대로 올렸는데 시트가
        // 갑자기 튀어 올라 사용자 지적, 2026-11-16). 필터 칸은 시트 안에서 민다.
        // 필터를 접으면 필터링을 끈 것으로 보고 고른 값을 모두 푼다. 접은 뒤에
        // "2학년" 같은 칩이 남아 목록을 몰래 거르지 않게(사용자 지적, 2026-11-16).
        onToggleFilterPanel: () => setState(() {
          _filterPanelOpen = !_filterPanelOpen;
          if (!_filterPanelOpen) _filters.clear();
        }),
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

    if (_useFigmaTopBar) {
      // 격자에서 고른 과목은 (목록 아래쪽에 있어도) 맨 위로 올려 펼쳐 둔다.
      final pinned = _pinnedCourse;
      final pinnedKey = pinned == null ? null : _courseKey(pinned);
      final items = [
        ?pinned,
        ...results.where((r) => _courseKey(r) != pinnedKey),
      ];
      return ListView.builder(
        controller: _resultsScroll,
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final key = _courseKey(item);
          final expanded = _expandedCourseKey == key;
          return CourseResultTile(
            key: expanded ? _expandedTileKey : ValueKey('course-tile-$key'),
            course: item,
            expanded: expanded,
            alreadyAdded: _isAdded(item),
            highlighted: pinnedKey == key,
            onTap: () => _onResultTileTap(item),
            onAdd: () => _addCourseResolvingConflicts(item),
            onViewSyllabus: () => _openSyllabus(item),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
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
