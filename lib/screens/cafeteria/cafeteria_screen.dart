import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/cafeteria_menu_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pressable.dart';
import '../../utils/wide_layout.dart';
import 'cafeteria_colors.dart';
import 'models/cafeteria_menu.dart';
import 'widgets/cafeteria_date_picker_dialog.dart';
import 'widgets/cafeteria_venue_tabs.dart';
import 'widgets/cafeteria_week_row.dart';
import 'widgets/small_menu_card.dart';

/// 학식 화면(디자인 "07 학식"). 위쪽에서 날짜(가로로 넘기는 칩, 오늘이 왼쪽 끝)와
/// 식당 탭(전체/학생식당/생활관식당/교직원식당)을 고르면, 그 날의 조식·중식·석식이
/// 구역별로 같은 크기의 카드로 두 칸씩 나온다.
///
/// 메뉴는 학교 사이트에서 받아 오며([CafeteriaMenuService]), 날짜가 바뀌면 그 날의
/// 메뉴를 다시 조회한다. 서버는 학생식당/교직원식당을 구분해 주지 않아 받은 메뉴는
/// 모두 학생식당으로 보여준다.
class CafeteriaScreen extends StatefulWidget {
  const CafeteriaScreen({this.now, this.service, super.key});

  /// 학식을 조회하는 서비스. 테스트에서 가짜로 바꿔 끼우려고 주입할 수 있다.
  final CafeteriaMenuServiceBase? service;

  /// "지금" 기준 시각(오늘 표시와 기본 끼니 고르기에 쓴다). 테스트에서 고정하려고
  /// 주입할 수 있다.
  final DateTime? now;

  @override
  State<CafeteriaScreen> createState() => _CafeteriaScreenState();
}

