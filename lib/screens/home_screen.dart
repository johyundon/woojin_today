import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/cafeteria_menu_service.dart';
import '../services/class_schedule_parser.dart';
import '../services/course_catalog_service.dart';
import '../services/logout_cleaner.dart';
import '../services/my_timetable_service.dart';
import '../services/notice_watcher.dart';
import '../services/service_factory.dart';
import '../services/session_cache.dart';
import '../services/student_info_service.dart';
import '../services/weather_service.dart';
import '../utils/weekday_labels.dart';
import 'cafeteria/cafeteria_screen.dart';
import 'calendar/calendar_screen.dart';
import 'collection_screen.dart';
import 'home/home_colors.dart';
import 'home/home_enums.dart';
import 'home/widgets/cafeteria_menu_card.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'home/widgets/upcoming_event_card.dart';
import 'home/widgets/home_top_icon_button.dart';
import 'home/services/home_banner_items.dart';
import 'home/widgets/home_notice_banner.dart';
import 'home/widgets/my_info_dialog.dart';
import 'home/widgets/my_menu_sheet.dart';
import 'home/widgets/next_class_card.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'campus_map/campus_map_screen.dart';
import 'campus_map/models/room_building.dart';
import 'login_screen.dart';
import 'notice/notice_screen.dart';
import 'search/app_features.dart';
import 'search/search_screen.dart';
import 'terms_detail_screen.dart';
import 'timetable/timetable_screen.dart';

/// "우진이의 하루" 홈 화면(메인 대시보드) (v7 디자인 12 수업 있는 날 / 13 공강인 날).
///
/// 거의 흰 바탕 위에 인사말, "다음 수업" 카드, 학과 등수·오늘 점심 작은 카드를 둔다.
/// 홈 카드 전용 색은 `home/home_colors.dart`의 [HomeV7Colors]에 있다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.weatherService,
    this.jsessionId,
    this.wmonid,
    this.userId2,
    this.myTimetableService,
    this.studentInfoService,
    this.cafeteriaMenuService,
    this.now,
    this.noticeWatcher,
  });

  /// 테스트에서 [WeatherService]를 mock으로 주입하기 위한 옵션. 기본값은
  /// `null`이며, 이 경우 `_HomeScreenState.initState`에서 실제
  /// [WeatherService]를 생성한다.
  final WeatherService? weatherService;

  /// 포털 로그인으로 얻은 세션 쿠키 값. 로그인 화면/스플래시 화면에서 로그인
  /// 완료 화면을 거쳐 그대로 전달된다. 셋 중 하나라도 null이면(세션 없음)
  /// 시간표 조회 자체를 하지 않는다 — 에러가 아니라 정상 상태로 취급한다.
  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  /// 테스트에서 [MyTimetableService]를 mock으로 주입하기 위한 옵션.
  /// [weatherService]와 동일한 패턴.
  final MyTimetableServiceBase? myTimetableService;

  /// 테스트에서 [StudentInfoService]를 mock으로 주입하기 위한 옵션.
  /// [weatherService]와 동일한 패턴.
  final StudentInfoServiceBase? studentInfoService;

  /// 테스트에서 학식 서비스를 mock으로 주입하기 위한 옵션. [weatherService]와
  /// 동일한 패턴.
  final CafeteriaMenuServiceBase? cafeteriaMenuService;

  /// 테스트에서 "지금 시각"을 고정하기 위한 옵션. 기본값은 `null`이며, 이
  /// 경우 실제 [DateTime.now]를 쓴다. "지금이 수업 시간인지" 판단은 실제
  /// 시계에 좌우되므로, 이 시드 없이는 특정 시각에 의존하는 테스트를 안정적으로
  /// 쓸 수 없다.
  final DateTime Function()? now;

  /// 테스트용. 새 공지 확인([NoticeWatcher])을 가짜로 바꾼다.
  final NoticeWatcher? noticeWatcher;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 현재 학기를 추정한다.
