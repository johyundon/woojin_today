import 'package:flutter/material.dart';

import '../../services/notice_service.dart';
import '../../services/notice_watcher.dart';
import '../../services/notification_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import '../calendar/widgets/ringing_bell.dart';
import '../../widgets/mascot_sticker.dart';
import 'models/notice_item.dart';
import 'services/notice_read_storage.dart';
import 'widgets/notice_list_card.dart';

/// "공지사항" 화면("놓치면 안 되는 공지" v4 리디자인). 전체/학사/장학/학과/행사
/// 칩으로 거르고, 카드의 북마크로 중요한 공지를 표시해 둘 수 있다(북마크는
/// 저장하지 않고 화면이 열려 있는 동안만 유지된다).
///
/// 학사공지·마일리지장학 공지를 학교 홈페이지에서 받아 보여준다([NoticeService],
/// 1시간 캐시, 당겨서 새로고침). 실제 게시판이 없는 학과·행사 탭과 목업 공지
/// ([NoticeMockData](services/notice_mock_data.dart))는 코드를 남겨 두고 화면에서만
/// 숨겼다([_visibleTags]).
///
/// "새 글 알림 받기" 토글(작은 종 버튼)은 기기에 저장된다. 켜 두면 앱을 열거나
/// 다시 돌아올 때 새 공지가 있으면 알림을 띄운다([NoticeWatcher]). 서버가 없어
/// 앱이 꺼져 있을 때는 확인하지 못한다. 켤 때 알림 권한을 묻고, 기본은 꺼짐이다.
/// 이 화면을 열면 홈 종 아이콘의 "새 공지" 점을 지운다.
class NoticeScreen extends StatefulWidget {
  const NoticeScreen({this.service, this.watcher, super.key});

  /// 테스트용 주입 지점.
  final NoticeServiceBase? service;

  /// 알림 켜짐 저장·새 공지 표시 지우기. 없으면 새로 만든다.
  final NoticeWatcher? watcher;

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  /// 화면에 보이는 분류 칩. 학과·행사는 실제 게시판이 없어 숨겨 둔다.
  static const _visibleTags = [NoticeTag.academic, NoticeTag.scholarship];

  final _notifications = NotificationService.instance;
  final _readStorage = NoticeReadStorage();
  late final NoticeServiceBase _service =
      widget.service ?? ServiceFactory.notice();
  late final NoticeWatcher _watcher =
      widget.watcher ?? NoticeWatcher(service: _service);

  List<NoticeItem> _notices = const [];
  bool _loading = true;

  /// 불러오지 못한 게시판 이름들(예: "학사공지"). 비어 있으면 모두 성공.
  List<String> _failedBoards = const [];

  /// null이면 "전체".
  NoticeTag? _filter;
  bool _notifyEnabled = false;
  final Set<String> _bookmarked = {};
  final Set<String> _read = {};

  @override
  void initState() {
    super.initState();
    _loadRead();
    _loadNotices();
    _loadNotifySetting();
    _watcher.clearPending();
  }

