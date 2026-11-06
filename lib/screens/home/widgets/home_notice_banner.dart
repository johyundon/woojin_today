import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/academic_schedule_service.dart';
import '../../../services/service_factory.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pressable.dart';
import '../../notice/notice_detail_screen.dart';
import '../services/home_banner_items.dart';

/// 홈·모아보기 위쪽의 공지·이벤트 배너(Figma v7 "03 홈"/"04 모아보기"의 353×76 칸).
///
/// 최근 공지와 2주 안의 학사일정을 한 장씩 보여주고 4초마다 옆으로 넘긴다.
/// 공지를 누르면 그 공지 상세, 학사일정을 누르면 [onOpenCalendar]로 간다.
/// 보여줄 것이 없으면(불러오는 중·실패·데이터 없음) 칸 자체를 숨긴다.
class HomeNoticeBanner extends StatefulWidget {
  const HomeNoticeBanner({
    super.key,
    this.load,
    this.onOpenCalendar,
    this.padding = EdgeInsets.zero,
    this.now,
  });

  /// 배너 카드를 불러오는 방법. 없으면 실제 공지·학사일정 서비스를 쓴다.
  /// 홈은 새 공지 확인이 끝난 뒤 불러오도록 이 값을 넘긴다.
  final Future<List<HomeBannerItem>> Function()? load;

  final VoidCallback? onOpenCalendar;

  /// 배너 바깥 여백. 배너를 숨길 때는 여백도 함께 없어진다.
  final EdgeInsets padding;

  /// 테스트용 오늘 날짜(D-day 계산).
  final DateTime Function()? now;

  /// 카드가 넘어가는 간격.
  static const autoSlide = Duration(seconds: 4);

  @override
  State<HomeNoticeBanner> createState() => _HomeNoticeBannerState();
}

class _HomeNoticeBannerState extends State<HomeNoticeBanner> {
  final _controller = PageController();
  List<HomeBannerItem> _items = const [];
  int _page = 0;
  Timer? _timer;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final load =
        widget.load ??
        () => loadHomeBannerItems(
          notices: ServiceFactory.notice(),
          schedule: ServiceFactory.academicSchedule(),
          now: _now(),
        );
    List<HomeBannerItem> items;
    try {
      items = await load();
    } catch (e) {
      debugPrint('[HomeBanner] 불러오기 실패: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _items = items);
    _timer?.cancel();
    if (items.length > 1) {
      _timer = Timer.periodic(HomeNoticeBanner.autoSlide, (_) => _next());
    }
  }

  void _next() {
    if (!mounted || !_controller.hasClients || _items.length < 2) return;
    final next = (_page + 1) % _items.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _open(HomeBannerItem item) {
    final notice = item.notice;
    if (notice != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => NoticeDetailScreen(notice: notice)),
      );
    } else {
      widget.onOpenCalendar?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: _items.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Pressable(
                pressedScale: 0.98,
                onTap: () => _open(_items[i]),
                child: _BannerCard(item: _items[i], today: _now()),
              ),
            ),
            if (_items.length > 1)
              Positioned(
                right: 12,
                bottom: 10,
                child: IgnorePointer(
                  child: Row(
                    children: [
                      for (var i = 0; i < _items.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(left: 4),
                          width: i == _page ? 12 : 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? AppColors.blue
                                : AppColors.checkLine,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.item, required this.today});

  final HomeBannerItem item;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final notice = item.notice;
    final event = item.event;
    final (icon, label, title, showDot) = notice != null
        ? (
            Icons.campaign_rounded,
            '${notice.tag.label} 공지 · ${_shortDate(notice.date)}',
            notice.title,
            notice.isNew,
          )
        : (Icons.event_rounded, _eventLabel(event!), event.title, false);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.blueText,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (showDot) ...[
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE64343),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Padding(
                  // 오른쪽 아래 넘김 점과 겹치지 않게 조금 비운다.
                  padding: const EdgeInsets.only(right: 34),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "2026.11.06" → "11.06".
  static String _shortDate(String date) {
    final parts = date.split('.');
    return parts.length == 3 ? '${parts[1]}.${parts[2]}' : date;
  }

  /// "D-3 · 학사일정", 진행 중이면 "진행 중 · 학사일정", 오늘이면 "오늘 · 학사일정".
  String _eventLabel(AcademicScheduleItem e) {
    final day = DateTime(today.year, today.month, today.day);
    final start = DateTime(e.start.year, e.start.month, e.start.day);
    final diff = start.difference(day).inDays;
    final when = diff > 0
        ? 'D-$diff'
        : diff == 0
        ? '오늘'
        : '진행 중';
    return '$when · 학사일정';
  }
}
