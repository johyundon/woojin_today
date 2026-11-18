import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'home/widgets/home_bottom_nav.dart';
import 'home/widgets/home_notice_banner.dart';
import 'home/widgets/home_top_icon_button.dart';
import 'home_placeholder_screen.dart';
import 'search/app_features.dart';
import 'search/feature_usage_store.dart';
import 'search/search_screen.dart';
import '../widgets/pressable.dart';

/// "모아보기" 화면 (Figma "04 모아보기", node 2140:2).
///
/// 홈 화면의 "모아보기" 탭에서 진입한다. 위에서부터 "자주 찾는 메뉴" 가로 카드
/// 3장(모아보기·검색에서 많이 연 기능 순, 기록이 없으면 시간표·학식·캘린더)과 "모든 메뉴" 목록 카드를 세로로 스크롤해서 보여준다.
/// 시안에 없는 찾기 버튼·공지 배너·"캠퍼스 · 도구" 아이콘 칸은 지우지 않고
/// 숨겨 두었고, 도구 4개는 "모든 메뉴" 목록 아래쪽 줄로 옮겼다. 구현되지 않은 항목이 생기면
/// [HomePlaceholderScreen]으로 이동한다.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({this.userId2, this.onTabTap, super.key});

  /// 하단 탭 바의 시간표/캘린더/MY 탭 동작. 홈 화면이 쓰는 핸들러를 그대로
  /// 받는다(MY 메뉴가 홈의 학생 정보 상태에 의존하기 때문). 홈(2) 탭은 이
  /// 화면을 닫고 홈으로 돌아가는 것으로 여기서 직접 처리한다.
  final ValueChanged<int>? onTabTap;

  /// 포털 로그인으로 얻은 본인 SSO uid. "지도교수 상담" 카드가 지도교수
  /// 조회에 써야 해서 홈 화면에서 그대로 전달받는다.
  final String? userId2;

  /// 기능 화면을 여는 데 필요한 값. 여는 동작은 검색 화면과 같은 [AppFeatures]를 쓴다.
  FeatureLinks get _links => FeatureLinks(userId2: userId2, onTabTap: onTabTap);

  void Function(BuildContext context) _opener(AppFeature feature) =>
      (context) => feature.openAndRecord(context, _links);

  /// 시안에 없어 숨긴 요소. 다시 보이려면 true로 바꾼다.
  static const _showSearchButton = false;
  static const _showNoticeBanner = false;
  static const _showToolGrid = false;

  /// "자주 찾는 메뉴" 기본 카드(기록이 없을 때, 횟수가 같을 때 앞에 온다).
  List<_DailyItem> get _dailyItems => [
    _DailyItem(
      feature: AppFeatures.timetable,
      button: '바로가기',
      headerColor: _CollectionColors.blueHeader,
      iconColor: _CollectionColors.blueIcon,
      onTap: _opener(AppFeatures.timetable),
    ),
    _DailyItem(
      feature: AppFeatures.cafeteria,
      button: '바로가기',
      headerColor: _CollectionColors.greenHeader,
      iconColor: _CollectionColors.greenIcon,
      onTap: _opener(AppFeatures.cafeteria),
    ),
    _DailyItem(
      feature: AppFeatures.calendar,
      button: '바로가기',
      headerColor: _CollectionColors.orangeHeader,
      iconColor: _CollectionColors.orangeIcon,
      onTap: _opener(AppFeatures.calendar),
    ),
  ];

  /// "자주 찾는 메뉴" 후보: 기본 3장 + "모든 메뉴" 목록 기능을 카드 모양으로.
  List<_DailyItem> get _frequentCandidates => [
    ..._dailyItems,
    for (final item in _schoolItems)
      _DailyItem(
        feature: item.feature,
        button: '바로가기',
        headerColor: _CollectionColors.headerFor(item.iconColor),
        iconColor: item.iconColor,
        onTap: item.onTap,
      ),
  ];

  /// "모든 메뉴" 목록. 아래 네 줄은 예전 "캠퍼스 · 도구" 칸에서 옮겨 왔다.
  List<_ListItem> get _schoolItems => [
    _ListItem(
      feature: AppFeatures.notice,
      boxColor: _CollectionColors.blueBox,
      iconColor: _CollectionColors.blueIcon,
      onTap: _opener(AppFeatures.notice),
    ),
    _ListItem(
      feature: AppFeatures.departmentRank,
      boxColor: _CollectionColors.greenBox,
      iconColor: _CollectionColors.greenIcon,
      onTap: _opener(AppFeatures.departmentRank),
    ),
    _ListItem(
      feature: AppFeatures.graduationCredit,
      boxColor: _CollectionColors.purpleBox,
      iconColor: _CollectionColors.purpleIcon,
      onTap: _opener(AppFeatures.graduationCredit),
    ),
    _ListItem(
      feature: AppFeatures.mileage,
      boxColor: _CollectionColors.orangeBox,
      iconColor: _CollectionColors.orangeIcon,
      onTap: _opener(AppFeatures.mileage),
    ),
    // "연강"은 캠퍼스 지도와 같은 화면을 열어 중복이라 목록에서 뺐다
    // (정의는 [AppFeatures.consecutiveClasses]에 남겨 둠).
    _ListItem(
      feature: AppFeatures.weather,
      boxColor: _CollectionColors.orangeBox,
      iconColor: _CollectionColors.orangeIcon,
      onTap: _opener(AppFeatures.weather),
    ),
    _ListItem(
      feature: AppFeatures.campusMap,
      boxColor: _CollectionColors.greenBox,
      iconColor: _CollectionColors.greenIcon,
      onTap: _opener(AppFeatures.campusMap),
    ),
    _ListItem(
      feature: AppFeatures.fileShare,
      boxColor: _CollectionColors.blueBox,
      iconColor: _CollectionColors.blueIcon,
      onTap: _opener(AppFeatures.fileShare),
    ),
    _ListItem(
      feature: AppFeatures.advisor,
      boxColor: _CollectionColors.purpleBox,
      iconColor: _CollectionColors.purpleIcon,
      onTap: _opener(AppFeatures.advisor),
    ),
  ];

  /// "캠퍼스 · 도구" 아이콘 칸(숨김, [_showToolGrid]).
  List<_ToolItem> get _toolItems => [
    _ToolItem(
      feature: AppFeatures.weather,
      onTap: _opener(AppFeatures.weather),
    ),
    _ToolItem(
      feature: AppFeatures.campusMap,
      onTap: _opener(AppFeatures.campusMap),
    ),
    _ToolItem(
      feature: AppFeatures.fileShare,
      onTap: _opener(AppFeatures.fileShare),
    ),
    _ToolItem(
      feature: AppFeatures.advisor,
      onTap: _opener(AppFeatures.advisor),
    ),
  ];

  /// 통합 검색 화면. 홈의 돋보기와 같은 화면을 같은 값으로 연다.
  void _openSearch(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => SearchScreen(links: _links)));
  }

  void _openPlaceholder(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const HomePlaceholderScreen()));
  }

  /// [onTap]이 null인(아직 구현되지 않은) 항목은 준비 중 화면으로 보낸다.
  VoidCallback _handler(
    BuildContext context,
    void Function(BuildContext context)? onTap,
  ) =>
      () => (onTap ?? _openPlaceholder)(context);

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
    final bottomInset = 120 + MediaQuery.of(context).padding.bottom;
    final school = _schoolItems;
    // 흰 바탕이라 상태 표시줄 글자(시계·배터리)를 어둡게 그린다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        extendBody: true,
        bottomNavigationBar: HomeBottomNav(
          selectedIndex: 1,
          onTap: (i) => _onTabTap(context, i),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 22, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '모아보기',
                          style: TextStyle(
                            color: AppColors.textStrong,
                            fontSize: 17,
                            height: 1.4,
                            letterSpacing: -0.34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // 예전 시안의 찾기 버튼. 홈 위쪽 검색 버튼과 같다(숨김).
                      if (_showSearchButton)
                        HomeV7IconButton(
                          asset: HomeV7IconButton.searchAsset,
                          semanticLabel: '검색',
                          onTap: () => _openSearch(context),
                        ),
                    ],
                  ),
                ),
                if (_showNoticeBanner)
                  HomeNoticeBanner(
                    onOpenCalendar: () => _onTabTap(context, 3),
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 2),
                  ),
                const SizedBox(height: 35),
                const _SectionHeading(
                  title: '자주 찾는 메뉴',
                  padding: EdgeInsets.symmetric(horizontal: 22),
                ),
                const SizedBox(height: 22),
                _FrequentCards(
                  candidates: _frequentCandidates,
                  onTapOf: (item) => _handler(context, item.onTap),
                ),
                const SizedBox(height: 32),
                const _SectionHeading(
                  title: '모든 메뉴',
                  padding: EdgeInsets.symmetric(horizontal: 18),
                ),
                const SizedBox(height: 11),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    children: [
                      for (final (i, item) in school.indexed)
                        _ListRow(
                          item: item,
                          showDivider: i < school.length - 1,
                          onTap: _handler(context, item.onTap),
                        ),
                    ],
                  ),
                ),
                if (_showToolGrid) ...[
                  const SizedBox(height: 38),
                  const _SectionHeading(title: '캠퍼스 · 도구'),
                  const SizedBox(height: 14),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 18),
                    padding: const EdgeInsets.fromLTRB(8, 18, 8, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final item in _toolItems)
                          Expanded(
                            child: _ToolCell(
                              item: item,
                              onTap: _handler(context, item.onTap),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 모아보기 화면에만 쓰는 색. 공통 팔레트(AppColors)에 없는 값만 모았고, 디자인
/// 요소 트리(14_collection)의 oklch 값을 sRGB로 바꿔 옮겼다.
class _CollectionColors {
  _CollectionColors._();

  // "매일 쓰는 기능" 카드 윗부분 색.
  static const Color blueHeader = Color(0xFF5376EA);
  static const Color greenHeader = Color(0xFF4BC680);
  static const Color orangeHeader = Color(0xFFF39E4C);

  // 아이콘 색.
  static const Color blueIcon = Color(0xFF315DD4);
  static const Color greenIcon = Color(0xFF00793D);
  static const Color orangeIcon = Color(0xFFD4771A);
  static const Color purpleIcon = Color(0xFF5D4DBE);

  // 목록 아이콘 상자 바탕.
  static const Color blueBox = Color(0xFFDEEBFF);
  static const Color greenBox = Color(0xFFD2F6DD);
  static const Color purpleBox = Color(0xFFE8E8FF);
  static const Color orangeBox = Color(0xFFFFEED6);

  /// 졸업학점·상담 예약이 "자주 찾는 메뉴" 카드로 올라올 때의 윗부분 색.
  /// 시안에 보라 카드가 없어 보라 아이콘 색을 파랑·초록 카드와 같은 정도로
  /// 밝게 맞춘 값이다.
  static const Color purpleHeader = Color(0xFF7A6BDB);

  /// 아이콘 색에 맞는 카드 윗부분 색.
  static Color headerFor(Color iconColor) => switch (iconColor) {
    greenIcon => greenHeader,
    orangeIcon => orangeHeader,
    purpleIcon => purpleHeader,
    _ => blueHeader,
  };

  /// 목록 줄 사이 구분선.
  static const Color divider = Color(0xFFE8EAEE);
}

/// 남색 굵은 글자 한 줄로 된 구역 머리말.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
  });

  final String title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.inkNavy,
          fontSize: 17,
          height: 1.4,
          letterSpacing: -0.34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// "자주 찾는 메뉴" 가로 카드 줄. 연 횟수 기록을 읽어 [candidates] 중 많이 연
