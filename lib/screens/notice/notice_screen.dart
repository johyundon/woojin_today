import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/notice_service.dart';
import '../../services/notice_watcher.dart';
import '../../services/notification_service.dart';
import '../../services/service_factory.dart';
import '../../services/session_cache.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import '../calendar/widgets/ringing_bell.dart';
import '../../widgets/mascot_sticker.dart';
import 'models/notice_item.dart';
import 'services/notice_body_cache.dart';
import 'services/notice_read_storage.dart';
import 'widgets/notice_list_card.dart';

/// "공지사항" 화면("놓치면 안 되는 공지" v7 디자인). 전체/학사/장학/학과/행사
/// 칩으로 거르고, 카드의 북마크로 중요한 공지를 표시해 둘 수 있다(북마크는
/// 저장하지 않고 화면이 열려 있는 동안만 유지된다).
///
/// 학사공지·마일리지장학 공지·종합강의시간표 공지를 학교 홈페이지에서 받아
/// 보여준다. 종합강의시간표 공지는 로그인한 사람만 볼 수 있어서 로그인 때
/// 홈페이지가 준 쿠키([SessionCache.homepageCookie])가 있을 때만 불러오고, 따로 "시간표" 칩으로도 모아 볼 수 있다
/// (로그인했을 때만 칩이 보인다)([NoticeService],
/// 1시간 캐시, 당겨서 새로고침). 실제 게시판이 없는 학과·행사 탭과 목업 공지
/// ([NoticeMockData](services/notice_mock_data.dart))는 코드를 남겨 두고 화면에서만
/// 숨겼다([_visibleTags]).
///
/// "새 글 알림 받기" 토글(작은 종 버튼)은 기기에 저장된다. 켜 두면 앱을 열거나
/// 다시 돌아올 때, 그리고 앱이 꺼져 있을 때도 몇 시간마다 새 공지가 있으면 알림을
/// 띄운다([NoticeWatcher]). 켤 때 알림 권한을 묻고, 기본은 꺼짐이다.
/// 이 화면을 열면 홈 종 아이콘의 "새 공지" 점을 지운다.
class NoticeScreen extends StatefulWidget {
  const NoticeScreen({this.service, this.watcher, this.loginCookie, super.key});

  /// 로그인 때 홈페이지가 준 쿠키. 없으면 [SessionCache.homepageCookie]를 쓴다
  /// (테스트에서 직접 넣는다). 있어야 종합강의시간표 공지를 읽을 수 있다.
  final String? loginCookie;

  /// 테스트용 주입 지점.
  final NoticeServiceBase? service;

  /// 알림 켜짐 저장·새 공지 표시 지우기. 없으면 새로 만든다.
  final NoticeWatcher? watcher;

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  /// 화면에 보이는 분류 칩. 학과·행사는 실제 게시판이 없어 숨겨 둔다. 시간표는
  /// 로그인해야 읽을 수 있어서, 로그인하지 않았으면 빈 칩이 되지 않게 숨긴다.
  late final List<NoticeTag> _visibleTags = [
    NoticeTag.academic,
    NoticeTag.scholarship,
    if (_loginCookie != null) NoticeTag.timetable,
  ];

  final _notifications = NotificationService.instance;
  final _readStorage = NoticeReadStorage();
  late final String? _loginCookie =
      widget.loginCookie ?? SessionCache.homepageCookie;

  late final NoticeServiceBase _service =
      widget.service ?? ServiceFactory.notice(loginCookie: _loginCookie);

  /// 이번에 불러올 게시판. 로그인 정보가 없으면 로그인이 필요한 게시판은
  /// 오류 없이 건너뛴다.
  late final List<NoticeBoard> _boards = [
    for (final board in NoticeBoard.values)
      if (!board.requiresLogin || _loginCookie != null) board,
  ];
  late final NoticeWatcher _watcher =
      widget.watcher ?? NoticeWatcher(service: _service);

  List<NoticeItem> _notices = const [];
  bool _loading = true;

  /// 불러오지 못한 게시판 이름들(예: "학사공지"). 비어 있으면 모두 성공.
  List<String> _failedBoards = const [];

  /// 검색어(앞뒤 공백 제거). 비어 있으면 검색하지 않는다.
  final _searchController = TextEditingController();
  String _query = '';

