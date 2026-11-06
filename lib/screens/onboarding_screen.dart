import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/terms_acceptance_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/pressable.dart';
import 'student_id_login_complete_screen.dart';

/// 온보딩 화면 ("우진이의 하루" v7 디자인 09~11).
/// 최초 로그인 후 이용약관 동의가 끝나면 학번별로 한 번 보여주는 3장짜리 소개
/// 화면으로, 마지막 장의 "시작하기"를 누르면 완료를 기록하고 로그인 완료
/// 화면으로 넘어간다. "시작하기" 전에 앱을 끄면 다음 로그인 때 다시 나온다.
/// 로그인 이후에 나오는 화면이라 로그인에서 받은 세션 쿠키를 그대로 들고
/// 있다가 다음 화면에 넘긴다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.userId,
    this.jsessionId,
    this.wmonid,
    this.userId2,
  });

  /// 온보딩 완료를 기록할 학번.
  final String userId;
  final String? jsessionId;
  final String? wmonid;
  final String? userId2;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pageCount = 3;

  final _pageController = PageController();
  int _page = 0;

  bool get _isLastPage => _page == _pageCount - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_isLastPage) {
      _goToLoginComplete();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goToLoginComplete() async {
    await TermsAcceptanceStorage().markOnboardingCompleted(widget.userId);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StudentIdLoginCompleteScreen(
          jsessionId: widget.jsessionId,
          wmonid: widget.wmonid,
          userId2: widget.userId2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 흰 바탕이라 상태 표시줄 글자(시계·배터리)를 어둡게 그린다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: [
            // 화면 가운데쯤 퍼지는 옅은 하늘색 원(디자인 09~11 배경).
            Positioned(
              left: -155,
              top: 60,
              child: Container(
                width: 700,
                height: 700,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [_glow, Color(0x8CDCEAFC), Color(0x00DCEAFC)],
                    stops: [0, 0.38, 0.68],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: const [
                        _CampusPage(),
                        _FeaturesPage(),
                        _NotificationsPage(),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _pageCount; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _Dot(active: i == _page),
                      ],
                    ],
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _NextButton(
                      label: _isLastPage ? '시작하기' : '다음',
                      onPressed: _onNext,
                    ),
                  ),
                  // 디자인의 "일단 구경만 할래" 자리(앱에 해당 기능이 없어 버튼은
                  // 두지 않고 자리만 남겨 버튼 위치를 디자인과 맞춘다).
                  const SizedBox(height: 12 + 35 + 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _glow = Color(0xFFDCEAFC);
}

/// 파란 "다음/시작하기" 버튼(글자 + 화살표).
class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable.effect(
      pressedScale: 0.96,
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

// 온보딩 장식 카드 색(디자인 09~11 값).
const _softCardBg = Color(0xFFF5F8FE);
const _softCardLine = Color(0xFFE3ECFA);
const _dotOff = Color(0xFFD1D5DB);

/// 장식 영역의 기준 크기. 디자인(390pt 폭 화면)에서 제목 아래부터 점 표시
/// 위까지의 영역이며, 화면이 이보다 작으면 통째로 줄여서 넘치지 않게 한다.
const _decorSize = Size(390, 408);

/// 온보딩 한 장의 공통 틀: 파란 글자 이름표 + 큰 제목 + 아래 장식 영역.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.badge,
    required this.title,
    required this.decor,
  });

  final String badge;
  final String title;

  /// 장식 요소들. [_decorSize] 기준 좌표의 [_Placed]로 배치한다.
  final List<Widget> decor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.blueSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textStrong,
                  fontSize: 31,
                  height: 1.4,
                  letterSpacing: -1.395,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox.fromSize(
                size: _decorSize,
                child: Stack(clipBehavior: Clip.none, children: decor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 장식 요소 하나를 중심점([cx], [cy]) 기준으로 놓고 [angle]만큼 기울인다.
/// 디자인 값은 기울인 뒤의 바깥 상자라서, 중심점으로 맞추면 위치가 그대로 맞는다.
class _Placed extends StatelessWidget {
  const _Placed({
    required this.cx,
    required this.cy,
    required this.child,
    this.angle = 0,
  });

  final double cx;
  final double cy;
  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: cx,
      top: cy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.rotate(angle: angle, child: child),
      ),
    );
  }
}

/// 1번째 장: 캠퍼스 소개.
class _CampusPage extends StatelessWidget {
  const _CampusPage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      badge: '대진대 26학번 필수템',
      title: '캠퍼스 처음이지?\n내가 다\n알려줄게!',
      decor: [
        _Placed(
          cx: 89,
          cy: 135,
          angle: -0.1396, // -8˚
          child: _InfoChip(
            icon: Icons.location_on_rounded,
            iconColor: AppColors.blue,
            textColor: AppColors.textStrong,
            soft: false,
            label: '강의실 어디야',
          ),
        ),
        _Placed(
          cx: 120.5,
          cy: 201.5,
          angle: 0.0873, // +5˚
          child: _InfoChip(
            icon: Icons.directions_bus_rounded,
            iconColor: AppColors.textStrong,
            textColor: AppColors.textStrong,
            soft: true,
            label: '셔틀 몇 분 남음?',
          ),
        ),
        _Placed(
          cx: 88,
          cy: 268,
          angle: -0.0698, // -4˚
          child: _InfoChip(
            icon: Icons.restaurant_rounded,
            iconColor: AppColors.blue,
            textColor: AppColors.blue,
            soft: true,
            label: '오늘 학식 뭐임',
          ),
        ),
        _Placed(
          cx: 275.5,
          cy: 229.5,
          child: MascotSticker(width: 243, angle: 0.1047),
        ),
      ],
    );
  }
}