/// 3개를 보여 주고, 기록이 바뀌면([FeatureUsageStore.changes]) 다시 고른다.
class _FrequentCards extends StatefulWidget {
  const _FrequentCards({required this.candidates, required this.onTapOf});

  final List<_DailyItem> candidates;
  final VoidCallback Function(_DailyItem item) onTapOf;

  @override
  State<_FrequentCards> createState() => _FrequentCardsState();
}

class _FrequentCardsState extends State<_FrequentCards> {
  Map<String, int> _counts = const {};

  @override
  void initState() {
    super.initState();
    _load();
    FeatureUsageStore.changes.addListener(_load);
  }

  @override
  void dispose() {
    FeatureUsageStore.changes.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final counts = await const FeatureUsageStore().load();
    if (mounted) setState(() => _counts = counts);
  }

  @override
  Widget build(BuildContext context) {
    final items = pickFrequent(widget.candidates, (i) => i.label, _counts);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      // 카드 그림자가 잘리지 않도록 위아래로 여유를 둔다.
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 12),
            _DailyCard(item: item, onTap: widget.onTapOf(item)),
          ],
        ],
      ),
    );
  }
}

class _DailyItem {
  const _DailyItem({
    required this.feature,
    required this.button,
    required this.headerColor,
    required this.iconColor,
    this.onTap,
  });

