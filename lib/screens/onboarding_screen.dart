import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import '../widgets/pressable.dart';
import 'student_id_login_complete_screen.dart';

/// 온보딩 화면 ("우진이의 하루" v4 리디자인, 01 섹션 3~5번째 화면).
/// 최초 로그인 후 이용약관 동의가 끝나면 한 번 보여주는 3장짜리 소개 화면으로,
/// 마지막 장의 "시작하기"를 누르면 로그인 완료 화면으로 넘어간다. 로그인
/// 이후에 나오는 화면이라 로그인에서 받은 세션 쿠키를 그대로 들고 있다가 다음
/// 화면에 넘긴다.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.jsessionId,
    this.wmonid,
    this.userId2,
  });

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

  void _goToLoginComplete() {
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
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
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
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Pressable.effect(
                  pressedScale: 0.96,
                  child: ElevatedButton(
                    onPressed: _onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.ink,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      _isLastPage ? '시작하기 →' : '다음 →',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// 온보딩 한 장의 공통 틀: 라임색 알약 + 큰 제목 + 아래 장식 영역.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.badge,
    required this.title,
    required this.body,
    this.gap = 16,
  });

  final String badge;
  final String title;
  final Widget body;

  /// 제목과 [body] 사이 간격.
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: gap),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// 1번째 장: 캠퍼스 소개.
class _CampusPage extends StatelessWidget {
  const _CampusPage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      badge: '대진대 26학번 필수템',
      title: '캠퍼스 처음이지?\n내가 다\n알려줄게!',
      gap: 100,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _InfoChip(
                icon: Icons.location_on,
                iconColor: AppColors.cobalt,
                backgroundColor: Colors.white,
                label: '강의실 어디야',
                angle: -0.1396, // -8˚
              ),
              const SizedBox(height: 28),
              // 디자인에서 셔틀 칩만 오른쪽으로 더 들어가 있어서
              // (강의실/학식 칩은 같은 왼쪽 선) 그대로 맞춘다.
              const Padding(
                padding: EdgeInsets.only(left: 24),
                child: _InfoChip(
                  icon: Icons.directions_bus,
                  iconColor: AppColors.ink,
                  backgroundColor: AppColors.blushPink,
                  label: '셔틀 몇 분 남음?',
                  angle: 0.0873, // +5˚
                ),
              ),
              const SizedBox(height: 28),
              const _InfoChip(
                icon: Icons.restaurant,
                iconColor: AppColors.ink,
                backgroundColor: AppColors.lime,
                label: '오늘 학식 뭐임',
                angle: -0.0698, // -4˚
              ),
            ],
          ),
          const Positioned(
            top: -40,
            right: -220,
            child: MascotSticker(width: 240, angle: 0.18),
          ),
        ],
      ),
    );
  }
}

/// 2번째 장: 시간표/학식 등 핵심 기능 소개.
class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      badge: '하루가 편해지는 기능',
      title: '시간표부터\n학식까지\n한 번에!',
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                color: AppColors.cobaltDeep,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            top: 100,
            child: _FeatureCard(
              icon: Icons.calendar_today,
              iconBackground: AppColors.cobalt,
              iconColor: Colors.white,
              backgroundColor: Colors.white,
              caption: '다음 수업',
              value: '10:30 자료구조',
              angle: -0.14,
            ),
          ),
          const Align(
            alignment: Alignment(0.1, 0.9),
            child: MascotSticker(width: 190, angle: 0.06),
          ),
          const Positioned(
            right: -4,
            top: 128,
            child: _FeatureCard(
              icon: Icons.bar_chart,
              iconBackground: AppColors.ink,
              iconColor: Colors.white,
              backgroundColor: AppColors.blushPink,
              caption: '학교 등수',
              value: '12위',
              angle: 0.14,
            ),
          ),
          const Positioned(
            left: 8,
            bottom: 20,
            child: _FeatureCard(
              icon: Icons.stars,
              iconBackground: AppColors.ink,
              iconColor: AppColors.lime,
              backgroundColor: AppColors.lime,
              caption: '마일리지',
              value: '1,240 P',
              angle: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3번째 장: 공지/일정 알림 소개.
class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    return _OnboardingPage(
      badge: '신입생 꿀팁',
      title: '공지도 일정도\n놓치지 않게\n챙겨줄게!',
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -80,
            top: -20,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                color: AppColors.cobaltDeep,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Positioned(
            right: 8,
            top: -50,
            child: MascotSticker(width: 110, angle: 0.1),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 84,
            child: _NotificationCard(
              icon: Icons.campaign,
              iconBackground: AppColors.lime,
              time: '지금',
              title: '새 공지가 올라왔어요',
              subtitle: '2학기 수강신청 안내',
              angle: -0.035,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 176,
            child: _NotificationCard(
              icon: Icons.event,
              iconBackground: AppColors.blushPink,
              time: '10분 전',
              title: '중간고사 D-12',
              subtitle: '학사일정에 등록했어요',
              angle: 0.03,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 268,
            child: _NotificationCard(
              icon: Icons.chat_bubble,
              iconBackground: AppColors.cobalt,
              time: '1시간 전',
              title: '상담 예약이 확정됐어요',
              subtitle: '장윤석 교수님 · 10/28 14:00',
              angle: -0.04,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2번째 장의 작은 기능 카드(아이콘 + 캡션 + 값). 스티커처럼 살짝 기울어져 있다.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.backgroundColor,
    required this.caption,
    required this.value,
    required this.angle,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Color backgroundColor;
  final String caption;
  final String value;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030A7F).withValues(alpha: 0.22),
              offset: const Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  caption,
                  style: const TextStyle(
                    color: Color(0xFF5A5852),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 3번째 장의 알림 카드(앱 이름 + 시간 / 제목 / 부제). 살짝 기울어져 있다.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.iconBackground,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.angle,
  });

  final IconData icon;
  final Color iconBackground;
  final String time;
  final String title;
  final String subtitle;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030A7F).withValues(alpha: 0.22),
              offset: const Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconBackground == AppColors.cobalt
                    ? Colors.white
                    : AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '우진이의 하루',
                          style: TextStyle(
                            color: Color(0xFF5A5852),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0xFF5A5852),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF5A5852),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.label,
    this.angle = 0,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String label;

  /// 라디안 단위 기울기. 디자인에서 칩마다 제각각 살짝 기울어진 스티커처럼
  /// 붙어있어서(CSS transform matrix 값을 그대로 역산한 각도), 칩마다 다른
  /// 값을 넘긴다.
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF030A7F).withValues(alpha: 0.22),
              offset: const Offset(0, 10),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 18 : 6,
      height: 10,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
