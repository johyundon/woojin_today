import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'advisor/advisor_consultation_screen.dart';
import 'calendar/calendar_screen.dart';
import 'campus_map/campus_map_screen.dart';
import 'fileshare/fileshare_screen.dart';
import 'home_placeholder_screen.dart';
import 'mileage/mileage_screen.dart';
import 'notice/notice_screen.dart';

/// "모아보기" 화면 (Figma node 6:76 헤더 / 6:77 리스트, 다크 전용).
///
/// 홈 화면의 "모아보기" 버튼에서 진입하며, 7개 기능 카드를 세로로 나열한다.
/// 구현된 기능(캘린더 등)은 그 화면으로, 아직 구현되지 않은 카드는 다른
/// 미구현 기능 카드와 동일하게 [HomePlaceholderScreen]으로 이동한다.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({this.userId2, super.key});

  /// 포털 로그인으로 얻은 본인 SSO uid. "지도교수 상담" 카드가 지도교수
  /// 조회에 써야 해서 홈 화면에서 그대로 전달받는다.
  final String? userId2;

  static void _openCalendar(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CalendarScreen()));
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

  static void _openFileShare(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const FileShareScreen()));
  }

  void _openAdvisorConsultation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdvisorConsultationScreen(userId2: userId2),
      ),
    );
  }

  List<_CollectionItem> get _items => [
    _CollectionItem(
      title: '우진이의 캘린더',
      description: '학교 일정을 알림으로 받아보세요',
      icon: Icons.calendar_month,
      imagePath: 'assets/images/calendar_mascot_dark.png',
      imageSize: 84,
      iconOnLeft: false,
      onTap: _openCalendar,
    ),
    _CollectionItem(
      title: '공지사항을\n알려드릴게요!',
      description: '무슨일이 있었을까요?!',
      icon: Icons.campaign,
      imagePath: 'assets/images/collection_notice.png',
      imageSize: 84,
      iconOnLeft: true,
      onTap: _openNotice,
    ),
    _CollectionItem(
      title: '연강이 가능할까요?',
      description: '건물간 도보 시간을 알려드릴께요!',
      icon: Icons.directions_walk,
      imagePath: 'assets/images/collection_break.png',
      imageSize: 84,
      iconOnLeft: false,
      onTap: _openCampusMap,
    ),
    _CollectionItem(
      title: '마일리지',
      description: '마일리지 관련 정보를 알려드릴게요!',
      icon: Icons.emoji_events,
      imagePath: 'assets/images/collection_mileage.png',
      imageSize: 84,
      iconOnLeft: true,
      onTap: _openMileage,
    ),
    _CollectionItem(
      title: '지도교수 상담',
      description: '내 지도교수님은 누구실까요?',
      icon: Icons.person_search,
      imagePath: 'assets/images/collection_advisor.png',
      imageSize: 84,
      iconOnLeft: false,
      onTap: _openAdvisorConsultation,
    ),
    const _CollectionItem(
      title: '졸업학점',
      description: '졸업하려면 몇학점 남았을까요?',
      icon: Icons.school,
      imagePath: 'assets/images/collection_credit.png',
      imageSize: 84,
      iconOnLeft: true,
    ),
    _CollectionItem(
      title: '파일공유',
      description: '중요한 파일을 안전하고 손쉽게 공유해요!',
      icon: Icons.description,
      imagePath: 'assets/images/collection_fileshare.png',
      imageSize: 84,
      iconOnLeft: false,
      onTap: _openFileShare,
    ),
  ];

  void _openPlaceholder(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 20, 8),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _CollectionItemCard(
                    item: item,
                    onTap: () => (item.onTap ?? _openPlaceholder)(context),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionItem {
  const _CollectionItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconOnLeft,
    this.imagePath,
    this.imageSize = 64,
    this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final bool iconOnLeft;
  final String? imagePath;
  final double imageSize;

  /// 이 카드를 눌렀을 때 이동할 화면. null이면 아직 구현되지 않은 기능이라
  /// [CollectionScreen._openPlaceholder]로 대체된다.
  final void Function(BuildContext context)? onTap;
}

class _CollectionItemCard extends StatelessWidget {
  const _CollectionItemCard({required this.item, required this.onTap});

  final _CollectionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textBlock = Expanded(
      child: Column(
        crossAxisAlignment: item.iconOnLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.title,
            textAlign: item.iconOnLeft ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: item.iconOnLeft ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );

    final iconBadge = item.imagePath != null
        ? Image.asset(
            item.imagePath!,
            height: item.imageSize,
            fit: BoxFit.contain,
          )
        : Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: Colors.white, size: 24),
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: item.iconOnLeft
              ? [iconBadge, const SizedBox(width: 16), textBlock]
              : [textBlock, const SizedBox(width: 16), iconBadge],
        ),
      ),
    );
  }
}