  final AppFeature feature;
  String get label => feature.label;
  String get description => feature.description;
  IconData get icon => feature.icon;
  final String button;
  final Color headerColor;
  final Color iconColor;
  final void Function(BuildContext context)? onTap;
}

/// "자주 찾는 메뉴" 카드 한 장(150x183). 색 띠 위에 흰 아이콘 상자가 걸쳐 있고,
/// 아래 흰 카드에 이름·설명·버튼 모양이 있다. 카드 전체가 눌린다.
class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.item, required this.onTap});

  final _DailyItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        height: 183,
        child: Stack(
          children: [
            Container(
              height: 104,
              decoration: BoxDecoration(
                color: item.headerColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
            ),
            Positioned(
              top: 52,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 16,
                        height: 1.4,
                        letterSpacing: -0.48,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textBody,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.blueSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        item.button,
                        style: const TextStyle(
                          color: AppColors.blueText,
                          fontSize: 14,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 49,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Icon(item.icon, color: item.iconColor, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListItem {
  const _ListItem({
    required this.feature,
    required this.boxColor,
    required this.iconColor,
    this.onTap,
  });

  final AppFeature feature;
  String get label => feature.label;
  String get description => feature.description;
  IconData get icon => feature.icon;
  final Color boxColor;
  final Color iconColor;
  final void Function(BuildContext context)? onTap;
}

/// "모든 메뉴" 목록 한 줄: 색 아이콘 상자 + 이름·설명 + 오른쪽 화살표.
class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.item,
    required this.showDivider,
    required this.onTap,
  });

  final _ListItem item;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: _CollectionColors.divider),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.boxColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 16,
                      height: 1.4,
                      letterSpacing: -0.32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textBody,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem({required this.feature, this.onTap});

  final AppFeature feature;
  String get label => feature.label;
  IconData get icon => feature.icon;
  final void Function(BuildContext context)? onTap;
}

/// "캠퍼스 · 도구" 아이콘 칸 하나.
class _ToolCell extends StatelessWidget {
  const _ToolCell({required this.item, required this.onTap});

  final _ToolItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.9,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.blueText, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textStrong,
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