///
/// *** 추정 규칙 *** API 명세에 학기 계산 규칙이 정의돼 있지 않아 간단한
/// 달력 기준 추정을 쓴다: 3~8월이면 1학기, 9~12월이면 2학기, 1~2월이면
/// 전년도 2학기로 본다.
({int year, int semester}) _estimateCurrentSemester(DateTime now) {
  if (now.month >= 3 && now.month <= 8) {
    return (year: now.year, semester: 1);
  } else if (now.month >= 9 && now.month <= 12) {
    return (year: now.year, semester: 2);
  } else {
    return (year: now.year - 1, semester: 2);
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final NoticeWatcher _noticeWatcher;

  /// 공지사항 화면에서 아직 보지 않은 새 공지가 있으면 종 아이콘에 점을 띄운다.
  bool _hasNewNotice = false;

  /// 앱을 열 때의 새 공지 확인. 배너는 이게 끝난 뒤 공지를 읽어, 같은 목록을
  /// 학교에 두 번 묻지 않고 방금 저장된 것을 쓴다.
  Future<void>? _firstNoticeCheck;

  late final WeatherService _weatherService;
  WeatherResponse? _weatherData;
  bool _weatherLoading = true;
  bool _weatherHasError = false;

  late final MyTimetableServiceBase _myTimetableService;
  late final DateTime Function() _now;
  List<TodayClass> _todayClasses = const [];
  List<CourseCatalogItem> _enrolledCourses = const [];
  bool _timetableLoaded = false;

  late final StudentInfoServiceBase _studentInfoService;
  StudentInfoResponse? _studentInfoData;
  bool _studentInfoLoading = true;
  StudentInfoErrorKind? _studentInfoError;

  /// "내 정보" 다이얼로그가 열려 있는 동안 [_loadStudentInfo]가 상태를 바꾸면
  /// 이 콜백으로 다이얼로그도 함께 새로고침한다. `showDialog`로 띄운
  /// 다이얼로그는 메인 화면 트리 밖의 별도 route라, 이 화면의
  /// `setState`만으로는 다시 그려지지 않기 때문이다. 다이얼로그가 닫히면
  /// null로 되돌려 닫힌 다이얼로그에 setState를 호출하지 않게 한다.
  void Function(void Function())? _myInfoDialogRefresh;

  @override
  void initState() {
    super.initState();
    _weatherService = widget.weatherService ?? WeatherService();
    _myTimetableService =
        widget.myTimetableService ?? ServiceFactory.myTimetable();
    _studentInfoService =
        widget.studentInfoService ?? ServiceFactory.studentInfo();
    _now = widget.now ?? DateTime.now;
    _noticeWatcher = widget.noticeWatcher ?? NoticeWatcher();
    WidgetsBinding.instance.addObserver(this);
    _firstNoticeCheck = _checkNotices();
    _loadWeather();
    _loadTodayClasses();
    _loadStudentInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱으로 다시 돌아올 때마다 새 공지를 확인한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkNotices();
  }

  /// 새 공지가 올라왔는지 확인하고(알림이 켜져 있으면 알림도 띄움) 종 아이콘의
  /// 점을 갱신한다. 실패해도 조용히 넘어간다([NoticeWatcher.check]).
  Future<void> _checkNotices() async {
    await _noticeWatcher.check();
    await _refreshNoticeDot();
  }

  /// 종 아이콘의 점: 마지막으로 공지사항 화면을 연 뒤 새로 들어온 공지가 있거나,
  /// 게시판에 새 글 표시가 붙은 공지 중 아직 열어 보지 않은 것이 있으면 켠다
  /// (공지사항 화면의 "새 글 N개"와 같은 기준).
  Future<void> _refreshNoticeDot() async {
    final show =
        await _noticeWatcher.hasPending() || await _noticeWatcher.hasUnread();
    if (mounted && show != _hasNewNotice) {
      setState(() => _hasNewNotice = show);
    }
  }

  /// "내 정보" 다이얼로그에 쓸 학생 정보를 홈 화면 진입 시 한 번만 불러와
  /// 캐싱한다(날씨 조회와 동일한 패턴). 다이얼로그를 열 때마다 다시
  /// 불러오지 않는 이유는, 이 정보가 세션 동안 바뀌지 않는 정적인 값이고
  /// (날씨처럼 "계속 바뀌는" 데이터가 아니다), 아바타 메뉴를 여러 번 열어도
  /// 매번 네트워크 호출을 하는 건 불필요하기 때문이다.
  ///
  /// userId2가 없으면(세션 정보 없음) 네트워크 호출 자체를 하지 않고 바로
  /// "세션 만료" 에러로 처리한다. 호출 중 발생하는 예외는 원인별로 구분해
  /// 저장한다 — 네트워크/서버/파싱 실패는 서로 다른 사용자 안내가 필요하다.
  Future<void> _loadStudentInfo({bool forceRefresh = false}) async {
    final userId2 = widget.userId2;
    if (userId2 == null) {
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoData = null;
        _studentInfoError = StudentInfoErrorKind.sessionExpired;
      });
      return;
    }

    _updateStudentInfoState(() {
      _studentInfoLoading = true;
      _studentInfoError = null;
    });

    try {
      final info = await SessionCache.getStudentInfo(
        _studentInfoService,
        userId2: userId2,
        forceRefresh: forceRefresh,
      );
      _updateStudentInfoState(() {
        _studentInfoData = info;
        _studentInfoLoading = false;
        _studentInfoError = null;
      });
    } on StudentInfoNetworkException catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(네트워크): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = StudentInfoErrorKind.network;
      });
    } on StudentInfoServerException catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(서버): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = StudentInfoErrorKind.server;
      });
    } on StudentInfoParseException catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(파싱): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = StudentInfoErrorKind.parse;
      });
    } catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(알 수 없음): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = StudentInfoErrorKind.parse;
      });
    }
  }

  /// [_studentInfoLoading]/[_studentInfoData]/[_studentInfoError] 중 하나를
  /// 바꾸는 공통 경로. 이 화면의 `setState` 외에, 지금 "내 정보" 다이얼로그가
  /// 열려 있다면([_myInfoDialogRefresh]가 non-null) 그 다이얼로그도 같이
  /// 새로고침한다.
  void _updateStudentInfoState(void Function() updates) {
    if (!mounted) return;
    setState(updates);
    _myInfoDialogRefresh?.call(() {});
  }

  /// 세션이 있으면(jsessionId/wmonid/userId2 전부 non-null) 내 시간표에서
  /// 오늘 수업 목록을 만들어 인사말("오늘 수업 N개 남았어")과 "다음 수업" 카드에
  /// 쓴다. 세션이 없거나 네트워크/서버/파싱 등 어떤 예외가 나도 조용히
  /// 빈 목록으로 남긴다 — 스낵바/다이얼로그 등 방해 UI는 쓰지 않는다(날씨
  /// 에러 처리와 동일한 원칙).
  Future<void> _loadTodayClasses() async {
    final jsessionId = widget.jsessionId;
    final wmonid = widget.wmonid;
    final userId2 = widget.userId2;
    if (jsessionId == null || wmonid == null || userId2 == null) {
      setState(() => _timetableLoaded = true);
      return;
    }

    try {
      final semester = _estimateCurrentSemester(_now());
      final myTimetable = await SessionCache.getMyTimetable(
        _myTimetableService,
        year: semester.year,
        semester: semester.semester,
        jsessionId: jsessionId,
        wmonid: wmonid,
        userId2: userId2,
      );
      if (!mounted) return;
      setState(() {
        _todayClasses = todayClasses(courses: myTimetable.courses, now: _now());
        _enrolledCourses = myTimetable.courses;
        _timetableLoaded = true;
      });
    } catch (e) {
      debugPrint('[Home] 오늘 수업 조회 실패: $e');
      if (!mounted) return;
      setState(() => _timetableLoaded = true);
    }
  }

  /// 홈 화면 헤드라인에 쓸 현재 날씨를 조회한다. 서버/네트워크/파싱 실패
  /// 원인과 무관하게(날씨 서비스 레이어가 던지는 예외는 전부
  /// [WeatherException] 하위 타입) 헤드라인 아이콘만 에러 상태로 바꾸고,
  /// 예외가 화면 밖으로 전파되지 않게 한다.
  Future<void> _loadWeather() async {
    try {
      final weather = await _weatherService.fetchWeather();
      if (!mounted) return;
      setState(() {
        _weatherData = weather;
        _weatherLoading = false;
        _weatherHasError = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _weatherLoading = false;
        _weatherHasError = true;
      });
    }
  }

  void _openCafeteria() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CafeteriaScreen()));
  }

  // 탭 화면(시간표/모아보기/캘린더)으로 가는 경로. 하단 탭 바에서 서로 오갈 때도
  // 같은 경로를 쓰려고 따로 만들어 둔다.
  Route<void> _timetableRoute() => MaterialPageRoute(
    builder: (_) => TimetableScreen(
      jsessionId: widget.jsessionId,
      wmonid: widget.wmonid,
      userId2: widget.userId2,
      onTabTap: _goToTab,
    ),
  );

  Route<void> _collectionRoute() => MaterialPageRoute(
    builder: (_) =>
        CollectionScreen(userId2: widget.userId2, onTabTap: _goToTab),
  );

  Route<void> _calendarRoute() =>
      MaterialPageRoute(builder: (_) => CalendarScreen(onTabTap: _goToTab));

  void _openTimetable() {
    Navigator.of(context).push(_timetableRoute());
  }

  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          links: FeatureLinks(userId2: widget.userId2, onTabTap: _goToTab),
        ),
      ),
    );
  }

  void _openCollection() {
    Navigator.of(context).push(_collectionRoute());
  }

  /// 공지사항 화면이 열리면서 새 공지 표시를 지우므로 점도 바로 끄고, 돌아오면
  /// 안 읽은 새 글이 남았는지 다시 본다.
  Future<void> _openNotice() async {
    setState(() => _hasNewNotice = false);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoticeScreen(watcher: _noticeWatcher)),
    );
    // 공지사항 화면에서 다 읽지 않았으면 점을 다시 켠다.
    await _refreshNoticeDot();
  }

  /// 길찾기: 앞 수업 건물(있으면)에서 다음 수업 건물까지 채운 채 지도를 연다.
  void _openCampusMap({String? origin, String? destination}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampusMapScreen(
          initialOriginBuilding: origin,
          initialDestinationBuilding: destination,
        ),
      ),
    );
  }

  /// "다가오는 일정" 카드를 다시 읽게 할 때 올린다(카드의 key로 쓴다).
  int _eventCardVersion = 0;

  /// 일정 카드에서 캘린더를 열고, 돌아오면 추가·수정한 일정이 보이게 카드를
  /// 다시 읽는다.
  Future<void> _openCalendarFromEventCard() async {
    await Navigator.of(context).push(_calendarRoute());
    if (mounted) setState(() => _eventCardVersion++);
  }

  void _openCalendar() {
    Navigator.of(context).push(_calendarRoute());
  }

  /// 위쪽 공지·이벤트 배너 카드. 새 공지 확인이 끝난 뒤 저장된 공지를 쓴다.
  Future<List<HomeBannerItem>> _loadBanner() async {
    await _firstNoticeCheck;
    return loadHomeBannerItems(
      notices: ServiceFactory.notice(),
      schedule: ServiceFactory.academicSchedule(),
      now: _now(),
    );
  }

  void _handleMenuAction(AvatarMenuAction action) {
    switch (action) {
      case AvatarMenuAction.myInfo:
        _showMyInfoDialog();
      case AvatarMenuAction.terms:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TermsDetailScreen(
              title: '이용약관',
              body: TermsDetailScreen.termsOfServiceBody,
            ),
          ),
        );
      case AvatarMenuAction.logout:
        _logout();
    }
  }

  /// 로그아웃하면 다른 학생이 같은 기기로 재로그인할 수 있으므로, 기기에 남은
  /// 이전 사용자의 데이터(자동 로그인 정보, 캐시, 저장한 시간표·일정, 예약
  /// 알림 등)를 전부 지운 뒤 로그인 화면으로 간다.
  Future<void> _logout() async {
    await clearUserDataOnLogout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// 홈 위에 열린 탭 화면(시간표/모아보기/캘린더)의 하단 탭 바를 눌렀을 때. 지금
  /// 화면을 닫고 홈으로 돌아가는 게 아니라, 누른 탭의 화면으로 바로 바꿔 준다 —
  /// 홈 위의 화면들을 걷어내고 그 탭 화면 하나만 올리므로 뒤로가기는 홈으로 간다.
  /// 홈 탭은 홈으로 돌아가고, MY 탭은 지금 화면 위에 메뉴를 띄운다.
  void _goToTab(int index) {
    switch (index) {
      case 0:
        Navigator.of(context)
            .pushAndRemoveUntil(_timetableRoute(), (route) => route.isFirst);
      case 1:
        Navigator.of(context)
            .pushAndRemoveUntil(_collectionRoute(), (route) => route.isFirst);
      case 2:
        Navigator.of(context).popUntil((route) => route.isFirst);
      case 3:
        Navigator.of(context)
            .pushAndRemoveUntil(_calendarRoute(), (route) => route.isFirst);
      case 4:
        _showMyMenu();
    }
  }

  /// 하단 탭 바의 탭을 눌렀을 때. 0(홈)은 이미 홈이라 아무것도 하지 않는다.
  void _onTabTap(int index) {
    switch (index) {
      case 0:
        _openTimetable();
      case 1:
        _openCollection();
      case 3:
        _openCalendar();
      case 4:
        _showMyMenu();
    }
  }

  /// MY 탭: 아바타 메뉴와 같은 항목(내 정보/이용약관/로그아웃)을 바텀시트로 보여준다.
  Future<void> _showMyMenu() async {
    final selected = await showModalBottomSheet<AvatarMenuAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => const MyMenuSheet(),
    );
    if (!mounted || selected == null) return;
    _handleMenuAction(selected);
  }

  /// "내 정보" 모달 (Figma node 6:17). 홈 화면 진입 시 미리 불러온(또는
  /// 로딩/에러 중인) [_studentInfoData]/[_studentInfoLoading]/
  /// [_studentInfoError]를 그대로 보여준다. [StatefulBuilder]의 로컬
  /// setState를 [_myInfoDialogRefresh]에 등록해두면, 다이얼로그가 열려 있는
  /// 동안 [_loadStudentInfo]가 끝나도(최초 로딩이 늦게 끝나는 경우나
  /// "다시 시도" 모두) 다이얼로그 내용이 함께 갱신된다. 다이얼로그가 닫히면
  /// 콜백을 반드시 해제한다 — 그러지 않으면 닫힌 다이얼로그의 setState를
  /// 호출하려다 에러가 난다.
  Future<void> _showMyInfoDialog() async {
    final colors = HomeColors(false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          _myInfoDialogRefresh = setDialogState;
          return MyInfoDialog(
            colors: colors,
            loading: _studentInfoLoading,
            data: _studentInfoData,
            error: _studentInfoError,
            onRetry: () => _loadStudentInfo(forceRefresh: true),
            onGoToLogin: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            ),
          );
        },
      ),
    );
    _myInfoDialogRefresh = null;
  }

  @override
  Widget build(BuildContext context) {
    final now = _now();
    final nowMinutes = now.hour * 60 + now.minute;
    final remaining = _todayClasses
        .where((c) => c.slot.endMinutes > nowMinutes)
        .toList();
    final next = remaining.isEmpty ? null : remaining.first;
    // 걷는 거리: 오늘 바로 앞 수업 강의실 건물 → 다음 수업 강의실 건물.
    final nextRoom = next == null ? '' : roomForSlot(next);
    final nextIndex = next == null ? -1 : _todayClasses.indexOf(next);
    final walkDestination = buildingForRoom(nextRoom);
    final walkOrigin = nextIndex > 0
        ? buildingForRoom(roomForSlot(_todayClasses[nextIndex - 1]))
        : null;

    final greeting = !_timetableLoaded || _todayClasses.isEmpty
        ? '오늘 하루도\n화이팅해요!'
        : remaining.isEmpty
        ? '오늘도\n수고했어요!'
        : '오늘은\n수업 ${remaining.length}개 남았어요!';
    final dateBadge =
        '${now.month.toString().padLeft(2, '0')}.'
        '${now.day.toString().padLeft(2, '0')} '
        '${weekdayLabelsMonFirst[now.weekday - 1]}요일';
    final upcoming = next == null
        ? nextClassAfterToday(courses: _enrolledCourses, now: now)
        : null;
    final upcomingDayLabel = upcoming == null
        ? ''
        : Weekday.values.indexOf(upcoming.day) == now.weekday % 7
        ? '내일'
        : '${weekdayLabelsMonFirst[Weekday.values.indexOf(upcoming.day)]}요일';

    // 흰 바탕이라 상태 표시줄 글자(시계·배터리)를 어둡게 그린다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        extendBody: true,
        bottomNavigationBar: HomeBottomNav(selectedIndex: 2, onTap: _onTabTap),
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          HomeV7IconButton(
                            asset: HomeV7IconButton.searchAsset,
                            semanticLabel: '검색',
                            onTap: _openSearch,
                          ),
                          const SizedBox(width: 8),
                          HomeV7IconButton(
                            asset: HomeV7IconButton.notificationsAsset,
                            semanticLabel: '알림',
                            onTap: _openNotice,
                            dot: _hasNewNotice,
                          ),
                        ],
                      ),
                    ),
                    HomeNoticeBanner(
                      load: _loadBanner,
                      onOpenCalendar: _openCalendar,
                      now: _now,
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 7),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: HomeV7Colors.dateBadge,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    dateBadge,
                                    style: const TextStyle(
                                      color: AppColors.textStrong,
                                      fontSize: 12,
                                      height: 1.4,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // 인사말이 한 줄이어도 디자인처럼 두 줄 높이를
                                // 잡아, 오른쪽 마스코트가 아래 카드를 덮지 않게 한다.
                                Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 73,
                                  ),
                                  padding: const EdgeInsets.only(right: 80),
                                  child: Text(
                                    greeting,
                                    style: const TextStyle(
                                      color: AppColors.inkNavy,
                                      fontSize: 26,
                                      height: 1.4,
                                      letterSpacing: -0.91,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Positioned(
                            right: -13,
                            top: 23,
                            child: MascotSticker(width: 90, angle: 0.14),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: NextClassCard(
                        next: next,
                        nowMinutes: nowMinutes,
                        timetableLoaded: _timetableLoaded,
                        hasClassesToday: _todayClasses.isNotEmpty,
                        upcoming: upcoming,
                        upcomingDayLabel: upcomingDayLabel,
                        room: nextRoom,
                        walkOrigin: walkOrigin,
                        walkDestination: walkDestination,
                        onDirectionsTap: () => _openCampusMap(
                          origin: walkOrigin?.name,
                          destination: walkDestination?.name,
                        ),
                        onTimetableTap: _openTimetable,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                      child: Row(
                        children: [
                          Expanded(
                            // 셔틀은 운행 정보 API가 없어 이 자리에 다가오는
                            // 일정을 보여준다. 캘린더에서 돌아오면 다시 읽는다.
                            child: UpcomingEventCard(
                              key: ValueKey(_eventCardVersion),
                              now: now,
                              onTap: _openCalendarFromEventCard,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CafeteriaMenuCard(
                              now: now,
                              onTap: _openCafeteria,
                              service: widget.cafeteriaMenuService,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
