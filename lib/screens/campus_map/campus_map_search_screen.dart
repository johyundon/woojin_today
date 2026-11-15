import 'package:flutter/material.dart';

import '../../services/class_schedule_parser.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../widgets/top_banner.dart';
import 'campus_map_colors.dart';
import 'models/campus_building.dart';
import 'models/route_classes.dart';
import 'models/room_building.dart';
import 'services/recent_place_store.dart';
import 'widgets/campus_map_top_bar.dart';
import 'widgets/campus_route_header.dart';

/// 검색 화면에서 고른 결과. [origin]이 있으면 "오늘 수업 길찾기"를 고른
/// 것이라 지도는 출발지 → 도착지 길을 그린다.
class CampusSearchResult {
  const CampusSearchResult({
    required this.destination,
    this.origin,
    this.classes,
    this.forOrigin = false,
  });

  /// 고른 건물. [origin]이 없으면 이 건물 하나만 고른 것이다.
  final CampusBuilding destination;
  final CampusBuilding? origin;

  /// 출발·도착 두 칸 검색([CampusMapSearchScreen.endpoints])에서 출발 칸에
  /// 넣으려고 고른 건물이면 true.
  final bool forOrigin;

  /// "오늘 수업 길찾기"로 고른 앞·뒤 수업.
  final RouteClasses? classes;
}

/// 캠퍼스 지도 위쪽 "어디 가?"를 누르면 열리는 검색 화면(시안 2번).
///
/// 글자가 비어 있으면 "오늘 수업 길찾기", "오늘 강의실", "최근 검색"을,
/// 글자를 치면 맞는 건물 목록을 보여 준다. 고르면 [CampusSearchResult]를
/// 돌려주며 닫힌다. 각 칸은 보여 줄 것이 없으면 통째로 숨긴다.
///
/// [endpoints]를 주면(길안내 화면에서 출발·도착 칸을 눌렀을 때) 위쪽이
/// 길안내 화면과 같은 출발·도착 두 칸으로 바뀌고, 고른 칸에 글자를 친다.
class CampusMapSearchScreen extends StatefulWidget {
  const CampusMapSearchScreen({
    super.key,
    required this.todayClasses,
    required this.now,
    this.recentStore = const RecentPlaceStore(),
    this.endpoints,
  });

  /// 길안내 화면에서 열었을 때의 출발·도착 칸 상태. null이면 기본 검색창.
  final CampusSearchEndpoints? endpoints;

  /// 오늘 수업(시작 시각 순). 시간표를 못 받았으면 빈 목록.
  final List<TodayClass> todayClasses;
  final DateTime now;
  final RecentPlaceStore recentStore;

  @override
  State<CampusMapSearchScreen> createState() => _CampusMapSearchScreenState();
}

/// 출발·도착 두 칸 검색의 처음 상태 — 지금 들어 있는 이름과, 어느 칸을
/// 눌러서 열었는지.
class CampusSearchEndpoints {
  const CampusSearchEndpoints({
    required this.originName,
    required this.destinationName,
    required this.editingOrigin,
  });

  final String? originName;
  final String? destinationName;
  final bool editingOrigin;
}

