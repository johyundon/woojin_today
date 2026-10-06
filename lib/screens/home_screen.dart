import 'package:flutter/material.dart';

import '../services/weather_service.dart';
import 'home_placeholder_screen.dart';
import 'login_screen.dart';
import 'terms_detail_screen.dart';

/// 좌상단 아바타를 눌렀을 때 뜨는 드롭다운 메뉴 항목 (Figma node 6:16).
enum _AvatarMenuAction { myInfo, terms, logout }

/// "우진이의 하루" 홈 화면(메인 대시보드) (Figma node 6:14 다크 / 6:20 라이트).
///
/// 다른 화면은 전부 다크 전용(theme/app_colors.dart의 AppColors)이지만, 이 화면만
/// 라이트/다크 테마 토글을 지원한다. 전역 테마나 다른 화면에는 영향을 주지 않도록
/// 로컬 State(`_isDark`)로만 관리하고, 색상도 이 파일 안의 [_HomeColors]로 분리했다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.weatherService});

  /// 테스트에서 [WeatherService]를 mock으로 주입하기 위한 옵션. 기본값은
  /// `null`이며, 이 경우 `_HomeScreenState.initState`에서 실제
  /// [WeatherService]를 생성한다.
  final WeatherService? weatherService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDark = true;
  final _avatarKey = GlobalKey();

  late final WeatherService _weatherService;
  WeatherResponse? _weatherData;
  bool _weatherLoading = true;
  bool _weatherHasError = false;

  @override
  void initState() {
    super.initState();
    _weatherService = widget.weatherService ?? WeatherService();
    _loadWeather();
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

  Future<void> _showAvatarMenu() async {
    final renderBox =
        _avatarKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    if (renderBox == null) return;

    final colors = _HomeColors(_isDark);
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

  /// "내 정보" 모달 (Figma node 6:17). 실제 회원 프로필 연동 전까지는
  /// Figma 목업과 동일한 더미 값을 보여준다.
  Future<void> _showMyInfoDialog() async {
    final colors = _HomeColors(_isDark);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            _MyInfoRow(colors: colors, label: '이름', value: '홍준표'),
            const SizedBox(height: 14),
            _MyInfoRow(colors: colors, label: '학과', value: '컴퓨터공학전공'),
            const SizedBox(height: 14),
            _MyInfoRow(colors: colors, label: '학년', value: '3학년'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _HomeColors(_isDark);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _Header(
                isDark: _isDark,
                colors: colors,
                avatarKey: _avatarKey,
                onAvatarTap: _showAvatarMenu,
                onToggle: (isDark) => setState(() => _isDark = isDark),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                children: [
                  _Headline(
                    colors: colors,
                    weatherLoading: _weatherLoading,
                    weatherHasError: _weatherHasError,
                    weatherData: _weatherData,
                  ),
                  const SizedBox(height: 16),
                  _RecommendCard(isDark: _isDark, onTap: _openPlaceholder),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RankCard(
                          isDark: _isDark,
                          onTap: _openPlaceholder,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MenuCard(
                          isDark: _isDark,
                          onTap: _openPlaceholder,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    colors: colors,
                    onMorePressed: _openPlaceholder,
                  ),
                  const SizedBox(height: 12),
                  _CalendarPromoCard(colors: colors, onTap: _openPlaceholder),
                  const SizedBox(height: 14),
                  _AdBannerPlaceholder(colors: colors),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 홈 화면 전용 라이트/다크 색상 세트.
/// Figma 노드(6:14 다크, 6:20 라이트)가 스크린샷으로 평탄화되어 있어 정확한 hex 값을
/// 추출할 수 없었다. 두 스크린샷을 눈으로 비교해 근사한 팔레트.
class _HomeColors {
  const _HomeColors(this.isDark);

  final bool isDark;

  Color get background =>
      isDark ? const Color(0xFF0B0B0D) : const Color(0xFFF2F2F2);

  Color get cardSurface =>
      isDark ? const Color(0xFF1C1C1F) : const Color(0xFFFFFFFF);

  Color get textPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1C);

  Color get textSecondary =>
      isDark ? const Color(0xFF9A9A9E) : const Color(0xFF6B6B70);

  Color get avatarBackground =>
      isDark ? const Color(0xFF1C1C1F) : const Color(0xFFFFFFFF);

  // 다크 모드일 때(스위치 썸이 왼쪽) 트랙 색.
  Color get switchTrackDark => const Color(0xFF2A2A2D);

  // 라이트 모드일 때(스위치 썸이 오른쪽) 트랙 색.
  Color get switchTrackLight => const Color(0xFFE4E4E8);

  Color get adBackground =>
      isDark ? const Color(0xFF1C1C1F) : const Color(0xFFE7E7EA);
}

// 카드 브랜드 컬러(다크 모드). 아바타 메뉴 "로그아웃" 등 모드 무관 포인트 컬러로도 쓰인다.
const Color _accentOrange = Color(0xFFFF7A29);
const Color _accentOrangeDeep = Color(0xFFFF5B00);
const Color _accentBlue = Color(0xFF3D6CFF);
const Color _accentBlueDeep = Color(0xFF2448D1);
const Color _accentPurple = Color(0xFF8B5CF6);
const Color _accentPurpleDeep = Color(0xFF6A3FE0);

// 라이트 모드 전용 카드 브랜드 컬러. 다크 모드와 동일한 원색은 흰 배경 위에서
// 너무 쨍하게 보여서, 채도/명도를 낮춘 별도 팔레트를 쓴다.
const Color _accentOrangeLight = Color(0xFFE46E25);
const Color _accentOrangeDeepLight = Color(0xFFC85719);
const Color _accentBlueLight = Color(0xFF3762E6);
const Color _accentBlueDeepLight = Color(0xFF3049A6);
const Color _accentPurpleLight = Color(0xFF7E53E0);
const Color _accentPurpleDeepLight = Color(0xFF5F39C8);
// Figma 스크린샷(node 6:16)의 "로그아웃" 텍스트를 스포이드로 찍어 확인한 값.
const Color _accentRed = Color(0xFFFF4D4F);

// 같은 스크린샷에서 "내 정보"/"이용약관"/"로그아웃" 사이 구분선을 스포이드로
// 찍어 확인한 값 — 카드 배경(약 0x19191B)보다 살짝 밝은 저대비 선.
const Color _menuDividerColor = Color(0xFF2C2C2F);

const List<String> _koreanWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// "9월 5일 토요일" 형식의 날짜 문자열. [DateTime.weekday]는 월=1~일=7.
String _formatKoreanDate(DateTime date) {
  return '${date.month}월 ${date.day}일 ${_koreanWeekdays[date.weekday - 1]}요일';
}

/// 좌측 아바타 + 날짜/인사말 + 우측 라이트⇄다크 토글 스위치.
class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.colors,
    required this.avatarKey,
    required this.onAvatarTap,
    required this.onToggle,
  });

  final bool isDark;
  final _HomeColors colors;
  final GlobalKey avatarKey;
  final VoidCallback onAvatarTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: ClipOval(
            child: Container(
              key: avatarKey,
              width: 52,
              height: 52,
              color: colors.avatarBackground,
              alignment: Alignment.center,
              // home_avatar.png는 원본 캔버스(230x230) 바닥 라인에 다리가
              // 그대로 걸쳐 잘려 있는 애셋이라(마진 0px), 어떤 레이아웃으로
              // 그려도 다리가 안 보였다. splash_character.png(전신, 다리까지
              // 포함)에서 배경색(#0A0A0B 단색, 투명 아님)만 크로마키로 제거해
              // assets/images/header_avatar.png를 새로 만들어 교체했다.
              child: FractionallySizedBox(
                widthFactor: 0.8,
                heightFactor: 0.8,
                child: Image.asset(
                  'assets/images/header_avatar.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatKoreanDate(DateTime.now()),
                style: TextStyle(color: colors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                '점심 맛있게 드세요!',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          isDark ? '다크' : '화이트',
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
        Switch(
          // Flutter Switch 기본 동작은 value=true일 때 썸이 오른쪽이다.
          // Figma 디자인상 라이트 모드일 때 썸이 오른쪽이므로 value는 '라이트 모드 여부'.
          value: !isDark,
          onChanged: (isLight) => onToggle(!isLight),
          activeThumbColor: _accentOrange,
          activeTrackColor: colors.switchTrackLight,
          inactiveThumbColor: _accentOrange,
          inactiveTrackColor: colors.switchTrackDark,
          trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ],
    );
  }
}

/// "오늘은 무얼 같이 해볼까요?" 헤드라인 + 날씨 아이콘.
///
/// 날씨는 로딩/성공/에러 3가지 상태를 구분해서 보여준다. 성공 시에는
/// [WeatherResponse.currentWeatherCode](WMO Weather Code)를
/// [_weatherDisplay]로 아이콘+한글 라벨로 바꾸고, 현재 온도를 함께 표시한다.
/// 에러 시에는 원인(네트워크/서버/파싱)과 무관하게 아이콘만 조용히
/// cloud_off로 바꾼다 — 이 화면에 스낵바/다이얼로그 등 방해되는 UI는 쓰지 않는다.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.colors,
    required this.weatherLoading,
    required this.weatherHasError,
    required this.weatherData,
  });

  final _HomeColors colors;
  final bool weatherLoading;
  final bool weatherHasError;
  final WeatherResponse? weatherData;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            '오늘은 무얼\n같이 해볼까요?',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
        ),
        _WeatherIndicator(
          colors: colors,
          weatherLoading: weatherLoading,
          weatherHasError: weatherHasError,
          weatherData: weatherData,
        ),
      ],
    );
  }
}