  /// 두 게시판을 동시에 받아 최신순으로 합친다. 한쪽이 실패해도 다른 쪽은 보여준다.
  Future<void> _loadNotices({bool forceRefresh = false}) async {
    final results = await Future.wait([
      for (final board in NoticeBoard.values)
        _service
            .fetchNotices(board, forceRefresh: forceRefresh)
            .then<List<NoticeItem>?>((items) => items)
            .catchError((Object _) => null),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failedBoards = [
        for (var i = 0; i < NoticeBoard.values.length; i++)
          if (results[i] == null)
            switch (NoticeBoard.values[i]) {
              NoticeBoard.academic => '학사공지',
              NoticeBoard.mileage => '마일리지장학 공지',
            },
      ];
      // 날짜가 "2026.10.29" 형식이라 문자열 비교가 곧 날짜 비교다.
      _notices = [for (final items in results) ...?items]
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  Future<void> _loadNotifySetting() async {
    final enabled = await _watcher.isEnabled();
    if (!mounted) return;
    setState(() => _notifyEnabled = enabled);
  }

  Future<void> _loadRead() async {
    final read = await _readStorage.load();
    if (!mounted) return;
    setState(() => _read.addAll(read));
  }

  void _markRead(NoticeItem notice) {
    if (!_read.add(notice.key)) return;
    setState(() {});
    _readStorage.save(_read);
  }

  bool _isUnread(NoticeItem n) => n.isNew && !_read.contains(n.key);

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null
        ? _notices
        : _notices.where((n) => n.tag == _filter).toList();
    // 북마크한 공지를 맨 위로(각 묶음 안의 순서는 최신순 그대로).
    final notices = [
      ...filtered.where((n) => _bookmarked.contains(n.key)),
      ...filtered.where((n) => !_bookmarked.contains(n.key)),
    ];
    final newCount = _notices.where(_isUnread).length;

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Pressable.icon(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.cobaltDeep,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lime,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.campaign,
                                    size: 14,
                                    color: AppColors.ink,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '새 글 $newCount개',
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 시안에는 없지만 기존 "새 글 알림 받기" 기능을 남긴
                            // 작은 종 버튼.
                            // 켜는 순간 종이 흔들리며 울린다.
                            Pressable.icon(
                              onTap: () => _onNotifyToggled(!_notifyEnabled),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: AppColors.cobaltDeep,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: RingingBell(
                                    active: _notifyEnabled,
                                    size: 16,
                                    activeColor: Colors.white,
                                    inactiveColor: Colors.white.withValues(
                                      alpha: 0.6,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '놓치면 안 되는 공지',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.04,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: MascotSticker(width: 76, angle: 0.08),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: '전체',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final tag in _visibleTags) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: tag.label,
                      selected: _filter == tag,
                      onTap: () => setState(() => _filter = tag),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadNotices(forceRefresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        children: [
                          if (_failedBoards.isNotEmpty)
                            _LoadErrorCard(
                              boards: _failedBoards,
                              onRetry: () {
                                setState(() => _loading = true);
                                _loadNotices(forceRefresh: true);
                              },
                            ),
                          for (final notice in notices) ...[
                            NoticeListCard(
                              notice: notice,
                              bookmarked: _bookmarked.contains(notice.key),
                              unread: _isUnread(notice),
                              detailService: _service,
                              onBookmarkTap: () => setState(() {
                                if (!_bookmarked.remove(notice.key)) {
                                  _bookmarked.add(notice.key);
                                }
                              }),
                              onOpened: () => _markRead(notice),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onNotifyToggled(bool turnOn) async {
    // 안내는 화면 아래 SnackBar 대신 맨 위에서 내려오는 배너로 보여준다.
    if (!turnOn) {
      setState(() => _notifyEnabled = false);
      showTopBanner(
        context,
        icon: Icons.notifications_off_rounded,
        title: '새 공지 알림을 껐어요',
        message: '다시 켜려면 종 버튼을 눌러주세요.',
      );
      await _watcher.setEnabled(false);
      return;
    }

    final granted = await _notifications.requestPermission();
    if (!mounted) return;
    if (!granted) {
      showTopBanner(
        context,
        icon: Icons.notifications_paused_rounded,
        title: '알림 권한이 꺼져 있어요',
        message: '설정에서 알림 권한을 허용해주세요.',
      );
      return;
    }

    setState(() => _notifyEnabled = true);
    showTopBanner(
      context,
      icon: Icons.notifications_active_rounded,
      title: '새 공지 알림을 켰어요',
      message: '앱을 열 때 새 공지가 있으면 알려드릴게요.',
    );
    await _watcher.setEnabled(true);
  }
}

/// 게시판을 불러오지 못했을 때 목록 위에 띄우는 안내.
class _LoadErrorCard extends StatelessWidget {
  const _LoadErrorCard({required this.boards, required this.onRetry});

  final List<String> boards;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${boards.join(', ')}를 불러오지 못했어요',
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              '다시 시도',
              style: TextStyle(
                color: AppColors.cobalt,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.lime : AppColors.cobaltDeep,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.ink : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
