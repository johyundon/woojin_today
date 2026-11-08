import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/notice_service.dart';
import '../../services/service_factory.dart';
import '../../services/session_cache.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../campus_map/campus_map_screen.dart';
import '../campus_map/models/campus_building.dart';
import '../campus_map/models/room_building.dart';
import '../notice/models/notice_item.dart';
import '../notice/notice_detail_screen.dart';
import '../notice/services/notice_read_storage.dart';
import 'app_features.dart';
import 'widgets/search_result_row.dart';

/// 홈 위쪽 돋보기로 여는 통합 검색 화면.
///
/// 디자인 시안이 없어서, 학과 선택 화면의 검색창과 모아보기 화면의 목록 줄
/// 모양을 그대로 가져와 만들었다. 검색어가 없으면 찾을 수 있는 기능 전체를
/// 보여 준다.
///
/// 찾는 대상은 세 가지다.
/// - 기능: [AppFeatures] 목록(모아보기와 같음).
/// - 공지: 공지 화면과 같은 게시판의 최근 글 제목. 화면을 열 때 한 번만 불러오고
///   (1시간 안에 받은 적이 있으면 기기에 저장된 목록), 글자를 칠 때마다 다시
///   요청하지 않는다.
/// - 장소: 캠퍼스 지도의 건물·장소 이름과 줄임말([buildingsMatching]).
class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
    this.links = const FeatureLinks(),
    this.noticeService,
    this.loginCookie,
  });

  /// 기능 화면을 열 때 넘길 값(홈에서 받음).
  final FeatureLinks links;

  /// 공지를 불러올 서비스(테스트에서 가짜를 넘긴다).
  final NoticeServiceBase? noticeService;

  /// 로그인한 사람만 보는 게시판용 쿠키. 없으면 [SessionCache.homepageCookie].
  final String? loginCookie;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  /// 검색 결과로 보여 줄 공지 최대 개수.
  static const _maxNotices = 20;

  late final String? _loginCookie =
      widget.loginCookie ?? SessionCache.homepageCookie;
  late final NoticeServiceBase _noticeService =
      widget.noticeService ?? ServiceFactory.notice(loginCookie: _loginCookie);

  List<NoticeItem> _notices = const [];
  bool _noticesLoading = true;
  bool _noticesFailed = false;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  /// 공지 화면과 같은 게시판을 불러와 최신순으로 합친다. 하나가 실패해도
  /// 나머지는 쓰고, 로그인 정보가 없으면 로그인이 필요한 게시판은 건너뛴다.
  Future<void> _loadNotices() async {
    final boards = [
      for (final board in NoticeBoard.values)
        if (!board.requiresLogin || _loginCookie != null) board,
    ];
    final results = await Future.wait([
      for (final board in boards)
        _noticeService
            .fetchNotices(board)
            .then<List<NoticeItem>?>((items) => items)
            .catchError((Object _) => null),
    ]);
    if (!mounted) return;
    setState(() {
      _noticesLoading = false;
      _noticesFailed = results.every((r) => r == null);
      // 날짜가 "2026.10.29" 형식이라 문자열 비교가 곧 날짜 비교다.
      _notices = [for (final items in results) ...?items]
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  List<NoticeItem> _matchingNotices() {
    final q = normalizeSearchText(_query);
    return _notices
        .where((n) => normalizeSearchText(n.title).contains(q))
        .take(_maxNotices)
        .toList();
  }

  /// 공지 화면에서 연 것처럼 읽음으로 표시하고 상세를 연다.
  void _openNotice(NoticeItem notice) {
    _markRead(notice);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NoticeDetailScreen(notice: notice, service: _noticeService),
      ),
    );
  }

  Future<void> _markRead(NoticeItem notice) async {
    try {
      final storage = NoticeReadStorage();
      final read = await storage.load();
      if (read.add(notice.key)) await storage.save(read);
    } catch (_) {
      // 읽음 표시는 실패해도 공지를 여는 데는 지장이 없다.
    }
  }

  void _openPlace(CampusBuilding building) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CampusMapScreen(initialSelectedBuilding: building.name),
      ),
    );
  }

  /// "2026.11.02" → "11.02".
  static String _shortDate(String date) {
    final parts = date.split('.');
    return parts.length == 3 ? '${parts[1]}.${parts[2]}' : date;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openFeature(AppFeature feature) => feature.open(context, widget.links);

  @override
  Widget build(BuildContext context) {
    final searching = normalizeSearchText(_query).isNotEmpty;
    final features = searching
        ? AppFeatures.all.where((f) => f.matches(_query)).toList()
        : AppFeatures.all;
    final notices = searching ? _matchingNotices() : const <NoticeItem>[];
    final places = searching
        ? buildingsMatching(_query)
        : const <CampusBuilding>[];
    final nothingFound =
        searching &&
        features.isEmpty &&
        notices.isEmpty &&
        places.isEmpty &&
        !_noticesLoading;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                child: Row(
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
                    const SizedBox(width: 10),
                    Expanded(child: _searchField()),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    0,
                    18,
                    0,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    if (nothingFound)
                      _EmptyResult(query: _query.trim())
                    else ...[
                      if (!searching || features.isNotEmpty) ...[
                        SearchSectionHeading(
                          label: searching ? '기능' : '이런 걸 찾을 수 있어요',
                          count: searching ? features.length : null,
                        ),
                        const SizedBox(height: 10),
                        SearchResultCard(
                          children: [
                            for (final (i, f) in features.indexed)
                              SearchResultRow(
                                icon: f.icon,
                                title: f.label,
                                subtitle: f.description,
                                showDivider: i < features.length - 1,
                                onTap: () => _openFeature(f),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                      ],
                      if (searching) ...[
                        if (notices.isNotEmpty) ...[
                          SearchSectionHeading(
                            label: '공지',
                            count: notices.length,
                          ),
                          const SizedBox(height: 10),
                          SearchResultCard(
                            children: [
                              for (final (i, n) in notices.indexed)
                                SearchResultRow(
                                  icon: Icons.campaign_rounded,
                                  title: n.title,
                                  titleMaxLines: 2,
                                  subtitle:
                                      '${n.tag.label} · ${_shortDate(n.date)}'
                                      ' · ${n.author}',
                                  showDivider: i < notices.length - 1,
                                  onTap: () => _openNotice(n),
                                ),
                            ],
                          ),
                          const SizedBox(height: 26),
                        ] else if (_noticesLoading || _noticesFailed)
                          _NoticeStatus(loading: _noticesLoading),
                        if (places.isNotEmpty) ...[
                          SearchSectionHeading(
                            label: '장소',
                            count: places.length,
                          ),
                          const SizedBox(height: 10),
                          SearchResultCard(
                            children: [
                              for (final (i, b) in places.indexed)
                                SearchResultRow(
                                  icon: Icons.location_on_rounded,
                                  title: b.name,
                                  subtitle: '캠퍼스 지도에서 보기',
                                  showDivider: i < places.length - 1,
                                  onTap: () => _openPlace(b),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _query = v),
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
          suffixIcon: _query.isEmpty
              ? null
              : Pressable.icon(
                  onTap: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                      semanticLabel: '지우기',
                    ),
                  ),
                ),
          suffixIconConstraints: const BoxConstraints(),
          hintText: '기능, 공지, 건물 검색',
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
    );
  }
}

/// 검색 결과가 하나도 없을 때.
class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppColors.blue,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "'$query'에 맞는 결과가 없어요",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 16,
              height: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '다른 말로 검색해 보세요',
            style: TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// 공지를 아직 불러오는 중이거나, 불러오지 못했을 때 공지 자리에 보여 주는 한 줄.
class _NoticeStatus extends StatelessWidget {
  const _NoticeStatus({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 26),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.blue,
              ),
            )
          else
            const Icon(
              Icons.error_outline_rounded,
              size: 16,
              color: AppColors.textSub,
            ),
          const SizedBox(width: 8),
          Text(
            loading ? '공지를 불러오는 중이에요' : '공지를 불러오지 못해 공지는 찾지 못했어요',
            style: const TextStyle(
              color: AppColors.textSub,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
