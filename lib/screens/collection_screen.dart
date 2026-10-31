import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/mascot_sticker.dart';
import 'advisor/advisor_consultation_screen.dart';
import 'calendar/calendar_screen.dart';
import 'campus_map/campus_map_screen.dart';
import 'fileshare/fileshare_screen.dart';
import 'graduation/graduation_credit_screen.dart';
import 'home/rank/department_rank_screen.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'home_placeholder_screen.dart';
import 'mileage/mileage_screen.dart';
import 'notice/notice_screen.dart';
import 'shuttle/shuttle_screen.dart';
import 'weather/weather_page.dart';
import '../widgets/pressable.dart';

/// "모아보기" 화면 ("우진이의 하루" v4 리디자인).
///
/// 홈 화면의 "모아보기" 탭에서 진입하며, 파란 헤더 아래 흰 시트에 전체 기능을
/// 4열 아이콘 그리드로 나열한다. 구현된 기능은 그 화면으로, 아직 구현되지 않은
/// 항목은 [HomePlaceholderScreen]으로 이동한다.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({this.userId2, this.onTabTap, super.key});

  /// 하단 탭 바의 시간표/캘린더/MY 탭 동작. 홈 화면이 쓰는 핸들러를 그대로
  /// 받는다(MY 메뉴가 홈의 학생 정보 상태에 의존하기 때문). 홈(2) 탭은 이
  /// 화면을 닫고 홈으로 돌아가는 것으로 여기서 직접 처리한다.
  final ValueChanged<int>? onTabTap;

  /// 포털 로그인으로 얻은 본인 SSO uid. "지도교수 상담" 카드가 지도교수
  /// 조회에 써야 해서 홈 화면에서 그대로 전달받는다.
  final String? userId2;

  void _openCalendar(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CalendarScreen(onTabTap: onTabTap)),
    );
  }

  static void _openCampusMap(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CampusMapScreen()));
  }

  static void _openMileage(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const MileageScreen()));
  }

  static void _openNotice(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NoticeScreen()));
  }

  static void _openWeather(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const WeatherPage()));
  }

  static void _openFileShare(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FileShareScreen()));
  }

  void _openDepartmentRank(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DepartmentRankScreen(isDark: true, userId2: userId2),
      ),
    );
  }

  void _openGraduationCredit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GraduationCreditScreen(userId2: userId2),
      ),
    );
  }

  static void _openShuttle(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ShuttleScreen()));
  }

  void _openAdvisorConsultation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvisorConsultationScreen(userId2: userId2),
      ),
    );
  }

  List<_CollectionItem> get _items => [
    const _CollectionItem(
      label: '연강',
      icon: Icons.directions_walk_rounded,
      onTap: _openCampusMap,
    ),
    _CollectionItem(
      label: '학과등수',
      icon: Icons.bar_chart_rounded,
      onTap: _openDepartmentRank,
    ),
    _CollectionItem(
      label: '교수상담',
      icon: Icons.school_rounded,
      onTap: _openAdvisorConsultation,
    ),
    const _CollectionItem(
      label: '파일공유',
      icon: Icons.folder_shared_rounded,
      onTap: _openFileShare,
    ),
    const _CollectionItem(
      label: '마일리지',
      icon: Icons.stars_rounded,
      onTap: _openMileage,
    ),
    const _CollectionItem(
      label: '날씨',
      icon: Icons.wb_cloudy_rounded,
      onTap: _openWeather,
    ),
    _CollectionItem(
      label: '캘린더',
      icon: Icons.event_rounded,
      onTap: _openCalendar,
    ),
    const _CollectionItem(
      label: '공지사항',
      icon: Icons.campaign_rounded,
      onTap: _openNotice,
    ),
    const _CollectionItem(
      label: '캠퍼스 지도',
      icon: Icons.map_rounded,
      onTap: _openCampusMap,
    ),
    const _CollectionItem(
      label: '셔틀버스',
      icon: Icons.directions_bus_rounded,
      onTap: _openShuttle,
    ),
    _CollectionItem(
      label: '졸업학점',
      icon: Icons.fact_check_rounded,
      onTap: _openGraduationCredit,
    ),
  ];

  void _openPlaceholder(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()));
  }

  /// 하단 탭 바. 1(모아보기)은 이미 이 화면이라 아무것도 하지 않는다. 다른 탭은 홈이
  /// 넘겨준 [onTabTap]이 그 탭 화면으로 바꿔 준다(홈 탭은 홈으로 돌아감). 콜백이
  /// 없으면 홈 탭만 이전 화면으로 돌아간다.
  void _onTabTap(BuildContext context, int index) {
    if (index == 1) return;
    final callback = onTabTap;
    if (callback != null) {
      callback(index);
    } else if (index == 2) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final bottomInset = 12 + 68 + MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.cobalt,
      extendBody: true,
      bottomNavigationBar: HomeBottomNav(
        selectedIndex: 1,
        onTap: (i) => _onTabTap(context, i),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '필요한 거 다 있음',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '뭐 찾아?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    top: -6,
                    right: 4,
                    child: MascotSticker(width: 64),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, bottomInset + 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '전체 메뉴',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '편집',
                            style: TextStyle(
                              color: AppColors.ink.withValues(alpha: 0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.8,
                        children: [
                          for (final item in items)
                            _CollectionGridItem(
                              item: item,
                              onTap: () =>
                                  (item.onTap ?? _openPlaceholder)(context),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionItem {
  const _CollectionItem({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;

  /// 이 항목을 눌렀을 때 이동할 화면. null이면 아직 구현되지 않은 기능이라
  /// [CollectionScreen._openPlaceholder]로 대체된다.
  final void Function(BuildContext context)? onTap;
}

class _CollectionGridItem extends StatelessWidget {
  const _CollectionGridItem({required this.item, required this.onTap});

  final _CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1EFEA),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(item.icon, color: AppColors.cobalt, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
