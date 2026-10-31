import 'package:flutter/material.dart';

import '../../services/cafeteria_menu_service.dart';
import '../../services/service_factory.dart';
import '../../theme/app_colors.dart';
import 'models/cafeteria_menu.dart';
import 'widgets/cafeteria_date_picker_dialog.dart';
import 'widgets/cafeteria_venue_tabs.dart';
import 'widgets/cafeteria_week_row.dart';
import 'widgets/featured_menu_card.dart';
import 'widgets/small_menu_card.dart';

/// "오늘 뭐 먹지?" 화면(v4 리디자인). 위쪽에서 요일(월~금 한 주)과 식당(학생식당/
/// 교직원식당)을 고르면, 그 식당의 메뉴가 큰 대표 카드 하나와 작은 코너 카드들로
/// 나온다. 아침/점심/저녁은 위쪽 라임 알약을 눌러 바꾼다.
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
  CafeteriaVenue _venue = CafeteriaVenue.student;
  late CafeteriaMeal _meal = _defaultMeal();

  /// 즐겨찾기한 메뉴(날짜+메뉴). 화면이 열려 있는 동안만 유지된다.
  final Set<String> _favorites = {};

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
  CafeteriaMeal _defaultMeal() {
    if (_now.hour < 10) return CafeteriaMeal.breakfast;
    if (_now.hour < 15) return CafeteriaMeal.lunch;
    return CafeteriaMeal.dinner;
  }

  String _dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
    _loadMenu();
  }

  void _moveWeek(int delta) =>
      _selectDate(_selectedDate.add(Duration(days: 7 * delta)));

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

  /// 지금 탭/끼니에 보여줄 메뉴.
  List<CafeteriaMenuItem> _itemsToShow(DailyCafeteriaMenu? menu) {
    if (menu == null) return const [];
    return menu.itemsFor(_meal).where((item) => item.venue == _venue).toList();
  }

  /// 위쪽 알약 문구 — 식당/끼니/시간.
  String get _pillText {
    switch (_venue) {
      case CafeteriaVenue.student:
        final time = _meal == CafeteriaMeal.lunch ? ' 11:30 ~ 13:30' : '';
        return '학생회관 1층 · ${_meal.label}$time';
      case CafeteriaVenue.staff:
        return '교직원식당 · ${_meal.label}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _itemsToShow(_menu);

    return Scaffold(
      backgroundColor: AppColors.cobalt,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  _circleButton(
                    Icons.arrow_back_ios_new,
                    () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  _circleButton(Icons.calendar_month, _openDatePicker),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _cycleMeal,
                child: Container(
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
                        Icons.restaurant,
                        size: 14,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          _pillText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.swap_horiz,
                        size: 16,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '오늘 뭐 먹지?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.04,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CafeteriaWeekRow(
                selectedDate: _selectedDate,
                today: _dateOnly(_now),
                onDaySelected: _selectDate,
                onWeekChanged: _moveWeek,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CafeteriaVenueTabs(
                selected: _venue,
                onChanged: (v) => setState(() => _venue = v),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.lime),
                    )
                  : _loadFailed
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '학식을 불러오지 못했어요',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: _loadMenu,
                            child: const Text(
                              '다시 시도',
                              style: TextStyle(
                                color: AppColors.lime,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : items.isEmpty
                  ? const Center(
                      child: Text(
                        '등록된 메뉴가 없어요',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    )
                  : _buildMenus(items),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenus(List<CafeteriaMenuItem> items) {
    final featured = items.first;
    final others = items.skip(1).toList();
    final favKey = '${_dateKey(_selectedDate)}/${featured.key}';
    const colors = [AppColors.blushPink, Colors.white];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        children: [
          FeaturedMenuCard(
            item: featured,
            favorite: _favorites.contains(favKey),
            onFavoriteTap: () => setState(() {
              if (!_favorites.remove(favKey)) _favorites.add(favKey);
            }),
          ),
          if (others.isNotEmpty) const SizedBox(height: 12),
          // 두 장씩 한 줄. 한 줄 안의 두 카드는 높이를 같게 맞춘다.
          for (var i = 0; i < others.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SmallMenuCard(
                      item: others[i],
                      background: colors[i % 2],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < others.length
                        ? SmallMenuCard(
                            item: others[i + 1],
                            background: colors[(i + 1) % 2],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.cobaltDeep,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
