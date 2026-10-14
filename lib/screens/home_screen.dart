import 'package:flutter/material.dart';

import '../config/mock_mode.dart';
import '../services/class_schedule_parser.dart';
import '../services/course_catalog_service.dart';
import '../services/fakes/fake_course_catalog_service.dart';
import '../services/fakes/fake_my_timetable_service.dart';
import '../services/fakes/fake_student_info_service.dart';
import '../services/my_enrolled_courses.dart';
import '../services/my_timetable_service.dart';
import '../services/student_info_service.dart';
import '../services/weather_service.dart';
import 'cafeteria/cafeteria_screen.dart';
import 'cafeteria/services/cafeteria_menu_mock_data.dart';
import 'calendar/calendar_screen.dart';
import 'collection_screen.dart';
import 'home/home_colors.dart';
import 'home/rank/department_rank_screen.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'home/widgets/home_mini_card.dart';
import 'home/widgets/my_info_row.dart';
import 'home/widgets/next_class_card.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'campus_map/campus_map_screen.dart';
import 'login_screen.dart';
import 'notice/notice_screen.dart';
import 'terms_detail_screen.dart';
import 'timetable/timetable_screen.dart';

/// 좌상단 아바타를 눌렀을 때 뜨는 드롭다운 메뉴 항목 (Figma node 6:16).
enum _AvatarMenuAction { myInfo, terms, logout }

