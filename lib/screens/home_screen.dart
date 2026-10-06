import 'package:flutter/material.dart';

import '../services/class_schedule_parser.dart';
import '../services/course_catalog_service.dart';
import '../services/my_enrolled_courses.dart';
import '../services/my_timetable_service.dart';
import '../services/student_info_service.dart';
import '../services/weather_service.dart';
import 'collection_screen.dart';
import 'home/home_colors.dart';
import 'home/widgets/ad_banner_placeholder.dart';
import 'home/widgets/calendar_promo_card.dart';
import 'home/widgets/header.dart';
import 'home/widgets/headline.dart';
import 'home/widgets/menu_card.dart';
import 'home/widgets/my_info_row.dart';
import 'home/widgets/rank_card.dart';
import 'home/widgets/recommend_card.dart';
import 'home/widgets/section_header.dart';
import 'home/widgets/weather_detail_dialog.dart';
import 'home_placeholder_screen.dart';
import 'login_screen.dart';
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

/// 홈 화면 인사말 자리의 고정 문구 기본값. 지금이 사용자의 실제 수업
/// 시간이면 "{과목명} 수업 화이팅!"으로 바뀐다.
const String _defaultGreeting = '오늘 하루도 화이팅!';

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
  bool _isDark = true;
  final _avatarKey = GlobalKey();

  late final WeatherService _weatherService;
  WeatherResponse? _weatherData;
  bool _weatherLoading = true;
  bool _weatherHasError = false;

  late final CourseCatalogService _courseCatalogService;
  late final MyTimetableService _myTimetableService;
  late final DateTime Function() _now;
  String _greeting = _defaultGreeting;

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
        widget.courseCatalogService ?? CourseCatalogService();
    _myTimetableService = widget.myTimetableService ?? MyTimetableService();
    _studentInfoService = widget.studentInfoService ?? StudentInfoService();
    _now = widget.now ?? DateTime.now;
    _loadWeather();
    _loadCurrentClassGreeting();
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

  /// 세션이 있으면(jsessionId/wmonid/userId2 전부 non-null) 지금이 실제 수업
  /// 시간인지 조회해 인사말을 "{과목명} 수업 화이팅!"으로 바꾼다. 세션이
  /// 없거나, 현재 수업이 없거나, 네트워크/서버/파싱 등 어떤 예외가 나도
  /// 조용히 기존 고정 문구로 남긴다 — 스낵바/다이얼로그 등 방해 UI는 쓰지
  /// 않는다(날씨 에러 처리와 동일한 원칙).
  Future<void> _loadCurrentClassGreeting() async {
    final jsessionId = widget.jsessionId;
    final wmonid = widget.wmonid;
    final userId2 = widget.userId2;
    if (jsessionId == null || wmonid == null || userId2 == null) {
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
      final currentClass = findCurrentClass(
        courses: matched.courses,
        now: _now(),
      );
      if (!mounted || currentClass == null) return;
      setState(() {
        _greeting = '${currentClass.courseName} 수업 화이팅!';
      });
    } catch (e) {
      debugPrint('[Home] 현재 수업 조회 실패: $e');
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

  void _openPlaceholder() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()));
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

  void _openCollection() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CollectionScreen()));
  }

  Future<void> _showAvatarMenu() async {
    final renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (renderBox == null) return;

    final colors = HomeColors(_isDark);
    // 아바타 하단에서 8px 떨어진 지점에 메뉴를 띄운다. Rect.fromPoints는 두
    // 점을 정규화해서 좌상단/우하단을 스스로 계산하므로, 두 점 모두에 같은
    // +8 오프셋을 줘야 의도한 간격이 실제로 반영된다(한쪽에만 주면 정규화
    // 과정에서 간격이 사라진다).
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(
          Offset(0, renderBox.size.height + 8),
          ancestor: overlay,
        ),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(const Offset(0, 8)),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    const itemTextStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);

    final selected = await showMenu<_AvatarMenuAction>(
      context: context,
      position: position,
      color: colors.cardSurface,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      menuPadding: EdgeInsets.zero,
      items: [
        PopupMenuItem(
          value: _AvatarMenuAction.myInfo,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '내 정보',
            style: itemTextStyle.copyWith(color: colors.textPrimary),
          ),
        ),
        const PopupMenuDivider(
          height: 1,
          thickness: 1,
          color: _menuDividerColor,
        ),
        PopupMenuItem(
          value: _AvatarMenuAction.terms,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '이용약관',
            style: itemTextStyle.copyWith(color: colors.textPrimary),
          ),
        ),
        const PopupMenuDivider(
          height: 1,
          thickness: 1,
          color: _menuDividerColor,
        ),
        PopupMenuItem(
          value: _AvatarMenuAction.logout,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('로그아웃', style: itemTextStyle.copyWith(color: _accentRed)),
        ),
      ],
    );

    if (!mounted || selected == null) return;
    switch (selected) {
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

  /// "내 정보" 모달 (Figma node 6:17). 홈 화면 진입 시 미리 불러온(또는
  /// 로딩/에러 중인) [_studentInfoData]/[_studentInfoLoading]/
  /// [_studentInfoError]를 그대로 보여준다. [StatefulBuilder]의 로컬
  /// setState를 [_myInfoDialogRefresh]에 등록해두면, 다이얼로그가 열려 있는
  /// 동안 [_loadStudentInfo]가 끝나도(최초 로딩이 늦게 끝나는 경우나
  /// "다시 시도" 모두) 다이얼로그 내용이 함께 갱신된다. 다이얼로그가 닫히면
  /// 콜백을 반드시 해제한다 — 그러지 않으면 닫힌 다이얼로그의 setState를
  /// 호출하려다 에러가 난다.
  Future<void> _showMyInfoDialog() async {
    final colors = HomeColors(_isDark);
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
                      backgroundColor: accentOrange,
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

  @override
  Widget build(BuildContext context) {
    final colors = HomeColors(_isDark);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Header(
                isDark: _isDark,
                colors: colors,
                avatarKey: _avatarKey,
                onAvatarTap: _showAvatarMenu,
                onToggle: (isDark) => setState(() => _isDark = isDark),
                greeting: _greeting,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                children: [
                  Headline(
                    colors: colors,
                    weatherLoading: _weatherLoading,
                    weatherHasError: _weatherHasError,
                    weatherData: _weatherData,
                    onWeatherTap: _weatherData == null
                        ? null
                        : () => showWeatherDetailDialog(
                            context,
                            colors: colors,
                            weather: _weatherData!,
                          ),
                  ),
                  const SizedBox(height: 16),
                  RecommendCard(isDark: _isDark, onTap: _openTimetable),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RankCard(
                          isDark: _isDark,
                          onTap: _openPlaceholder,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: MenuCard(
                          isDark: _isDark,
                          onTap: _openPlaceholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(colors: colors, onMorePressed: _openCollection),
                  const SizedBox(height: 12),
                  CalendarPromoCard(colors: colors, onTap: _openPlaceholder),
                  const SizedBox(height: 14),
                  AdBannerPlaceholder(colors: colors),
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

// 같은 스크린샷에서 "내 정보"/"이용약관"/"로그아웃" 사이 구분선을 스포이드로
// 찍어 확인한 값 — 카드 배경(약 0x19191B)보다 살짝 밝은 저대비 선.
const Color _menuDividerColor = Color(0xFF2C2C2F);