/// [_Headline] 우측의 날씨 아이콘/온도 영역. 로딩 중에는 작은 스피너,
/// 에러 시에는 cloud_off 아이콘, 성공 시에는 날씨 아이콘 + 현재 온도를 보여준다.
class _WeatherIndicator extends StatelessWidget {
  const _WeatherIndicator({
    required this.colors,
    required this.weatherLoading,
    required this.weatherHasError,
    required this.weatherData,
  });

  final _HomeColors colors;
  final bool weatherLoading;
  final bool weatherHasError;
  final WeatherResponse? weatherData;

  @override
  Widget build(BuildContext context) {
    if (weatherLoading) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    final weather = weatherData;
    if (weatherHasError || weather == null) {
      return Icon(Icons.cloud_off, color: colors.textSecondary, size: 44);
    }

    final display = _weatherDisplay(weather.currentWeatherCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(display.icon, color: const Color(0xFFFFC452), size: 36),
        const SizedBox(height: 4),
        Text(
          '${weather.currentTemp.round()}°C',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          display.label,
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

/// WMO Weather Code(현재 날씨 코드)를 아이콘+한글 라벨로 단순 매핑한다.
/// 전체 코드 표를 그대로 옮기지 않고, 명세에서 언급한 자주 쓰는 범위만
/// 구간으로 묶어서 구분한다:
/// 0=맑음, 1~3=대체로 흐림, 45·48=안개, 51~67=비, 71~77=눈, 80~82=소나기,
/// 95~99=뇌우. 그 외 값은 "알 수 없음"으로 처리한다.
({IconData icon, String label}) _weatherDisplay(int code) {
  if (code == 0) return (icon: Icons.wb_sunny, label: '맑음');
  if (code >= 1 && code <= 3) return (icon: Icons.cloud, label: '흐림');
  if (code == 45 || code == 48) return (icon: Icons.foggy, label: '안개');
  if (code >= 51 && code <= 67) return (icon: Icons.umbrella, label: '비');
  if (code >= 71 && code <= 77) return (icon: Icons.ac_unit, label: '눈');
  if (code >= 80 && code <= 82) return (icon: Icons.grain, label: '소나기');
  if (code >= 95 && code <= 99) {
    return (icon: Icons.thunderstorm, label: '뇌우');
  }
  return (icon: Icons.cloud, label: '알 수 없음');
}

/// 그라데이션 배경 + 장식용 원형 2개를 공통으로 그리는 카드 베이스.
class _GradientCard extends StatelessWidget {
  const _GradientCard({
    required this.colors,
    required this.onTap,
    required this.child,
    this.height,
  });

  final List<Color> colors;
  final VoidCallback onTap;
  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: _DecoCircle(size: 140, opacity: 0.08),
            ),
            Positioned(
              right: -10,
              top: 44,
              child: _DecoCircle(size: 90, opacity: 0.06),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _DecoCircle extends StatelessWidget {
  const _DecoCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "시간표를 짜볼까요?" 추천 카드.
class _RecommendCard extends StatelessWidget {
  const _RecommendCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientCard(
      onTap: onTap,
      height: 168,
      colors: isDark
          ? const [_accentOrange, _accentOrangeDeep]
          : const [_accentOrangeLight, _accentOrangeDeepLight],
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Badge(label: '추천'),
            const SizedBox(height: 16),
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white,
              size: 26,
            ),
            const Spacer(),
            const Text(
              '시간표를 짜볼까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '나만의 시간표를 만들고 저장해보세요',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "나는 학과에서 몇등일까요?" 카드.
class _RankCard extends StatelessWidget {
  const _RankCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientCard(
      onTap: onTap,
      height: 156,
      colors: isDark
          ? const [_accentBlue, _accentBlueDeep]
          : const [_accentBlueLight, _accentBlueDeepLight],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 26),
            const Spacer(),
            const Text(
              '나는 학과에서\n몇등일까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '두근두근',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "오늘의 메뉴는 무엇일까요?" 카드.
class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.isDark, required this.onTap});

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GradientCard(
      onTap: onTap,
      height: 156,
      colors: isDark
          ? const [_accentPurple, _accentPurpleDeep]
          : const [_accentPurpleLight, _accentPurpleDeepLight],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                color: isDark ? _accentPurpleDeep : _accentPurpleDeepLight,
                size: 16,
              ),
            ),
            const Spacer(),
            const Text(
              '오늘의 메뉴는\n무엇일까요?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '학식을 조회할 수 있어요!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "필요한 기능만 모아봤어요!" + "모아보기" 섹션 헤더.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.colors, required this.onMorePressed});

  final _HomeColors colors;
  final VoidCallback onMorePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '필요한 기능만 모아봤어요!',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        GestureDetector(
          onTap: onMorePressed,
          child: Text(
            '모아보기',
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// "우진이의 캘린더" 프로모 카드.
class _CalendarPromoCard extends StatelessWidget {
  const _CalendarPromoCard({required this.colors, required this.onTap});

  final _HomeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '우진이의 캘린더',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '학교 일정을 알림으로 받아보세요',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Image.asset(
              colors.isDark
                  ? 'assets/images/calendar_mascot_dark.png'
                  : 'assets/images/calendar_mascot.png',
              width: 72,
              height: 68,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}

/// "내 정보" 모달의 한 줄(라벨+값).
class _MyInfoRow extends StatelessWidget {
  const _MyInfoRow({
    required this.colors,
    required this.label,
    required this.value,
  });

  final _HomeColors colors;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 광고 SDK 연동 전 자리만 잡아두는 placeholder.
class _AdBannerPlaceholder extends StatelessWidget {
  const _AdBannerPlaceholder({required this.colors});

  final _HomeColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.adBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '광고 영역',
        style: TextStyle(color: colors.textSecondary, fontSize: 13),
      ),
    );
  }
}