  /// 검색용 본문 저장소. 처음 검색할 때 목록 공지의 본문을 받아 둔다.
  late final NoticeBodyCache _bodyCache = NoticeBodyCache(_service);
  bool _bodiesLoading = false;
  bool _bodiesRequested = false;

  /// null이면 "전체".
  NoticeTag? _filter;
  bool _notifyEnabled = false;
  final Set<String> _bookmarked = {};
  final Set<String> _read = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value.trim());
    if (_query.isNotEmpty) _loadBodies();
  }

  /// 처음 검색할 때 한 번, 목록 공지의 본문을 받아 둔다(저장된 건 다시 받지
  /// 않는다). 새로고침으로 목록이 바뀌면 다음 검색 때 새 공지만 더 받는다.
  Future<void> _loadBodies() async {
    if (_bodiesLoading) return;
    final paths = [
      for (final n in _notices)
        if (n.detailPath case final path?)
          if (!_bodyCache.bodies.containsKey(path)) path,
    ];
    if (paths.isEmpty && _bodiesRequested) return;
    _bodiesRequested = true;
    setState(() => _bodiesLoading = true);
    await _bodyCache.load(
      paths,
      onProgress: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) setState(() => _bodiesLoading = false);
  }

  /// 검색어가 제목에 있으면 빈 문자열(본문 한 줄 없이 보여줌), 본문에만 있으면
  /// 본문 한 줄, 둘 다 없으면 null.
  String? _match(NoticeItem n) {
    final q = _query.toLowerCase();
    if (n.title.toLowerCase().contains(q)) return '';
    final body = n.detailPath == null ? null : _bodyCache.bodies[n.detailPath];
    return body == null ? null : noticeSnippet(body, _query);
  }

  @override
  void initState() {
    super.initState();
    _loadRead();
    _loadNotices();
    _loadNotifySetting();
    _watcher.clearPending();
  }

  /// 게시판들을 동시에 받아 최신순으로 합친다. 하나가 실패해도 나머지는 보여준다.
  Future<void> _loadNotices({bool forceRefresh = false}) async {
    var loginExpired = false;
    final results = await Future.wait([
      for (final board in _boards)
        _service
            .fetchNotices(board, forceRefresh: forceRefresh)
            .then<List<NoticeItem>?>((items) => items)
            .catchError((Object e) {
              if (e is NoticeLoginRequiredException) loginExpired = true;
              return null;
            }),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failedBoards = [
        for (var i = 0; i < _boards.length; i++)
          if (results[i] == null)
            switch (_boards[i]) {
              NoticeBoard.academic => '학사공지',
              NoticeBoard.mileage => '마일리지장학 공지',
              NoticeBoard.timetable =>
                loginExpired ? '종합강의시간표 공지(다시 로그인 필요)' : '종합강의시간표 공지',
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
    final byTag = _filter == null
        ? _notices
        : _notices.where((n) => n.tag == _filter).toList();
    // 검색 중이면 제목·본문에 검색어가 있는 공지만 남기고, 본문에서만 찾은
    // 공지는 그 문장을 카드에 함께 보여준다.
    final matches = <String, String>{};
    final filtered = <NoticeItem>[];
    for (final n in byTag) {
      if (_query.isEmpty) {
        filtered.add(n);
        continue;
      }
      final m = _match(n);
      if (m == null) continue;
      filtered.add(n);
      if (m.isNotEmpty) matches[n.key] = m;
    }
    // 북마크한 공지를 맨 위로(각 묶음 안의 순서는 최신순 그대로).
    final notices = [
      ...filtered.where((n) => _bookmarked.contains(n.key)),
      ...filtered.where((n) => !_bookmarked.contains(n.key)),
    ];
    final newCount = _notices.where(_isUnread).length;

    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                newCount: newCount,
                notifyEnabled: _notifyEnabled,
                onNotifyTap: () => _onNotifyToggled(!_notifyEnabled),
              ),
              const SizedBox(height: 16),
              _SearchField(
                controller: _searchController,
                onChanged: _onQueryChanged,
                onClear: () {
                  _searchController.clear();
                  _onQueryChanged('');
                },
              ),
              const SizedBox(height: 14),
              // 칩 그림자가 위아래로 잘리지 않게 자르지 않는다.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _FilterChip(
                      label: '전체',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final tag in _visibleTags) ...[
                      const SizedBox(width: 6),
                      _FilterChip(
                        label: tag.label,
                        selected: _filter == tag,
                        onTap: () => setState(() => _filter = tag),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.blue),
                      )
                    : RefreshIndicator(
                        color: AppColors.blue,
                        backgroundColor: Colors.white,
                        onRefresh: () => _loadNotices(forceRefresh: true),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            18,
                            12,
                            18,
                            24 + MediaQuery.paddingOf(context).bottom,
                          ),
                          children: [
                            if (_failedBoards.isNotEmpty)
                              _LoadErrorCard(
                                boards: _failedBoards,
                                onRetry: () {
                                  setState(() => _loading = true);
                                  _loadNotices(forceRefresh: true);
                                },
                              ),
                            if (_query.isNotEmpty)
                              _SearchStatus(
                                query: _query,
                                count: notices.length,
                                searchingBodies: _bodiesLoading,
                              ),
                            for (final notice in notices) ...[
                              NoticeListCard(
                                matchSnippet: matches[notice.key],
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
      message: '새 공지가 올라오면 알려드릴게요.',
    );
    await _watcher.setEnabled(true);
  }
}

/// 헤더: 흰 네모 뒤로가기, "새 글 N개" 배지 + 알림 종 버튼, 큰 제목, 오른쪽 위
/// 마스코트 스티커.
class _Header extends StatelessWidget {
  const _Header({
    required this.newCount,
    required this.notifyEnabled,
    required this.onNotifyTap,
  });

  final int newCount;
  final bool notifyEnabled;
  final VoidCallback onNotifyTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          right: 14,
          top: -5,
          child: IgnorePointer(child: MascotSticker(width: 86, angle: 0.14)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Pressable.icon(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.textStrong,
                    size: 15,
                    semanticLabel: '뒤로',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.campaign_rounded,
                          size: 14,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '새 글 $newCount개',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // 시안에는 없지만 기존 "새 글 알림 받기" 기능을 남긴 작은 종
                  // 버튼. 켜는 순간 종이 흔들리며 울린다.
                  Pressable.icon(
                    onTap: onNotifyTap,
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Center(
                        child: RingingBell(
                          active: notifyEnabled,
                          size: 16,
                          activeColor: AppColors.blue,
                          inactiveColor: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Padding(
                // 오른쪽 마스코트와 겹치지 않게 비워 둔다.
                padding: EdgeInsets.only(right: 80),
                child: Text(
                  '놓치면 안 되는 공지',
                  style: TextStyle(
                    color: AppColors.textStrong,
                    fontSize: 26,
                    height: 1.4,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.91,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${boards.join(', ')}를 불러오지 못했어요',
              style: const TextStyle(
                color: AppColors.textStrong,
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
                color: AppColors.blue,
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected ? null : AppColors.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.blue : AppColors.textStrong,
            fontSize: 13,
            height: 1.4,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// 목록 위 검색창(학과 변경 화면의 검색창과 같은 모양). 제목과 본문을 함께 찾는다.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            cursorColor: AppColors.blue,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 8),
                child: Icon(
                  Icons.search_rounded,
                  size: 19,
                  color: AppColors.textMuted,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: value.text.isEmpty
                  ? null
                  : Pressable.icon(
                      onTap: onClear,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(
                          Icons.cancel_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(),
              hintText: '제목·본문으로 공지 검색',
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

/// 검색 중 목록 맨 위 한 줄: 결과 수, 본문을 받는 중이면 그 표시, 결과가
/// 없으면 안내.
class _SearchStatus extends StatelessWidget {
  const _SearchStatus({
    required this.query,
    required this.count,
    required this.searchingBodies,
  });

  final String query;
  final int count;
  final bool searchingBodies;

  @override
  Widget build(BuildContext context) {
    final text = count == 0 && !searchingBodies
        ? "'$query'와 맞는 공지가 없어요"
        : "'$query' 검색 결과 $count건";
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textBody,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (searchingBodies) ...[
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '본문 확인 중',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
