import 'package:flutter/material.dart';

import '../services/class_schedule_parser.dart';
import '../services/course_catalog_service.dart';
import '../services/my_enrolled_courses.dart';
import '../services/my_timetable_service.dart';
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
import 'home/rank/department_rank_screen.dart';
import 'home/widgets/cafeteria_menu_card.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'home/widgets/home_mini_card.dart';
import 'home/widgets/home_top_icon_button.dart';
import 'home/widgets/my_info_dialog.dart';
import 'home/widgets/my_menu_sheet.dart';
import 'home/widgets/next_class_card.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'campus_map/campus_map_screen.dart';
import 'login_screen.dart';
import 'notice/notice_screen.dart';
import 'terms_detail_screen.dart';
import 'timetable/timetable_screen.dart';

/// "우진이의 하루" 홈 화면(메인 대시보드) (Figma node 6:14 다크 / 6:20 라이트).
///
/// 다른 화면은 전부 다크 전용(theme/app_colors.dart의 AppColors)이지만, 이 화면만
/// 라이트/다크 테마 토글을 지원한다. 전역 테마나 다른 화면에는 영향을 주지 않도록
/// 로컬 State(`_isDark`)로만 관리하고, 색상도 이 파일 안의 [HomeColors]로 분리했다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.weatherService,
    this.jsessionId,
    this.wmonid,
    this.userId2,
    this.courseCatalogService,
    this.myTimetableService,
    this.studentInfoService,
    this.now,
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

  /// 테스트에서 [CourseCatalogService]/[MyTimetableService]를 mock으로
  /// 주입하기 위한 옵션. [weatherService]와 동일한 패턴.
  final CourseCatalogServiceBase? courseCatalogService;
  final MyTimetableServiceBase? myTimetableService;

  /// 테스트에서 [StudentInfoService]를 mock으로 주입하기 위한 옵션.
  /// [weatherService]와 동일한 패턴.
  final StudentInfoServiceBase? studentInfoService;

  /// 테스트에서 "지금 시각"을 고정하기 위한 옵션. 기본값은 `null`이며, 이
  /// 경우 실제 [DateTime.now]를 쓴다. "지금이 수업 시간인지" 판단은 실제
  /// 시계에 좌우되므로, 이 시드 없이는 특정 시각에 의존하는 테스트를 안정적으로
  /// 쓸 수 없다.
  final DateTime Function()? now;

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

class _HomeScreenState extends State<HomeScreen> {
  late final WeatherService _weatherService;
  WeatherResponse? _weatherData;
  bool _weatherLoading = true;
  bool _weatherHasError = false;

  late final CourseCatalogServiceBase _courseCatalogService;
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
    _courseCatalogService =
        widget.courseCatalogService ?? ServiceFactory.courseCatalog();
    _myTimetableService =
        widget.myTimetableService ?? ServiceFactory.myTimetable();
    _studentInfoService =
        widget.studentInfoService ?? ServiceFactory.studentInfo();
    _now = widget.now ?? DateTime.now;
    _loadWeather();
    _loadTodayClasses();
    _loadStudentInfo();
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
      final catalog = await SessionCache.getCourseCatalog(
        _courseCatalogService,
        year: semester.year,
        semester: semester.semester,
        jsessionId: jsessionId,
        wmonid: wmonid,
        icKwa: '%',
      );
      final myTimetable = await SessionCache.getMyTimetable(
        _myTimetableService,
        year: semester.year,
        semester: semester.semester,
        jsessionId: jsessionId,
        wmonid: wmonid,
        userId2: userId2,
      );
      final matched = matchEnrolledCourses(
        catalog: catalog,
        myTimetable: myTimetable,
      );
      if (!mounted) return;
      setState(() {
        _todayClasses = todayClasses(courses: matched.courses, now: _now());
        _enrolledCourses = matched.courses;
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

  void _openDepartmentRank() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DepartmentRankScreen(isDark: true)),
    );
  }

  void _openCollection() {
    Navigator.of(context).push(_collectionRoute());
  }

  void _openNotice() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NoticeScreen()));
  }

  void _openCampusMap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CampusMapScreen()));
  }

  void _openCalendar() {
    Navigator.of(context).push(_calendarRoute());
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
        // 로그아웃하면 다른 학생이 같은 기기로 재로그인할 수 있으므로, 이전
        // 세션의 캐시(학생정보/시간표/개설과목)가 다음 로그인에 잘못
        // 재사용되지 않도록 반드시 비운다.
        SessionCache.clear();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
    }
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

  /// 이름("홍길동")에서 성을 뗀 호칭("길동아")을 만든다. 받침이 있으면 "아",
  /// 없으면 "야". 이름을 모르거나 두 글자 미만이면 null.
  String? _callName() {
    final name = _studentInfoData?.name?.trim();
    if (name == null || name.length < 2) return null;
    final given = name.length >= 3 ? name.substring(name.length - 2) : name;
    final last = given.codeUnitAt(given.length - 1);
    final hasBatchim =
        last >= 0xAC00 && last <= 0xD7A3 && (last - 0xAC00) % 28 != 0;
    return '$given${hasBatchim ? '아' : '야'}';
  }

  @override
  Widget build(BuildContext context) {
    final now = _now();
    final nowMinutes = now.hour * 60 + now.minute;
    final remaining = _todayClasses
        .where((c) => c.slot.endMinutes > nowMinutes)
        .toList();
    final next = remaining.isEmpty ? null : remaining.first;

    final callName = _callName();
    final greetingHead = callName == null ? '' : '$callName,\n';
    final greeting = !_timetableLoaded || _todayClasses.isEmpty
        ? '$greetingHead오늘 하루도 화이팅!'
        : remaining.isEmpty
        ? '$greetingHead오늘도 수고했어!'
        : '$greetingHead오늘 수업 ${remaining.length}개 남았어';
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

    return Scaffold(
      backgroundColor: AppColors.cobalt,
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
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        HomeTopIconButton(
                          icon: Icons.search,
                          onTap: _openTimetable,
                        ),
                        const SizedBox(width: 8),
                        HomeTopIconButton(
                          icon: Icons.notifications_none,
                          onTap: _openNotice,
                          dot: true,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
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
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.lime,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  dateBadge,
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Padding(
                                padding: const EdgeInsets.only(right: 70),
                                child: Text(
                                  greeting,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    height: 1.22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Positioned(
                          right: -20,
                          top: 10,
                          child: MascotSticker(width: 100, angle: 0.1),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: NextClassCard(
                      next: next,
                      nowMinutes: nowMinutes,
                      timetableLoaded: _timetableLoaded,
                      hasClassesToday: _todayClasses.isNotEmpty,
                      upcoming: upcoming,
                      upcomingDayLabel: upcomingDayLabel,
                      onDirectionsTap: _openCampusMap,
                      onTimetableTap: _openTimetable,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: HomeMiniCard(
                            icon: Icons.bar_chart_rounded,
                            iconBackground: AppColors.lime,
                            iconColor: AppColors.ink,
                            label: '학과 등수',
                            title: '나는 학과에서\n몇등일까?',
                            titleColor: AppColors.lime,
                            footer: const Text(
                              '두근두근',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            backgroundColor: AppColors.ink,
                            textColor: Colors.white,
                            onTap: _openDepartmentRank,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CafeteriaMenuCard(
                            now: now,
                            onTap: _openCafeteria,
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
    );
  }
}
