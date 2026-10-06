import 'package:flutter/material.dart';

import '../services/weather_service.dart';
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
import 'home_placeholder_screen.dart';
import 'login_screen.dart';
import 'terms_detail_screen.dart';

/// 좌상단 아바타를 눌렀을 때 뜨는 드롭다운 메뉴 항목 (Figma node 6:16).
enum _AvatarMenuAction { myInfo, terms, logout }

/// "우진이의 하루" 홈 화면(메인 대시보드) (Figma node 6:14 다크 / 6:20 라이트).
///
/// 다른 화면은 전부 다크 전용(theme/app_colors.dart의 AppColors)이지만, 이 화면만
/// 라이트/다크 테마 토글을 지원한다. 전역 테마나 다른 화면에는 영향을 주지 않도록
/// 로컬 State(`_isDark`)로만 관리하고, 색상도 이 파일 안의 [HomeColors]로 분리했다.
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

  /// "내 정보" 모달 (Figma node 6:17). 실제 회원 프로필 연동 전까지는
  /// Figma 목업과 동일한 더미 값을 보여준다.
  Future<void> _showMyInfoDialog() async {
    final colors = HomeColors(_isDark);
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
            MyInfoRow(colors: colors, label: '이름', value: '홍준표'),
            const SizedBox(height: 14),
            MyInfoRow(colors: colors, label: '학과', value: '컴퓨터공학전공'),
            const SizedBox(height: 14),
            MyInfoRow(colors: colors, label: '학년', value: '3학년'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
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
                  ),
                  const SizedBox(height: 16),
                  RecommendCard(isDark: _isDark, onTap: _openPlaceholder),
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
                  SectionHeader(
                    colors: colors,
                    onMorePressed: _openPlaceholder,
                  ),
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