class _CampusMapSearchScreenState extends State<CampusMapSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  List<String> _recent = const [];

  /// 두 칸 검색에서 지금 글자를 치는 칸이 출발이면 true.
  late bool _editingOrigin = widget.endpoints?.editingOrigin ?? false;

  @override
  void initState() {
    super.initState();
    widget.recentStore.load().then((list) {
      if (mounted) setState(() => _recent = list);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _nowMinutes => widget.now.hour * 60 + widget.now.minute;

  /// "오늘 수업 길찾기"에 쓸 수업 두 개. 방금 끝난(또는 듣는 중인) 수업이
  /// 있으면 그 수업 → 다음 수업, 아직 첫 수업 전이면 첫 수업 → 둘째 수업.
  /// 남은 수업이 없거나 강의실 건물을 못 찾으면 null(카드를 숨긴다).
  ({TodayClass from, TodayClass to, CampusBuilding a, CampusBuilding b})?
  get _nextHop {
    final classes = widget.todayClasses;
    final nextIndex = classes.indexWhere(
      (c) => c.slot.startMinutes > _nowMinutes,
    );
    if (nextIndex < 0) return null;
    final fromIndex = nextIndex == 0 ? 0 : nextIndex - 1;
    if (fromIndex + 1 >= classes.length) return null;
    final from = classes[fromIndex];
    final to = classes[fromIndex + 1];
    final a = buildingForRoom(roomForSlot(from));
    final b = buildingForRoom(roomForSlot(to));
    if (a == null || b == null) return null;
    return (from: from, to: to, a: a, b: b);
  }

  Future<void> _pick(
    CampusBuilding building, {
    CampusBuilding? origin,
    RouteClasses? classes,
  }) async {
    if (origin == null) await widget.recentStore.add(building.name);
    if (!mounted) return;
    Navigator.of(context).pop(
      CampusSearchResult(
        destination: building,
        origin: origin,
        classes: classes,
        forOrigin: origin == null && _editingOrigin,
      ),
    );
  }

  void _pickRoom(String room) {
    final building = buildingForRoom(room);
    if (building == null) {
      showTopBanner(
        context,
        title: '건물을 찾지 못했어요',
        message: '"$room" 강의실이 지도의 어느 건물인지 아직 몰라요.',
        icon: Icons.help_outline_rounded,
      );
      return;
    }
    _pick(building);
  }

  Future<void> _removeRecent(String name) async {
    final list = await widget.recentStore.remove(name);
    if (mounted) setState(() => _recent = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CampusMapColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            if (widget.endpoints case final endpoints?)
              _endpointsHeader(endpoints)
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 16, 8),
                child: Row(
                  children: [
                    Pressable.icon(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 44,
                        height: 52,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textStrong,
                          size: 20,
                          semanticLabel: '뒤로',
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: _searchField()),
                  ],
                ),
              ),
            Expanded(child: _query.isEmpty ? _suggestions() : _results()),
          ],
        ),
      ),
    );
  }

  /// 길안내 화면과 같은 위쪽 카드 — "‹ 캠퍼스 지도", 출발·도착 두 칸.
  /// 고른 칸은 테두리가 생기고 글자를 받는다. 다른 칸을 누르면 그 칸으로
  /// 바꾼다.
  Widget _endpointsHeader(CampusSearchEndpoints endpoints) {
    Widget field({
      required bool origin,
      required String? name,
      required Widget icon,
    }) {
      final editing = origin == _editingOrigin;
      final box = Container(
        height: 40,
        padding: const EdgeInsets.only(left: 8, right: 4),
        decoration: BoxDecoration(
          color: editing ? CampusMapColors.surface : AppColors.fill,
          borderRadius: BorderRadius.circular(10),
          border: editing
              ? Border.all(color: AppColors.textStrong, width: 1)
              : null,
        ),
        child: Row(
          children: [
            SizedBox(width: 24, child: Center(child: icon)),
            const SizedBox(width: 8),
            Expanded(
              child: editing
                  ? TextField(
                      key: ValueKey(origin),
                      controller: _controller,
                      autofocus: true,
                      textInputAction: TextInputAction.done,
                      onChanged: (v) => setState(() => _query = v.trim()),
                      style: const TextStyle(
                        color: AppColors.textStrong,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        hintText: name ?? CampusMapTopBar.searchHint,
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    )
                  : Text(
                      name ?? CampusMapTopBar.searchHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: name == null
                            ? AppColors.textMuted
                            : AppColors.textStrong,
                        fontSize: 14,
                        fontWeight: name == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
            ),
            if (editing && _query.isNotEmpty)
              Pressable.icon(
                onTap: () {
                  _controller.clear();
                  setState(() => _query = '');
                },
                child: const SizedBox(
                  width: 36,
                  height: 40,
                  child: Icon(
                    Icons.cancel_rounded,
                    color: AppColors.checkLine,
                    size: 18,
                    semanticLabel: '지우기',
                  ),
                ),
              ),
          ],
        ),
      );
      if (editing) return box;
      return Pressable(
        onTap: () {
          _controller.clear();
          setState(() {
            _query = '';
            _editingOrigin = origin;
          });
        },
        pressedScale: 0.98,
        child: box,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          CampusMapTitleRow(onBack: () => Navigator.of(context).pop()),
          const SizedBox(height: 10),
          Row(
            children: [
              // 길안내 화면의 바꾸기 버튼 자리. 여기선 칸을 눌러 바꾼다.
              const SizedBox(width: 36),
              Expanded(
                child: Column(
                  children: [
                    field(
                      origin: true,
                      name: endpoints.originName,
                      icon: const RouteOriginDot(),
                    ),
                    const SizedBox(height: 8),
                    field(
                      origin: false,
                      name: endpoints.destinationName,
                      icon: const RouteDestinationPin(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: CampusMapColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blue, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onChanged: (v) => setState(() => _query = v.trim()),
              style: const TextStyle(
                color: AppColors.textStrong,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: CampusMapTopBar.searchHint,
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
          Pressable.icon(
            onTap: () {
              _controller.clear();
              setState(() => _query = '');
            },
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(
                Icons.close_rounded,
                color: AppColors.textStrong,
                size: 22,
                semanticLabel: '지우기',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestions() {
    final hop = _nextHop;
    final recent = [
      for (final name in _recent)
        if (campusBuildings.any((b) => b.name == name)) name,
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        if (hop != null) ...[
          const _SectionTitle('오늘 수업 길찾기'),
          _NextHopCard(
            title:
                '${hop.from.course.courseName} → ${hop.to.course.courseName}',
            subtitle:
                '${roomForSlot(hop.from)} → ${roomForSlot(hop.to)} · 여유 '
                '${hop.to.slot.startMinutes - hop.from.slot.endMinutes}분',
            onTap: () => _pick(
              hop.b,
              origin: hop.a,
              classes: RouteClasses(from: hop.from, to: hop.to),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (widget.todayClasses.isNotEmpty) ...[
          const _SectionTitle('오늘 강의실'),
          for (final c in widget.todayClasses)
            _PlaceRow(
              title: roomForSlot(c),
              subtitle: c.slot.endMinutes <= _nowMinutes
                  ? '${c.course.courseName} · ${hhmm(c.slot.endMinutes)} 끝'
                  : '${c.course.courseName} · ${hhmm(c.slot.startMinutes)} 시작',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 26,
              ),
              onTap: () => _pickRoom(roomForSlot(c)),
            ),
          const SizedBox(height: 12),
        ],
        if (recent.isNotEmpty) ...[
          const _SectionTitle('최근 검색'),
          for (final name in recent)
            _PlaceRow(
              title: name,
              subtitle: '최근 검색',
              trailing: Pressable.icon(
                onTap: () => _removeRecent(name),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                    semanticLabel: '최근 검색에서 지우기',
                  ),
                ),
              ),
              onTap: () =>
                  _pick(campusBuildings.firstWhere((b) => b.name == name)),
            ),
        ],
        if (hop == null && widget.todayClasses.isEmpty && recent.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text(
                '건물 이름이나 강의실을 검색해 보세요',
                style: TextStyle(color: AppColors.textSub, fontSize: 15),
              ),
            ),
          ),
      ],
    );
  }

  Widget _results() {
    final matches = buildingsMatching(_query);
    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Align(
          alignment: Alignment.topCenter,
          child: Text(
            '찾는 건물이 없어요',
            style: TextStyle(color: AppColors.textSub, fontSize: 15),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        for (final b in matches)
          _PlaceRow(
            title: b.name,
            subtitle: '캠퍼스 건물',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 26,
            ),
            onTap: () => _pick(b),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSub,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 파란 "오늘 수업 길찾기" 카드.
class _NextHopCard extends StatelessWidget {
  const _NextHopCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.blueSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.blueSoftLine),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.blueText,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textBody,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.blue,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

/// 목록 한 줄(굵은 이름 + 회색 설명 + 오른쪽 아이콘, 아래 구분선).
class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.transparent,
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textStrong,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