/// 2번째 장: 시간표/학식 등 핵심 기능 소개.
class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      badge: '하루가 편해지는 기능',
      title: '시간표부터\n학식까지\n한 번에!',
      decor: [
        _Placed(
          cx: 212.5,
          cy: 257,
          child: MascotSticker(width: 261, angle: -0.0698),
        ),
        _Placed(
          cx: 105,
          cy: 116,
          angle: -0.1047, // -6˚
          child: _FeatureCard(
            icon: Icons.calendar_month_rounded,
            iconBoxSize: 40,
            iconBackground: AppColors.blue,
            iconColor: Colors.white,
            soft: false,
            textColor: AppColors.textStrong,
            caption: '다음 수업',
            value: '10:30 자료구조',
          ),
        ),
        _Placed(
          cx: 310.5,
          cy: 228,
          angle: 0.0873, // +5˚
          child: _FeatureCard(
            icon: Icons.leaderboard_rounded,
            iconBoxSize: 39,
            iconBackground: Colors.white,
            iconColor: AppColors.textStrong,
            soft: true,
            textColor: AppColors.textStrong,
            caption: '학과 등수',
            value: '12위',
          ),
        ),
        _Placed(
          cx: 93,
          cy: 356,
          angle: -0.0524, // -3˚
          child: _FeatureCard(
            icon: Icons.stars_rounded,
            iconBoxSize: 38,
            iconBackground: AppColors.blue,
            iconColor: Colors.white,
            soft: true,
            textColor: AppColors.blue,
            caption: '마일리지',
            value: '1,240 P',
          ),
        ),
      ],
    );
  }
}

/// 3번째 장: 공지/일정 알림 소개.
class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingPage(
      badge: '신입생 꿀팁',
      title: '공지도 일정도\n놓치지 않게\n챙겨줄게!',
      decor: [
        _Placed(
          cx: 324.5,
          cy: 42.5,
          child: MascotSticker(width: 119, angle: 0.1396),
        ),
        _Placed(
          cx: 195.5,
          cy: 148.5,
          angle: -0.0349, // -2˚
          child: _NotificationCard(
            icon: Icons.campaign_rounded,
            iconBackground: AppColors.blueSoft,
            iconColor: AppColors.blue,
            time: '지금',
            title: '새 공지가 올라왔어요',
            subtitle: '2학기 수강신청 안내',
          ),
        ),
        _Placed(
          cx: 205,
          cy: 243,
          angle: 0.0262, // +1.5˚
          child: _NotificationCard(
            icon: Icons.event_rounded,
            iconBackground: AppColors.blueSoft,
            iconColor: AppColors.textStrong,
            time: '10분 전',
            title: '중간고사 D-12',
            subtitle: '학사일정에 등록했어요',
          ),
        ),
        _Placed(
          cx: 189.5,
          cy: 336.5,
          angle: -0.0175, // -1˚
          child: _NotificationCard(
            icon: Icons.forum_rounded,
            iconBackground: AppColors.blue,
            iconColor: Colors.white,
            time: '1시간 전',
            title: '상담 예약이 확정됐어요',
            subtitle: '장윤석 교수님 · 10/28 14:00',
          ),
        ),
      ],
    );
  }
}

BoxDecoration _decorCardDecoration({required bool soft, required double r}) {
  return BoxDecoration(
    color: soft ? _softCardBg : Colors.white,
    borderRadius: BorderRadius.circular(r),
    border: soft ? Border.all(color: _softCardLine) : null,
    boxShadow: AppColors.cardShadow,
  );
}

/// 2번째 장의 작은 기능 카드(아이콘 + 캡션 + 값).
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconBoxSize,
    required this.iconBackground,
    required this.iconColor,
    required this.soft,
    required this.textColor,
    required this.caption,
    required this.value,
  });

  final IconData icon;
  final double iconBoxSize;
  final Color iconBackground;
  final Color iconColor;

  /// true면 옅은 하늘색 바탕 + 테두리, false면 흰 바탕.
  final bool soft;
  final Color textColor;
  final String caption;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
      decoration: _decorCardDecoration(soft: soft, r: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                caption,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14.5,
                  height: 1.4,
                  letterSpacing: -0.29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3번째 장의 알림 카드(앱 이름 + 시간 / 제목 / 부제).
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.time,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String time;
  final String title;
  final String subtitle;

  static const _metaStyle = TextStyle(
    color: AppColors.textSub,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w700,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 340,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xF7FFFFFF),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 21, color: iconColor),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('우진이의 하루', style: _metaStyle)),
                    Text(time, style: _metaStyle),
                  ],
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 13.5,
                    height: 1.4,
                    letterSpacing: -0.27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textBody,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 1번째 장의 말풍선 같은 칩(아이콘 + 글자).
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.soft,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color textColor;

  /// true면 옅은 하늘색 바탕 + 테두리, false면 흰 바탕.
  final bool soft;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: _decorCardDecoration(soft: soft, r: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 22 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.blue : _dotOff,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