/// "내 정보" 조회 실패 원인. 원인마다 사용자에게 보여줄 안내/행동이 다르므로
/// (세션 만료 → 재로그인 유도, 네트워크/서버 오류 → 재시도, 파싱 실패 →
/// 알 수 없는 오류) 하나의 뭉뚱그린 에러 상태로 합치지 않는다.
enum _StudentInfoErrorKind { sessionExpired, network, server, parse }

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
  final CourseCatalogService? courseCatalogService;
  final MyTimetableService? myTimetableService;

  /// 테스트에서 [StudentInfoService]를 mock으로 주입하기 위한 옵션.
  /// [weatherService]와 동일한 패턴.
  final StudentInfoService? studentInfoService;

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

  late final CourseCatalogService _courseCatalogService;
  late final MyTimetableService _myTimetableService;
  late final DateTime Function() _now;
  List<TodayClass> _todayClasses = const [];
  List<CourseCatalogItem> _enrolledCourses = const [];
  bool _timetableLoaded = false;

  late final StudentInfoService _studentInfoService;
  StudentInfoResponse? _studentInfoData;
  bool _studentInfoLoading = true;
  _StudentInfoErrorKind? _studentInfoError;

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
        widget.courseCatalogService ??
        (kUseMockApi ? FakeCourseCatalogService() : CourseCatalogService());
    _myTimetableService =
        widget.myTimetableService ??
        (kUseMockApi ? FakeMyTimetableService() : MyTimetableService());
    _studentInfoService =
        widget.studentInfoService ??
        (kUseMockApi ? FakeStudentInfoService() : StudentInfoService());
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
  Future<void> _loadStudentInfo() async {
    final userId2 = widget.userId2;
    if (userId2 == null) {
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoData = null;
        _studentInfoError = _StudentInfoErrorKind.sessionExpired;
      });
      return;
    }

    _updateStudentInfoState(() {
      _studentInfoLoading = true;
      _studentInfoError = null;
    });

    try {
      final info = await _studentInfoService.fetchStudentInfo(userId2: userId2);
      _updateStudentInfoState(() {
        _studentInfoData = info;
        _studentInfoLoading = false;
        _studentInfoError = null;
      });
    } on StudentInfoNetworkException catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(네트워크): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = _StudentInfoErrorKind.network;
      });
    } on StudentInfoServerException catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(서버): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = _StudentInfoErrorKind.server;
      });
    } on StudentInfoParseException catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(파싱): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = _StudentInfoErrorKind.parse;
      });
    } catch (e) {
      debugPrint('[Home] 내 정보 조회 실패(알 수 없음): $e');
      _updateStudentInfoState(() {
        _studentInfoLoading = false;
        _studentInfoError = _StudentInfoErrorKind.parse;
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
      final catalog = await _courseCatalogService.fetchCourseCatalog(
        year: semester.year,
        semester: semester.semester,
        jsessionId: jsessionId,
        wmonid: wmonid,
        icKwa: '%',
      );
      final myTimetable = await _myTimetableService.fetchMyTimetable(
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

  void _openTimetable() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TimetableScreen(
          jsessionId: widget.jsessionId,
          wmonid: widget.wmonid,
          userId2: widget.userId2,
        ),
      ),
    );
  }

  void _openDepartmentRank() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DepartmentRankScreen(isDark: true)),
    );
  }

  void _openCollection() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CollectionScreen(userId2: widget.userId2),
      ),
    );
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
  }

  void _handleMenuAction(_AvatarMenuAction action) {
    switch (action) {
      case _AvatarMenuAction.myInfo:
        _showMyInfoDialog();
      case _AvatarMenuAction.terms:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const TermsDetailScreen(
              title: '이용약관',
              body: TermsDetailScreen.termsOfServiceBody,
            ),
          ),
        );
      case _AvatarMenuAction.logout:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
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
    final selected = await showModalBottomSheet<_AvatarMenuAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              title: const Text('내 정보'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AvatarMenuAction.myInfo),
            ),
            ListTile(
              title: const Text('이용약관'),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AvatarMenuAction.terms),
            ),
            ListTile(
              title: const Text('로그아웃', style: TextStyle(color: _accentRed)),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AvatarMenuAction.logout),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
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
          return AlertDialog(
            backgroundColor: colors.cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '내 정보',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                ..._buildMyInfoContent(colors, dialogContext),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cobalt,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    _myInfoDialogRefresh = null;
  }

  /// 로딩/에러/성공 상태에 따른 "내 정보" 본문을 만든다.
  List<Widget> _buildMyInfoContent(
    HomeColors colors,
    BuildContext dialogContext,
  ) {
    if (_studentInfoLoading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ];
    }

    final error = _studentInfoError;
    if (error != null) {
      return _buildMyInfoError(colors, dialogContext, error);
    }

    final info = _studentInfoData;
    return [
      MyInfoRow(colors: colors, label: '이름', value: info?.name ?? '정보 없음'),
      const SizedBox(height: 14),
      MyInfoRow(
        colors: colors,
        label: '학과',
        value: info?.department ?? '정보 없음',
      ),
      const SizedBox(height: 14),
      MyInfoRow(colors: colors, label: '학년', value: info?.grade ?? '정보 없음'),
    ];
  }

  /// 에러 원인별 안내 문구 + 복구 행동(재로그인 유도/재시도)을 구성한다.
  List<Widget> _buildMyInfoError(
    HomeColors colors,
    BuildContext dialogContext,
    _StudentInfoErrorKind error,
  ) {
    void goToLogin() {
      Navigator.of(dialogContext).pop();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    final (icon, message) = switch (error) {
      _StudentInfoErrorKind.sessionExpired => (
        Icons.login,
        '로그인 정보를 찾을 수 없어요.\n다시 로그인해주세요.',
      ),
      _StudentInfoErrorKind.network => (Icons.wifi_off, '네트워크 연결을 확인해주세요.'),
      _StudentInfoErrorKind.server => (
        Icons.error_outline,
        '서버에 문제가 발생했어요.\n잠시 후 다시 시도해주세요.',
      ),
      _StudentInfoErrorKind.parse => (
        Icons.error_outline,
        '정보를 불러오지 못했어요.\n(알 수 없는 오류)',
      ),
    };

    return [
      Row(
        children: [
          Icon(icon, color: colors.textSecondary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
      if (error == _StudentInfoErrorKind.sessionExpired) ...[
        const SizedBox(height: 12),
        TextButton(onPressed: goToLogin, child: const Text('로그인 화면으로 이동')),
      ] else if (error == _StudentInfoErrorKind.network ||
          error == _StudentInfoErrorKind.server) ...[
        const SizedBox(height: 12),
        TextButton(onPressed: _loadStudentInfo, child: const Text('다시 시도')),
      ],
    ];
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

  static const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

  Widget _topIconButton(IconData icon, VoidCallback onTap, {bool dot = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.cobaltDeep,
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            if (dot)
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.blushPink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 분홍색 "오늘 학식" 카드. 학식 데이터는 목데이터([CafeteriaMenuMockData])라
  /// 오늘 점심 메뉴가 등록돼 있으면 첫 번째 식당의 메뉴 두 가지와 가격을, 없으면
  /// 안내 문구를 보여준다.
  Widget _buildMenuCard(DateTime now) {
    final lunch = CafeteriaMenuMockData.menuFor(now)?.lunch ?? const [];
    final item = lunch.isEmpty ? null : lunch.first;
    final title = item == null
        ? '오늘의 메뉴는\n무엇일까?'
        : item.dishes.take(2).join('\n');
    return HomeMiniCard(
      icon: Icons.restaurant,
      iconBackground: Colors.white,
      iconColor: AppColors.ink,
      label: '오늘 점심',
      title: title,
      footer: item == null
          ? Text(
              '학식을 조회할 수 있어요',
              style: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    item.restaurant,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.priceText,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
      backgroundColor: AppColors.blushPink,
      textColor: AppColors.ink,
      onTap: _openCafeteria,
    );
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
        '${_weekdayNames[now.weekday - 1]}요일';
    final upcoming = next == null
        ? nextClassAfterToday(courses: _enrolledCourses, now: now)
        : null;
    final upcomingDayLabel = upcoming == null
        ? ''
        : Weekday.values.indexOf(upcoming.day) == now.weekday % 7
        ? '내일'
        : '${_weekdayNames[Weekday.values.indexOf(upcoming.day)]}요일';

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
                        _topIconButton(Icons.search, _openTimetable),
                        const SizedBox(width: 8),
                        _topIconButton(
                          Icons.notifications_none,
                          _openNotice,
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
                        Expanded(child: _buildMenuCard(now)),
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

// Figma 스크린샷(node 6:16)의 "로그아웃" 텍스트를 스포이드로 찍어 확인한 값.
const Color _accentRed = Color(0xFFFF4D4F);