class _CafeteriaScreenState extends State<CafeteriaScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();
  late DateTime _selectedDate = _dateOnly(_now);

  /// 고른 식당 탭. null이면 "전체".
  CafeteriaVenue? _venue;
  late CafeteriaMeal _meal = _defaultMeal();

  late final CafeteriaMenuServiceBase _service =
      widget.service ?? ServiceFactory.cafeteriaMenu();

  DailyCafeteriaMenu? _menu;
  bool _loading = true;
  bool _loadFailed = false;

  /// 날짜를 빠르게 바꿨을 때 늦게 도착한 이전 응답이 화면을 덮어쓰지 않게 한다.
  int _loadId = 0;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final id = ++_loadId;
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final menu = await _service.fetchMenu(_selectedDate);
      if (!mounted || id != _loadId) return;
      setState(() {
        _menu = menu;
        _loading = false;
      });
    } on CafeteriaMenuException catch (e) {
      debugPrint('[Cafeteria] 학식 조회 실패: $e');
      if (!mounted || id != _loadId) return;
      setState(() {
        _menu = null;
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// 지금 시각에 맞는 끼니(오전 10시 전 아침, 오후 3시 전 점심, 그 뒤 저녁).
  CafeteriaMeal _defaultMeal() => mealAt(_now);

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
    _loadMenu();
  }

  Future<void> _openDatePicker() async {
    final picked = await showCafeteriaDatePickerDialog(
      context,
      initialDate: _selectedDate,
    );
    if (picked != null) _selectDate(picked);
  }

  void _cycleMeal() {
    final values = CafeteriaMeal.values;
    setState(() => _meal = values[(_meal.index + 1) % values.length]);
  }

  /// 위쪽 알약 문구 — 식당/끼니/시간. 전체 탭은 학생식당 기준으로 쓴다.
  String get _pillText {
    switch (_venue) {
      case null:
      case CafeteriaVenue.student:
        final time = _meal == CafeteriaMeal.lunch ? ' 11:30 - 13:30' : '';
        return '학생회관 1층 · ${_meal.label}$time';
      case CafeteriaVenue.dorm:
      case CafeteriaVenue.staff:
      case CafeteriaVenue.cafe:
        return '${_venue!.label} · ${_meal.label}';
    }
  }

  /// 예전 디자인의 윗부분(달력 버튼, 끼니 바꾸는 알약, "오늘 뭐 먹지?" 제목).
  /// 새 디자인("07 학식")에는 없어 숨겨 두었다. true로 바꾸면 다시 보인다.
  static const bool _showLegacyHeader = false;

  /// 한 끼니에 보여줄 메뉴(식당 탭으로 거른다).
  List<CafeteriaMenuItem> _itemsFor(CafeteriaMeal meal) {
    final menu = _menu;
    if (menu == null) return const [];
    final items = menu.itemsFor(meal);
    if (_venue == null) return items;
    return items.where((item) => item.venue == _venue).toList();
  }

  @override
  Widget build(BuildContext context) {
    // 밝은 바탕이라 상태 표시줄 글자를 어둡게 한다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBar(),
              if (_showLegacyHeader) _buildLegacyHeader(),
              CafeteriaDateStrip(
                selectedDate: _selectedDate,
                today: _dateOnly(_now),
                onDaySelected: _selectDate,
              ),
              const SizedBox(height: 16),
              CafeteriaVenueTabs(
                selected: _venue,
                onChanged: (v) => setState(() => _venue = v),
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  /// 맨 위 줄 — 뒤로 꺾쇠와 "학식" 제목(디자인 높이 60, 좌우 여백 6).
  Widget _buildAppBar() {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Pressable.icon(
              onTap: () => Navigator.of(context).pop(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.chevron_left_rounded,
                  size: 28,
                  color: CafeteriaColors.title,
                  semanticLabel: '뒤로',
                ),
              ),
            ),
            const Text(
              '학식',
              style: TextStyle(
                color: CafeteriaColors.title,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.blue),
      );
    }
    if (_loadFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '학식을 불러오지 못했어요',
              style: TextStyle(
                color: AppColors.textSub,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Pressable.effect(
              child: TextButton(
                onPressed: _loadMenu,
                child: const Text(
                  '다시 시도',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 메뉴가 있는 끼니만 구역으로 보여준다(디자인 "중식만 있을 경우"). 하나도
    // 없으면 구역 없이 안내 문구만 가운데에 띄운다(디자인 "학식_데이터 없음").
    final meals = [
      for (final meal in CafeteriaMeal.values)
        if (_itemsFor(meal).isNotEmpty) meal,
    ];
    if (meals.isEmpty) {
      return const Center(
        child: Text(
          '오늘은 학식이 없습니다!',
          style: TextStyle(
            color: CafeteriaColors.tabText,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // 조식·중식·석식 순서로, 구역 사이에는 가는 선을 긋는다.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < meals.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 24),
              const Divider(
                height: 1,
                thickness: 1,
                color: CafeteriaColors.cardBorder,
              ),
              const SizedBox(height: 24),
            ],
            _buildMealSection(meals[i], isLast: i == meals.length - 1),
          ],
        ],
      ),
    );
  }

  /// 끼니 한 구역 — 제목(조식/중식/석식)과 메뉴 카드.
  Widget _buildMealSection(CafeteriaMeal meal, {required bool isLast}) {
    final items = _itemsFor(meal);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _sectionTitles[meal]!,
              style: const TextStyle(
                color: CafeteriaColors.tabText,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildCards(items),
        ],
      ),
    );
  }

  static const _sectionTitles = {
    CafeteriaMeal.breakfast: '조식',
    CafeteriaMeal.lunch: '중식',
    CafeteriaMeal.dinner: '석식',
  };

  /// 메뉴 카드를 두 장씩 한 줄로 놓는다(남는 칸은 비워 둔다). 넓은 화면(펼친
  /// 듀오 등)에서는 네 장씩 놓는다(사용자 요청, 2026-11-28). 한 줄의 카드는
  /// 가장 긴 쪽에 높이를 맞춘다.
  Widget _buildCards(List<CafeteriaMenuItem> items) {
    final perRow = isWideLayout(context) ? 4 : 2;
    return Column(
      children: [
        for (var i = 0; i < items.length; i += perRow) ...[
          if (i > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + perRow; j++) ...[
                  if (j > i) const SizedBox(width: 10),
                  Expanded(
                    child: j < items.length
                        ? SmallMenuCard(item: items[j])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 숨겨 둔 예전 윗부분([_showLegacyHeader]).
  Widget _buildLegacyHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              _squareButton(
                Icons.calendar_month_rounded,
                19,
                '날짜 선택',
                _openDatePicker,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Pressable(
            onTap: _cycleMeal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _pillText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '오늘 뭐 먹지?',
            style: TextStyle(
              color: AppColors.textStrong,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.4,
              letterSpacing: -1.04,
            ),
          ),
        ],
      ),
    );
  }

  /// 흰 네모 버튼(뒤로가기·날짜 선택). 디자인 42x42, 모서리 12, 옅은 그림자.
  Widget _squareButton(
    IconData icon,
    double iconSize,
    String label,
    VoidCallback onTap,
  ) {
    return Pressable.icon(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppColors.cardShadow,
        ),
        child: Icon(
          icon,
          color: AppColors.textStrong,
          size: iconSize,
          semanticLabel: label,
        ),
      ),
    );
  }
}
